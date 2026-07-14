---
change: CHG-0002-document-the-existing-swift-retry-api-at-complete-specsync-coverage
artifact: docs
---

# Docs

The documentation delivery replaces every generated scaffold entry in `specs/retry/` with source-backed content:

- `retry.spec.md` owns all fourteen implementation files and documents the public surface and invariants.
- `requirements.md` defines eight stable `REQ-retry-*` contracts without changing existing semantics.
- `context.md` records architecture boundaries, navigation, and current implementation status.
- `testing.md` maps all sixty-four current tests and the edge cases they protect.
- `tasks.md` records the completed inventory and documentation preparation work.

Public documentation does not claim that hosted CI or closing approval completed before those events occur.
