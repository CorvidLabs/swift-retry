---
spec: retry.spec.md
---

## Key Decisions

- Keep retry policy compositional: execution, delay strategy, jitter, configuration, and circuit breaking remain
  separate public types.
- Keep mutable breaker state in an actor so public breaker operations are safe under concurrent callers.
- Treat the implementation and its current tests as the source of truth for this documentation-only migration.
- Map all fourteen implementation files and all forty-eight names parsed by SpecSync; do not add inferred API that
  is absent from source.

## Files to Read First

- `Sources/Retry/Core/Retry.swift` for attempt ordering, delays, timeout handling, and result conversion.
- `Sources/Retry/Configuration/RetryConfiguration.swift` for retry selection and presets.
- `Sources/Retry/CircuitBreaker/CircuitBreaker.swift` for actor-isolated state transitions.
- `Sources/Retry/Strategy/RetryStrategy.swift` and `Sources/Retry/Jitter/Jitter.swift` for extension points.
- `Tests/RetryTests/RetryTests.swift` for end-to-end behavior and static-member syntax.

## Current Status

- The implementation consists of fourteen Swift source files in one `retry` library module.
- SpecSync 5.0.1 parses forty-eight distinct public names from those files.
- The test target contains sixty-four Swift Testing cases across twelve suites in six files.
- This companion is active and describes existing behavior only; the migration introduces no source or test edits.

## Notes

- Attempt numbering is one-based in the executor and strategy formulas.
- `RetryError.cancelled` is public, while cancellation thrown by the retry delay currently propagates from
  `Task.sleep` rather than being translated by the executor.
- Decorrelated jitter requires its configured base not to exceed three times the input delay; callers own valid
  policy inputs, matching the current implementation.
