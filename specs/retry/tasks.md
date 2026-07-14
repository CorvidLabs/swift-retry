---
spec: retry.spec.md
---

## Tasks

- [x] Inventory the fourteen Swift implementation files owned by the `retry` module.
- [x] Inventory the forty-eight public names parsed from the current source.
- [x] Map retry execution, configuration, strategies, jitter, circuit breaking, and errors to stable requirements.
- [x] Inventory the sixty-four automated tests across twelve suites and six files.
- [x] Record the migration boundary that leaves `Sources/` and `Tests/` unchanged.

## Gaps

No uncovered source files or parsed public exports are accepted for this active companion. Runtime behavior outside
the documented contract remains outside this documentation-only change rather than being represented as migration
work.

## Review Sign-offs

- **Product**: not applicable; existing library behavior is unchanged
- **QA**: protected by the existing native build and sixty-four-test suite
- **Design**: not applicable; no API or architecture change
- **Dev**: source and parsed-export inventory completed
