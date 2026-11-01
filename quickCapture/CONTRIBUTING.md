# Contributing to DMS Quick Capture

Thanks for contributing! Here's everything you need to get started.

---

## Before you start

- Read [`docs/developer-guide.md`](docs/developer-guide.md) — it covers the file layout, architectural patterns, and a step-by-step guide for adding a new tool.
- Search [existing issues](https://github.com/hthienloc/dms-quick-capture/issues) before opening a new one.

---

## Development setup

```bash
# Clone into the DMS plugins directory so it loads automatically
git clone https://github.com/hthienloc/dms-quick-capture \
  ~/.config/DankMaterialShell/plugins/quickCapture

# Reload without restarting your shell
dms plugins reload quickCapture

# View live logs
journalctl --user -f -u dank-material-shell
```

---

## Making changes

1. Fork the repo and create a branch: `git checkout -b feat/your-feature` or `fix/your-fix`
2. Make your changes. See `developer-guide.md` for the relevant files.
3. Test on your setup — reload the plugin and exercise the affected feature.
4. Open a PR using the provided template.

**Branch naming:**
- `feat/` — new feature
- `fix/` — bug fix
- `refactor/` — code cleanup, no behavior change
- `docs/` — documentation only

---

## A few rules

- **No logic changes in refactor PRs.** If you're cleaning up code, don't sneak in behavior changes.
- **Test before submitting.** The plugin must load without errors (`dms plugins reload quickCapture` should produce no warnings in the log).
- **Update docs if needed.** If you add a tool, shortcut, IPC command, or widget host capability (such as Dock integration), update the relevant doc in `docs/`.
- **DMS 2.0 Dock & Bar Widget Conventions:** Ensure widget pills adapt properly to both panel bars and docks (`kind: "bar" | "dock"`). Use dynamic sizing (`root.iconSize` / `root.textSize`) instead of fixed sizes like `iconSizeSmall`, support both `horizontalBarPill` and `verticalBarPill`, avoid `triggerPopout()` loops when using `pillClickAction`, gate timers/animations on `surfaceLive`, and never assume a single singleton widget instance (`widgetInstanceId`).
- **One concern per PR.** A PR that fixes a bug and adds a feature is two PRs.

---

## Questions?

Open a [Discussion](https://github.com/hthienloc/dms-quick-capture/discussions) or drop a comment on the relevant issue.
