# Quick Capture v5.0.0-beta.2

This beta introduces the new Rust screenshot backend as an opt-in replacement for the existing backend.

## Highlights

- Faster and smoother screenshot capture in local testing.
- Supports region, window, full-screen, output, and scrolling capture.
- Adds **Old Backend** and **New Backend** selection in Settings.
- Publishes the Rust backend as a separately verified GitHub Release asset.
- Adds checksum-verified installation and local build scripts.
- Improves selector responsiveness and keeps scrolling capture separate from Last Region.
- Adds a live scrolling preview that can be clicked to finish capture.

## Installation

1. Update Quick Capture to this beta version.
2. Install `dms-screenshot-rs` using the instructions in [`dms-screenshot-rs/README.md`](../dms-screenshot-rs/README.md).
3. Select **New Backend** in Quick Capture Settings.

You can build the backend locally if a release asset is not available for your architecture.

## Current Limitations

- Release binaries currently support `x86_64` Linux.
- The Rust backend is opt-in and is not enabled by default.
- Behavior may vary across compositors, display layouts, and multi-monitor setups.

Switch back to **Old Backend** if you encounter a problem, then report the compositor, output layout, capture mode, and relevant logs.
