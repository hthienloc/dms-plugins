# Spec: Emoji Composition Queue

## Objective

Add an ephemeral composition queue to Emoji Picker so users can build and
copy or paste a multi-emoji sequence without reopening the picker. Preserve
the existing one-emoji mouse and keyboard workflows.

The queue exists only while the picker is open. Finalizing or cancelling the
picker clears it.

## Interaction Contract

| Input | Empty queue | Non-empty queue |
| --- | --- | --- |
| Left click | Copy clicked emoji and close | Copy clicked emoji and close |
| Right click | Copy/paste clicked emoji and close | Copy/paste clicked emoji and close |
| Shift+left click | Append clicked emoji and stay open | Append clicked emoji and stay open |
| Shift+Enter | Append focused emoji and stay open | Append focused emoji and stay open |
| Enter | Copy focused emoji and close | Copy the queued sequence and close |
| Ctrl+Enter | Copy/paste focused emoji and close | Copy/paste the queued sequence and close |
| Backspace | Edit the search query normally | Remove the last queued emoji when the grid is focused or the search query is empty |
| Escape | Close without changing clipboard | Discard the queue and keep the picker open |

Queued emojis are concatenated in selection order without a separator. For
example, `👍`, `🔥`, `🚀` produces `👍🔥🚀`.

## Queue Preview

- Show a compact preview row at the bottom of the modal only when the queue is
  non-empty.
- Show the composed emoji sequence with icon actions to copy or paste it; do not
  show an item count.
- Keep the sequence readable when long by scrolling horizontally; do not grow
  the modal or shrink the emoji grid below its normal usable size.
- Keep shortcut guidance in the existing documentation instead of displaying
  inline hints in the modal.
- Use existing `Theme.*`, `StyledText`, and surface tokens; do not introduce
  custom colors or a new settings option.

## State and Data

- Store the queue as local runtime state on `EmojiPicker.qml`; do not persist it.
- Clear it on open, successful copy/paste completion, Escape while non-empty,
  close button, background click, IPC close, and plugin teardown. Escape closes
  the picker only when the queue is already empty.
- Add each finalized emoji to Recent while preserving the existing uniqueness
  and history-size limit. The last emoji in the composed sequence is the most
  recent item.
- A clipboard failure leaves the picker and queue open so the user can retry.

## Tech Stack

- QML / QtQuick 6
- Quickshell and DankMaterialShell plugin APIs
- `DMSService` clipboard request and `ClipboardService` paste keystroke
- Existing DMS theme and widget components

## Commands

```bash
# Static QML validation
qmllint -I /home/loccun/Documents/GitHub/DankMaterialShell/quickshell -I . \
  EmojiPicker.qml EmojiQueuePreview.qml EmojiPickerSettings.qml

# Manifest validation
jq -e . plugin.json

# Whitespace/error validation
git diff --check
```

Manual verification runs in DMS after opening the plugin with:

```bash
dms ipc call emojiPicker open
```

## Project Structure

```text
EmojiPicker.qml          Picker state, clipboard actions, modal UI, input handling
EmojiQueuePreview.qml    Queue sequence and copy/paste actions
EmojiPickerSettings.qml  Settings usage guide
README.md                User-facing controls documentation
plugin.json              DMS plugin manifest
docs/specs/              Feature specifications
```

## Code Style

Follow the existing QML style: root-owned state, small intent-named functions,
early returns, `const`/`let` for local JavaScript state, and DMS theme tokens.

```qml
function appendCurrentEmoji() {
    const entry = root.visibleEntries[root.selectedIndex];
    if (!entry)
        return false;
    root.queuedEmojis = root.queuedEmojis.concat([entry.emoji]);
    return true;
}
```

## Testing Strategy

- Static: `qmllint`, JSON validation, and `git diff --check`.
- Keyboard: verify queueing/finalization from both search and grid focus,
  including Backspace conflict handling.
- Mouse: verify normal, right, and Shift+left clicks.
- Lifecycle: verify every close path clears the queue and clipboard failures do
  not.
- Regression: verify category shortcuts, arrow navigation, search editing,
  Recent ordering, copy toast, and paste delay remain functional.
- Layout: verify all configured picker sizes (500, 560, 620) and long queues.

## Boundaries

- Always: preserve existing single-emoji behavior, theme tokens, focus handling,
  localized user-facing text, and clipboard error handling.
- Ask first: change persisted settings, manifest permissions, IPC API, paste
  timing, or Recent-history semantics.
- Never: persist queue contents, add dependencies, intercept Backspace while it
  should edit a non-empty query, or mutate the clipboard on Escape.

## Success Criteria

- Shift+left click and Shift+Enter append exactly one focused/clicked emoji and
  keep the picker open.
- Preview displays the exact concatenated queue and remains usable when long.
- Enter and Ctrl+Enter finalize the queue as specified, clear it, and close only
  after successful clipboard copy.
- Empty-queue Enter/Ctrl+Enter and normal/right clicks retain current behavior.
- Backspace removes only the final queued emoji without breaking search editing.
- Every close/cancel path discards the queue.
- Recent history contains finalized emojis in the specified order and limit.
- Static validation and the complete manual interaction matrix pass.

## Out of Scope

- Clicking an item in the preview to remove it
- Arbitrary deletion or reordering
- Configurable separators, persistence, or maximum queue length
- Changes to category navigation, search ranking, or emoji data

## Open Questions

None after approval of this specification.
