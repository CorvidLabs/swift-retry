---
change: CHG-0002-document-the-existing-swift-retry-api-at-complete-specsync-coverage
artifact: context
---

# Context

Swift Retry already exposes a complete async retry library, but the SpecSync 5.0.1 migration initially produced an
empty companion scaffold. The implementation spans fourteen files; the Swift parser reports forty-eight public
names; and six test files contain sixty-four cases across twelve suites. A placeholder companion would create false
confidence at a nominal 100% path threshold, so this change documents the actual implementation and test behavior.

The migration is deliberately non-semantic. `Sources/`, `Tests/`, the package manifest, and runtime behavior remain
unchanged. The companion is derived from the checked-in implementation and verified against the parser and native
test suite.
