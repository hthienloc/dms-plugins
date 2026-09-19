# Tasks: Emoji Composition Queue

## Task 1: Implement the complete queue interaction slice

**Description:** Add local queue state and central actions for append, remove,
finalize, copy/paste, Recent updates, and cancellation. Route search, grid, and
mouse input through those actions while retaining existing single-emoji behavior.

**Acceptance criteria:**

- [x] Shift+left click and Shift+Enter append one emoji without closing.
- [x] Enter/Ctrl+Enter choose focused emoji when empty and queued text when non-empty.
- [x] Backspace, queue-first Escape, close buttons, background click, IPC close,
  copy failure, and successful finalize follow the approved lifecycle contract.

**Verification:**

- [x] Run the spec's `qmllint`, `jq`, and `git diff --check` commands.
- [ ] Manually exercise every row of the interaction contract from search and grid focus.
- [ ] Confirm category shortcuts, arrows, search editing, toast, paste delay, and Recent ordering.

**Dependencies:** None

**Files likely touched:**

- `EmojiPicker.qml`

**Estimated scope:** Small (1 file)

## Task 2: Add the queue preview

**Description:** Create a focused themed preview component and place it at the
bottom of the modal without changing modal dimensions or focus ownership.

**Acceptance criteria:**

- [x] Empty queue consumes no layout space; non-empty queue shows the exact sequence and copy/paste icon actions.
- [x] Long sequences scroll horizontally at all three configured picker sizes.
- [x] Shortcut hints remain in documentation rather than occupying modal space.

**Verification:**

- [x] Run `qmllint` for the picker, preview, and settings components.
- [ ] Inspect 500, 560, and 620 px layouts with short and long queues.
- [ ] Confirm preview never takes keyboard focus from search/grid navigation.

**Dependencies:** Task 1

**Files likely touched:**

- `EmojiQueuePreview.qml`
- `EmojiPicker.qml`

**Estimated scope:** Small (2 files)

## Task 3: Document and regression-test the feature

**Description:** Update both user-facing control references and verify the full
approved behavior against the final implementation.

**Acceptance criteria:**

- [x] README and Settings Usage Guide describe queue, finalize, paste, removal, and cancel behavior.
- [x] Documentation matches actual modifiers and empty-queue fallbacks exactly.
- [x] All implemented spec criteria pass without unrelated source changes.

**Verification:**

- [x] Run all static validation commands from the spec.
- [x] Search for duplicate Enter/Escape/Backspace/click handlers and inspect every match.
- [x] Review the complete diff against `main`.

**Dependencies:** Tasks 1 and 2

**Files likely touched:**

- `README.md`
- `EmojiPickerSettings.qml`
- `tasks/todo.md`

**Estimated scope:** Medium (3 files)
