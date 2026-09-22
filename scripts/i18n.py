#!/usr/bin/env python3
"""
i18n.py — Centralized Translation Management Tool for DMS Plugins (DMS 1.6+).

Usage:
  python3 scripts/i18n.py status                         # Overview coverage across all plugins
  python3 scripts/i18n.py status --plugin <id>           # Detailed status for a specific plugin
  python3 scripts/i18n.py status --plugin <id> --readme  # Update translation table in plugin's README.md
  python3 scripts/i18n.py lint                           # Audit all plugins for legacy I18n.tr() calls & old format
  python3 scripts/i18n.py lint --plugin <id>             # Audit a single plugin
  python3 scripts/i18n.py extract --plugin <id>          # Extract strings into 2-level JSON format
  python3 scripts/i18n.py extract --all                  # Extract strings for all plugins
  python3 scripts/i18n.py migrate --plugin <id>          # Auto-migrate QML to I18n.trFor() & poexports to 2-level JSON
  python3 scripts/i18n.py translate --plugin <id>        # Auto-translate missing strings via Google Translate
  python3 scripts/i18n.py translate --plugin <id> --lang vi,ja
"""

import re
import sys
import json
import time
import argparse
import urllib.request
import urllib.parse
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent

KNOWN_LANGUAGES = {
    "ar":    "Arabic",
    "bg":    "Bulgarian",
    "de":    "German",
    "eo":    "Esperanto",
    "es":    "Spanish",
    "fa":    "Persian",
    "fr":    "French",
    "he":    "Hebrew",
    "hu":    "Hungarian",
    "it":    "Italian",
    "ja":    "Japanese",
    "ko":    "Korean",
    "nl":    "Dutch",
    "pl":    "Polish",
    "pt":    "Portuguese",
    "ru":    "Russian",
    "sv":    "Swedish",
    "tr":    "Turkish",
    "uk":    "Ukrainian",
    "vi":    "Vietnamese",
    "zh_CN": "Chinese (Simplified)",
    "zh_TW": "Chinese (Traditional)",
}

_GT_LOCALE_MAP = {
    "zh_CN": "zh-CN",
    "zh_TW": "zh-TW",
    "he": "iw",
}

TABLE_START = "<!-- TRANSLATIONS_TABLE_START -->"
TABLE_END   = "<!-- TRANSLATIONS_TABLE_END -->"

def info(msg):    print(f"\033[94m{msg}\033[0m")
def success(msg): print(f"\033[92m{msg}\033[0m")
def warn(msg):    print(f"\033[93mWarning: {msg}\033[0m", file=sys.stderr)
def error(msg):   print(f"\033[91mError: {msg}\033[0m", file=sys.stderr); sys.exit(1)

def discover_plugins() -> dict[str, Path]:
    """Find all plugin directories that contain plugin.json."""
    plugins = {}
    for p in sorted(REPO_ROOT.iterdir()):
        if p.is_dir() and not p.name.startswith(".") and (p / "plugin.json").exists():
            try:
                manifest = json.loads((p / "plugin.json").read_text(encoding="utf-8"))
                plugin_id = manifest.get("id", p.name)
            except Exception:
                plugin_id = p.name
            plugins[plugin_id] = p
    return plugins

def _clean_str(s: str) -> str:
    return s.replace(r'\"', '"').replace(r'\\', '\\').replace(r'\n', '\n')

def get_plugin_qml_files(plugin_dir: Path) -> list[Path]:
    return [
        q for q in sorted(plugin_dir.rglob("*.qml"))
        if "dms-common" not in q.parts and ".git" not in q.parts
    ]

def extract_plugin_strings(plugin_dir: Path, plugin_id: str) -> tuple[list[str], list[dict]]:
    """
    Returns:
      (strings, legacy_calls)
      strings: unique list of strings to translate
      legacy_calls: list of dicts with {file, line, text, pattern}
    """
    strings = set()
    legacy_calls = []

    tr_for_re = re.compile(rf'I18n\.trFor\(\s*["\']{re.escape(plugin_id)}["\']\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)')
    tr_legacy_re = re.compile(r'I18n\.tr\(\s*"((?:[^"\\]|\\.)*)"\s*\)')
    tr_wrong_id_re = re.compile(r'I18n\.trFor\(\s*["\']([^"\']+)["\']\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)')

    for qml in get_plugin_qml_files(plugin_dir):
        lines = qml.read_text(encoding="utf-8", errors="replace").splitlines()
        for idx, line in enumerate(lines, 1):
            # Check trFor
            for m in tr_for_re.finditer(line):
                raw = _clean_str(m.group(1)).strip()
                if raw:
                    strings.add(raw)

            # Check legacy tr()
            for m in tr_legacy_re.finditer(line):
                raw = _clean_str(m.group(1)).strip()
                if raw:
                    strings.add(raw)
                    legacy_calls.append({
                        "file": qml.relative_to(REPO_ROOT),
                        "line": idx,
                        "text": raw,
                        "type": "I18n.tr() [legacy]",
                    })

            # Check wrong pluginId in trFor()
            for m in tr_wrong_id_re.finditer(line):
                found_id = m.group(1)
                raw = _clean_str(m.group(2)).strip()
                if found_id != plugin_id:
                    legacy_calls.append({
                        "file": qml.relative_to(REPO_ROOT),
                        "line": idx,
                        "text": raw,
                        "type": f"I18n.trFor('{found_id}') [mismatched ID]",
                    })

    return sorted(strings), legacy_calls

