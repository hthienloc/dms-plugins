#!/usr/bin/env python3
import json
import re
import subprocess
from pathlib import Path

def git_cmd(*args):
    try:
        res = subprocess.run(["git", *args], capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except subprocess.CalledProcessError:
        return ""

def parse_semver(ver_str):
    parts = [int(x) for x in re.findall(r"\d+", str(ver_str or "1.0.0"))]
    while len(parts) < 3:
        parts.append(0)
    return parts[:3]

def determine_bump_type(commits):
    has_breaking = False
    has_feat = False
    has_fix = False

    for msg in commits:
        msg = msg.strip()
        if not msg:
            continue
        # Breaking change: feat!: or fix!: or BREAKING CHANGE: / BREAKING-CHANGE:
        if re.search(r"BREAKING[- ]CHANGE|^\w+(\(.*?\))?!:", msg):
            has_breaking = True
            break
        elif re.match(r"^feat(\(.*?\))?:", msg):
            has_feat = True
        else:
            has_fix = True

    if has_breaking:
        return "major"
    if has_feat:
        return "minor"
    if has_fix:
        return "patch"
    return None

def bump(parts, bump_type):
    major, minor, patch = parts
    if bump_type == "major":
        return [major + 1, 0, 0]
    elif bump_type == "minor":
        return [major, minor + 1, 0]
    elif bump_type == "patch":
        return [major, minor, patch + 1]
    return parts

updated = []

for plugin_dir in sorted(Path(".").iterdir()):
    if not plugin_dir.is_dir() or plugin_dir.name.startswith("."):
        continue

    manifest = plugin_dir / "plugin.json"
    if not manifest.exists():
        continue

    # Commit gần nhất sửa plugin.json
    last_bump = git_cmd("log", "-n", "1", "--format=%H", "--", str(manifest))
    range_spec = f"{last_bump}..HEAD" if last_bump else "HEAD"

    # Lấy các commit trong plugin_dir kể từ lần bump trước
    raw_log = git_cmd("log", range_spec, "--format=%H %an %s", "--", str(plugin_dir))
    if not raw_log:
        continue

    relevant_commits = []
    for line in raw_log.splitlines():
        parts = line.split(" ", 2)
        if len(parts) < 3:
            continue
        h, author, subject = parts
        # Bỏ qua commit của github-actions bot và commit bump
        if "github-actions" in author.lower() or subject.startswith("chore(release):"):
            continue

        # Kiểm tra commit có thực sự thay đổi file nào khác ngoài plugin.json không
        files = git_cmd("diff-tree", "--no-commit-id", "--name-only", "-r", h, "--", str(plugin_dir)).splitlines()
        if any(f.strip() != str(manifest) for f in files if f.strip()):
            relevant_commits.append(subject)

    if not relevant_commits:
        continue

    bump_type = determine_bump_type(relevant_commits)
    if not bump_type:
        continue

    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"Error reading {manifest}: {e}")
        continue

    current_ver = data.get("version", "1.0.0")
    next_ver = ".".join(str(x) for x in bump(parse_semver(current_ver), bump_type))

    if current_ver == next_ver:
        continue

    data["version"] = next_ver
    manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    updated.append(f"{plugin_dir.name} ({current_ver} -> {next_ver})")
    print(f"[{bump_type.upper()}] {plugin_dir.name}: {current_ver} -> {next_ver}")

if updated:
    summary = ", ".join(updated)
    Path(".bump-summary.txt").write_text(summary, encoding="utf-8")
    print(f"Updated: {summary}")
else:
    print("No plugins require version bump.")
