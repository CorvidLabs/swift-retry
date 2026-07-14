---
spec: retry.spec.md
---

## Automated Testing

The package has sixty-four `@Test` cases across twelve suites in six Swift Testing files.

| Test File | Cases | What It Covers |
|-----------|------:|----------------|
| `Tests/RetryTests/RetryTests.swift` | 23 | Success and exhaustion, all strategies and jitters, breaker integration, max delay, timeout, retry predicate, result API, full integration, and static factories. |
| `Tests/RetryTests/CircuitBreakerTests.swift` | 12 | Initial state, thresholds, timeout transitions, recovery, reset cycles, concurrency, descriptions, and equality. |
| `Tests/RetryTests/JitterTests.swift` | 10 | Exact no-jitter behavior, randomized bounds and variation, default base, zero delay, and small delays. |
| `Tests/RetryTests/ConfigurationTests.swift` | 7 | Default and named presets, custom values, predicates, typed error sets, and `Sendable` use. |
| `Tests/RetryTests/ErrorTests.swift` | 6 | Error descriptions, equality, associated values, and `Sendable` use. |
| `Tests/RetryTests/StrategyTests.swift` | 6 | Constant, linear, exponential, and Fibonacci calculations including defaults and larger values. |

The native verification lane runs `swift build -v` followed by `swift test -v` through Fledge.

## Manual Testing

No separate manual product flow is required for this documentation-only migration. Review consists of comparing the
companion against the public declarations and formulas in all fourteen source files, confirming the parsed export
inventory, and verifying that the migration diff does not modify `Sources/` or `Tests/`.

## Edge Cases & Boundary Conditions

| Scenario | Expected Behavior |
|----------|-------------------|
| Operation succeeds on its first attempt | Return immediately without sleeping. |
| Final eligible attempt fails | Throw `.maxAttemptsExceeded` containing the final attempt count and error description. |
| Predicate rejects an error | Rethrow that error without another attempt. |
| Timeout has elapsed before an attempt | Throw `.timeout` before invoking the operation. |
| Breaker remains within reset timeout | Deny admission and surface `.circuitBreakerOpen`. |
| Breaker reset timeout elapses | Move to half-open and admit the probe request. |
| Jitter is randomized | Every sampled value remains within the algorithm's documented inclusive bounds. |
| Retry task is cancelled during delay | Propagate the error thrown by `Task.sleep`. |
| Circuit breaker is used concurrently | Actor isolation serializes mutable state access. |
