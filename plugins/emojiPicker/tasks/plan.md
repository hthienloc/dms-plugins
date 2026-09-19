# Implementation Plan: Emoji Composition Queue

## Overview

Implement the approved queue contract as local picker state, route every mouse,
keyboard, clipboard, and close path through a small set of intent-named actions,
then add a compact responsive preview and update user documentation.

## Dependency Graph

```text
Queue state and finalize/cancel actions
    |
    +-- Mouse and keyboard routing
    |       |
    |       +-- End-to-end copy/paste behavior
    |
    +-- Queue preview component
            |
            +-- Long-sequence overflow

Completed interaction contract
    |
    +-- README and Settings usage guide
```

## Architecture Decisions

- Keep queue state in `EmojiPicker.qml`, beside selection and modal lifecycle
  state. It is runtime-only and has one owner.
- Resolve the output text before calling the existing clipboard path. Clipboard
  success remains the only point that records Recent, clears state, closes the
  modal, and optionally triggers paste.
- Centralize key interpretation in helper functions used by both search and
  grid handlers so Enter modifier behavior cannot diverge.
- Add a focused `EmojiQueuePreview.qml` presentation component. It receives the
  sequence and emits copy/paste intents but does not own or mutate queue state.
- Preserve right-click and all category/navigation shortcuts unchanged.

## Task List

### Phase 1: Complete Interaction Slice

- [x] Task 1: Add queue state, actions, lifecycle cleanup, recent updates, and
  unified mouse/keyboard routing.

### Checkpoint: Interaction

- [x] `qmllint`, manifest validation, and `git diff --check` pass.
- [ ] Empty and non-empty queue keyboard/mouse matrices behave as specified.
- [ ] Clipboard failure retains picker state; every cancel path clears it.

### Phase 2: Preview and Discoverability

- [x] Task 2: Add the themed responsive bottom preview with sequence,
  copy/paste actions, and overflow.

### Checkpoint: UI

- [ ] Preview is absent for an empty queue and usable at 500/560/620 px.
- [ ] Long queues scroll horizontally without resizing the modal.
- [ ] Focus and keyboard navigation remain intact.

### Phase 3: Documentation and Regression

- [x] Task 3: Update README and Settings usage instructions, then run the full
  regression checklist.

### Checkpoint: Complete

- [ ] Every success criterion in `docs/specs/emoji-queue.md` is satisfied.
- [x] No duplicate input handlers or stale queue state paths remain.
- [x] Worktree diff is review-ready.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Search Backspace conflicts with queue removal | High | Remove from queue only with grid focus or an empty query; otherwise leave the event to the text field. |
| Search and grid Enter handlers drift | High | Route both through one modifier-aware action function. |
| Clipboard failure loses composition | High | Clear and close only inside the successful clipboard response. |
| Long queue crowds the emoji grid | Medium | Fixed-height bottom preview with horizontal scrolling. |
| Recent order reverses unexpectedly | Medium | Update the history once from the finalized sequence, explicitly making the last selected emoji most recent. |

## Parallelization

Implementation is sequential because Tasks 1 and 2 share the queue contract and
focus behavior. Documentation follows the final interaction labels. No sub-agent
work is needed.

## Open Questions

None.
