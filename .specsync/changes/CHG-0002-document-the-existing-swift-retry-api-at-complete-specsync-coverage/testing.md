---
change: CHG-0002-document-the-existing-swift-retry-api-at-complete-specsync-coverage
artifact: testing
---

# Testing

Verification uses the repository's native Fledge lane, which runs `swift build -v` and `swift test -v`. The existing
test inventory is sixty-four cases across twelve suites in `RetryTests.swift`, `CircuitBreakerTests.swift`,
`JitterTests.swift`, `ConfigurationTests.swift`, `ErrorTests.swift`, and `StrategyTests.swift`.

Spec verification must pass in strict mode with a 100% threshold and must account for all forty-eight public names.
The migration diff must show no edits under `Sources/` or `Tests/`. Trust doctor and Trust verification provide the
governance-level configuration and committed-range checks after the SpecSync lifecycle is complete.

| Requirement evidence | Native test evidence |
|----------------------|----------------------|
| `REQ-retry-001` | `Tests/RetryTests/RetryTests.swift` — first success, later success, and exhausted attempts. |
| `REQ-retry-002` | `Tests/RetryTests/RetryTests.swift`, `Tests/RetryTests/ConfigurationTests.swift` — predicates, typed errors, and result API. |
| `REQ-retry-003` | `Tests/RetryTests/RetryTests.swift` — timeout, maximum delay, and strategy/jitter integration. |
| `REQ-retry-004` | `Tests/RetryTests/ConfigurationTests.swift` — default, conservative, and aggressive values. |
| `REQ-retry-005` | `Tests/RetryTests/StrategyTests.swift` — all four formulas and defaults. |
| `REQ-retry-006` | `Tests/RetryTests/JitterTests.swift` — exact and randomized bounds. |
| `REQ-retry-007` | `Tests/RetryTests/CircuitBreakerTests.swift`, `Tests/RetryTests/RetryTests.swift` — transitions, reset, concurrency, and execution integration. |
| `REQ-retry-008` | `Tests/RetryTests/ConfigurationTests.swift`, `Tests/RetryTests/ErrorTests.swift`, `Tests/RetryTests/CircuitBreakerTests.swift` — concurrency, equality, and descriptions. |