def read_translations_file(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        res = {}
        for k, v in data.items():
            if isinstance(v, dict):
                val = v.get(k, "")
                res[k] = val if isinstance(val, str) else ""
            elif isinstance(v, str):
                res[k] = v
        return res
    except Exception:
        return {}

def write_2level_translations(path: Path, flat_map: dict[str, str]):
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {}
    for k in sorted(flat_map.keys()):
        payload[k] = {k: flat_map[k]}
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def get_plugin_stats(plugin_dir: Path, plugin_id: str) -> dict:
    strings, legacy = extract_plugin_strings(plugin_dir, plugin_id)
    total = len(strings)
    trans_dir = plugin_dir / "translations"

    per_lang = []
    completed_langs = 0
    usable_langs = 0

    for code, name in sorted(KNOWN_LANGUAGES.items()):
        fpath = trans_dir / f"{code}.json"
        existing = read_translations_file(fpath)
        done = sum(1 for s in strings if existing.get(s, "").strip())
        pct = (done / total * 100) if total else 0.0
        if pct >= 100.0:
            completed_langs += 1
        if pct >= 80.0:
            usable_langs += 1

        per_lang.append({
            "code": code,
            "name": name,
            "file": f"{code}.json",
            "done": done,
            "missing": total - done,
            "pct": pct,
        })

    avg_pct = (sum(l["pct"] for l in per_lang) / len(per_lang)) if per_lang else 0.0
    return {
        "id": plugin_id,
        "dir": plugin_dir,
        "strings": strings,
        "total": total,
        "legacy": legacy,
        "per_lang": per_lang,
        "completed_langs": completed_langs,
        "usable_langs": usable_langs,
        "avg_pct": avg_pct,
    }

# ── COMMAND: LINT / AUDIT ───────────────────────────────────────────────────────
def cmd_lint(args):
    plugins = discover_plugins()
    if args.plugin:
        if args.plugin not in plugins:
            error(f"Plugin '{args.plugin}' not found.")
        target_plugins = {args.plugin: plugins[args.plugin]}
    else:
        target_plugins = plugins

    total_legacy = 0
    print(f"\n{'Plugin':<22} {'Legacy Calls':<15} {'Old poexports/':<15} {'DMS 1.6+ JSONs':<15}")
    print("-" * 70)

    for pid, pdir in target_plugins.items():
        _, legacy = extract_plugin_strings(pdir, pid)
        has_poexports = (pdir / "translations" / "poexports").exists()
        json_count = len(list((pdir / "translations").glob("*.json"))) if (pdir / "translations").exists() else 0

        legacy_str = str(len(legacy)) if legacy else "0"
        po_str = "Yes (Legacy)" if has_poexports else "No"
        print(f"{pid:<22} {legacy_str:<15} {po_str:<15} {json_count:<15}")
        total_legacy += len(legacy)

    if args.verbose or args.plugin:
        print("\n--- Detailed Legacy Calls ---")
        for pid, pdir in target_plugins.items():
            _, legacy = extract_plugin_strings(pdir, pid)
            if legacy:
                info(f"\n[{pid}] {len(legacy)} issues:")
                for call in legacy:
                    print(f"  {call['file']}:{call['line']} -> {call['type']}: \"{call['text']}\"")

    print(f"\nTotal legacy / mismatched calls across scanned plugins: {total_legacy}")

# ── COMMAND: STATUS ────────────────────────────────────────────────────────────
def cmd_status(args):
    plugins = discover_plugins()

    if args.plugin:
        if args.plugin not in plugins:
            error(f"Plugin '{args.plugin}' not found.")
        stats = get_plugin_stats(plugins[args.plugin], args.plugin)
        total = stats["total"]

        print(f"\nPlugin: {args.plugin} | Total Strings: {total}")
        print(f"{'Language':<22} {'Locale':<8} {'Done':>6} {'Missing':>8} {'Coverage':>10}")
        print("-" * 60)
        for l in stats["per_lang"]:
            status_icon = "✓" if l["missing"] == 0 else ("~" if l["done"] > 0 else "✗")
            print(f"{l['name']:<22} {l['code']:<8} {l['done']:>6} {l['missing']:>8}   {l['pct']:>7.1f}%  {status_icon}")
        print()

        if getattr(args, "readme", False):
            readme_path = plugins[args.plugin] / "README.md"
            if not readme_path.exists():
                error(f"{readme_path} not found.")
            content = readme_path.read_text(encoding="utf-8")
            if TABLE_START not in content or TABLE_END not in content:
                # Append table if markers not found
                table_md = _format_readme_table(stats["per_lang"], total)
                content += f"\n\n## Translations\n\n{TABLE_START}\n{table_md}\n{TABLE_END}\n"
                readme_path.write_text(content, encoding="utf-8")
                success(f"Added translation status table to {readme_path.relative_to(REPO_ROOT)}")
            else:
                table_md = _format_readme_table(stats["per_lang"], total)
                pattern = re.compile(f"{re.escape(TABLE_START)}.*?{re.escape(TABLE_END)}", re.DOTALL)
                new_content = pattern.sub(f"{TABLE_START}\n{table_md}\n{TABLE_END}", content)
                readme_path.write_text(new_content, encoding="utf-8")
                success(f"Updated translation status table in {readme_path.relative_to(REPO_ROOT)}")
        return

    # Overview table
    print(f"\n{'Plugin':<22} {'Strings':<9} {'Complete (100%)':<17} {'Usable (>=80%)':<16} {'Avg Coverage':>12}")
    print("-" * 80)
    for pid, pdir in plugins.items():
        st = get_plugin_stats(pdir, pid)
        print(f"{pid:<22} {st['total']:<9} {st['completed_langs']}/{len(KNOWN_LANGUAGES):<15} {st['usable_langs']}/{len(KNOWN_LANGUAGES):<14} {st['avg_pct']:>11.1f}%")
    print()

def _format_readme_table(stats: list[dict], total: int) -> str:
    lines = [
        "| Language | Locale | Progress | Coverage | Status |",
        "| :--- | :--- | :---: | :---: | :---: |",
    ]
    for s in stats:
        pct_str = f"{s['pct']:.1f}%"
        if s["pct"] >= 100.0:
            badge = "🟢 Complete"
        elif s["pct"] >= 80.0:
            badge = "🟡 Usable"
        elif s["pct"] > 0.0:
            badge = "🟠 In Progress"
        else:
            badge = "⚪ Not Started"
        lines.append(f"| {s['name']} | `{s['code']}` | {s['done']}/{total} | {pct_str} | {badge} |")
    return "\n".join(lines)

# ── COMMAND: EXTRACT ───────────────────────────────────────────────────────────
def cmd_extract(args):
    plugins = discover_plugins()
    if args.all:
        target_plugins = plugins
    elif args.plugin:
        if args.plugin not in plugins:
            error(f"Plugin '{args.plugin}' not found.")
        target_plugins = {args.plugin: plugins[args.plugin]}
    else:
        error("Specify --plugin <id> or --all")

    for pid, pdir in target_plugins.items():
        strings, _ = extract_plugin_strings(pdir, pid)
        if not strings:
            warn(f"[{pid}] No translatable strings found.")
            continue

        trans_dir = pdir / "translations"
        poexports_dir = trans_dir / "poexports"
        trans_dir.mkdir(parents=True, exist_ok=True)

        for code in KNOWN_LANGUAGES:
            fpath = trans_dir / f"{code}.json"
            po_path = poexports_dir / f"{code}.json"

            existing = read_translations_file(po_path)
            existing.update(read_translations_file(fpath))

            merged = {s: existing.get(s, "") for s in strings}
            write_2level_translations(fpath, merged)

        success(f"[{pid}] Extracted {len(strings)} strings across {len(KNOWN_LANGUAGES)} languages.")

# ── COMMAND: MIGRATE ───────────────────────────────────────────────────────────
def cmd_migrate(args):
    """
    Automate migration for a plugin:
    1. Replace I18n.tr("...") with I18n.trFor("<pluginId>", "...") in QML.
    2. Extract strings and merge any existing translations in poexports/ into translations/<lang>.json (2-level JSON).
    3. Remove old poexports/ if specified.
    """
    plugins = discover_plugins()
    if not args.plugin or args.plugin not in plugins:
        error(f"Specify valid --plugin. Available: {', '.join(plugins.keys())}")

    pid = args.plugin
    pdir = plugins[pid]
    info(f"Migrating plugin '{pid}' in {pdir}...")

    # 1. Update QML files
    qml_files = get_plugin_qml_files(pdir)
    tr_re = re.compile(r'I18n\.tr\(\s*"((?:[^"\\]|\\.)*)"\s*\)')

    replaced_count = 0
    for qml in qml_files:
        content = qml.read_text(encoding="utf-8")
        def _replace_match(m):
            nonlocal replaced_count
            replaced_count += 1
            inner = m.group(1)
            return f'I18n.trFor("{pid}", "{inner}")'
        new_content = tr_re.sub(_replace_match, content)
        if new_content != content:
            qml.write_text(new_content, encoding="utf-8")

    info(f"Replaced {replaced_count} legacy I18n.tr() calls with I18n.trFor(\"{pid}\", ...)")

    # 2. Extract & convert translations
    class DummyArgs:
        plugin = pid
        all = False
    cmd_extract(DummyArgs())

    # 3. Clean up poexports
    poexports_dir = pdir / "translations" / "poexports"
    if poexports_dir.exists() and args.clean:
        import shutil
        shutil.rmtree(poexports_dir)
        info("Removed old poexports/ directory.")

    success(f"Migration completed for {pid}.")

# ── COMMAND: TRANSLATE ─────────────────────────────────────────────────────────
def _google_translate(text: str, target_lang: str) -> str | None:
    gt_lang = _GT_LOCALE_MAP.get(target_lang, target_lang)
    params = urllib.parse.urlencode({
        "client": "gtx",
        "sl":     "en",
        "tl":     gt_lang,
        "dt":     "t",
        "q":      text,
    })
    url = f"https://translate.googleapis.com/translate_a/single?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            parts = [seg[0] for seg in data[0] if seg and seg[0]]
            return "".join(parts)
    except Exception as e:
        warn(f"Translate failed for '{text[:30]}' ({target_lang}): {e}")
        return None

def cmd_translate(args):
    plugins = discover_plugins()
    if not args.plugin or args.plugin not in plugins:
        error(f"Specify valid --plugin. Available: {', '.join(plugins.keys())}")

    pid = args.plugin
    pdir = plugins[pid]
    strings, _ = extract_plugin_strings(pdir, pid)
    if not strings:
        error(f"[{pid}] No translatable strings found.")

    trans_dir = pdir / "translations"
    trans_dir.mkdir(parents=True, exist_ok=True)

    langs = list(KNOWN_LANGUAGES.keys())
    if args.lang:
        req = {l.strip().replace("-", "_") for l in args.lang.split(",")}
        langs = [l for l in langs if l in req or l.replace("_", "-") in req]

    delay = 0.2
    for code in langs:
        fpath = trans_dir / f"{code}.json"
        existing = read_translations_file(fpath)
        missing = [s for s in strings if not existing.get(s, "").strip()]

        if not missing:
            info(f"[{code}] already 100% complete ({len(existing)} strings)")
            continue

        info(f"[{code}] translating {len(missing)}/{len(strings)} strings...")
        translated = dict(existing)
        failed = 0

        for s in missing:
            res = _google_translate(s, code)
            if res:
                translated[s] = res
            else:
                translated[s] = ""
                failed += 1
            time.sleep(delay)

        write_2level_translations(fpath, translated)
        ok = len(missing) - failed
        if failed:
            warn(f"[{code}] {ok} translated, {failed} failed -> {code}.json")
        else:
            success(f"[{code}] {ok} strings translated -> {code}.json")

# ── MAIN ───────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Centralized i18n tooling for DMS plugins",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # Status
    p_status = sub.add_parser("status", help="Show translation coverage")
    p_status.add_argument("--plugin", help="Specific plugin ID")
    p_status.add_argument("--readme", action="store_true", help="Update README table")

    # Lint
    p_lint = sub.add_parser("lint", help="Audit plugins for legacy I18n.tr() calls")
    p_lint.add_argument("--plugin", help="Specific plugin ID")
    p_lint.add_argument("-v", "--verbose", action="store_true", help="Show line-by-line details")

    # Extract
    p_extract = sub.add_parser("extract", help="Extract strings into 2-level JSON")
    p_extract.add_argument("--plugin", help="Specific plugin ID")
    p_extract.add_argument("--all", action="store_true", help="All plugins")

    # Migrate
    p_migrate = sub.add_parser("migrate", help="Auto-migrate plugin to I18n.trFor() and 2-level JSON")
    p_migrate.add_argument("--plugin", required=True, help="Plugin ID to migrate")
    p_migrate.add_argument("--clean", action="store_true", help="Remove old poexports/ after migration")

    # Translate
    p_trans = sub.add_parser("translate", help="Auto-translate missing strings via Google Translate")
    p_trans.add_argument("--plugin", required=True, help="Plugin ID to translate")
    p_trans.add_argument("--lang", default="", help="Comma-separated language codes")

    args = parser.parse_args()
    {
        "status": cmd_status,
        "lint": cmd_lint,
        "extract": cmd_extract,
        "migrate": cmd_migrate,
        "translate": cmd_translate,
    }[args.command](args)

if __name__ == "__main__":
    main()
