---
module: retry
version: 2
status: active
files:
  - Sources/Retry/Configuration/RetryConfiguration.swift
  - Sources/Retry/Core/RetryError.swift
  - Sources/Retry/Core/Retry.swift
  - Sources/Retry/Jitter/Jitter.swift
  - Sources/Retry/Jitter/DecorrelatedJitter.swift
  - Sources/Retry/Jitter/EqualJitter.swift
  - Sources/Retry/Jitter/FullJitter.swift
  - Sources/Retry/CircuitBreaker/CircuitBreaker.swift
  - Sources/Retry/CircuitBreaker/CircuitState.swift
  - Sources/Retry/Strategy/LinearStrategy.swift
  - Sources/Retry/Strategy/FibonacciStrategy.swift
  - Sources/Retry/Strategy/RetryStrategy.swift
  - Sources/Retry/Strategy/ExponentialStrategy.swift
  - Sources/Retry/Strategy/ConstantStrategy.swift

db_tables: []
depends_on: []
---

# Retry

## Purpose

The `retry` module executes `Sendable` asynchronous Swift operations until they succeed, become ineligible for
retry, exceed their configured attempt or time limit, or are rejected by an optional circuit breaker. It owns delay
strategies, jitter policies, retry configuration, circuit state, and typed terminal errors. It does not own the
operation being retried, persistence, networking, logging, or scheduling beyond the delay between attempts.

## Public API

### Exported Types and Protocols

| Export | Kind | Contract |
|--------|------|----------|
| `Retry` | enum namespace | Provides throwing `execute` overloads and `executeReturningResult` for async operations. |
| `RetryConfiguration` | `Sendable` struct | Holds `maxAttempts`, optional `maxDelay`, optional `timeout`, and a `@Sendable shouldRetry` predicate; also provides `forErrors` and preset configurations. |
| `RetryError` | `Error`, `Sendable`, `Equatable` enum | Represents exhausted attempts, timeout, an open circuit, and cancellation, with human-readable `description` values. |
| `CircuitBreaker` | actor | Serializes failure accounting and closed/open/half-open transitions through `currentState`, `recordSuccess`, `recordFailure`, `shouldAllowRequest`, and `reset`. |
| `CircuitState` | `Sendable`, `Equatable` enum | Represents `.closed`, `.open(openedAt:)`, and `.halfOpen`, with a human-readable `description`. |
| `ConstantStrategy` | struct | Returns the same configured delay for every attempt. |
| `LinearStrategy` | struct | Returns `base + increment * (attempt - 1)`. |
| `ExponentialStrategy` | struct | Returns `base * multiplier^(attempt - 1)`; the default multiplier is `2.0`. |
| `FibonacciStrategy` | struct | Returns `base` times the Fibonacci value for the attempt; nonpositive attempts map to zero. |
| `NoJitter` | struct | Returns the strategy delay unchanged. |
| `FullJitter` | struct | Returns a random delay in the inclusive range from zero through the strategy delay. |
| `EqualJitter` | struct | Returns half the strategy delay plus a random value from zero through the other half. |
| `DecorrelatedJitter` | struct | Returns a random delay from its configured base through three times the strategy delay. |
| `RetryStrategy` | `Sendable` protocol | Calculates a retry delay through `delay(for:)`. |
| `Jitter` | `Sendable` protocol | Transforms a delay through `apply(to:attempt:)`. |

### Exported Members

| Export | Contract |
|--------|----------|
| `maxAttempts` | Maximum number of operation attempts. |
| `maxDelay` | Optional cap applied after jitter. |
| `timeout` | Optional elapsed-time limit checked before an attempt. |
| `shouldRetry` | `@Sendable` predicate that selects retryable errors. |
| `forErrors` | Builds a configuration for a set of typed, equatable errors. |
| `init` | Initializes public configuration, strategy, jitter, and breaker values with their declared defaults. |
| `conservative` | Five-attempt preset with a 30-second delay cap and 120-second timeout. |
| `aggressive` | Ten-attempt preset with a 60-second delay cap and 300-second timeout. |
| `==` | Compares retry errors or circuit states, including associated values. |
| `description` | Returns diagnostic text for retry errors and circuit states. |
| `maxAttemptsExceeded` | Terminal retry error containing attempt count and final error description. |
| `circuitBreakerOpen` | Error emitted when a breaker denies admission. |
| `cancelled` | Public retry cancellation error representation. |
| `execute` | Runs a throwing async operation with the selected retry policies. |
| `executeReturningResult` | Converts throwing retry execution into `Result<Output, Error>`. |
| `apply` | Applies a jitter policy to a strategy delay and attempt number. |
| `none` | Static-member factory for `NoJitter`. |
| `decorrelated` | Static-member factory for `DecorrelatedJitter`. |
| `equal` | Static-member factory for `EqualJitter`. |
| `full` | Static-member factory for `FullJitter`. |
| `currentState` | Actor-isolated circuit state snapshot. |
| `recordSuccess` | Clears failures and closes a half-open breaker. |
| `recordFailure` | Increments failure count and opens at the threshold. |
| `shouldAllowRequest` | Applies closed/open/half-open admission and timeout transitions. |
| `reset` | Restores closed state and clears failures. |
| `closed` | Circuit state that permits requests. |
| `open` | Circuit state that records when the failure threshold was reached. |
| `halfOpen` | Circuit state used for a recovery probe. |
| `delay` | Calculates a strategy's delay for an attempt. |
| `linear` | Static-member factory for `LinearStrategy`. |
| `fibonacci` | Static-member factory for `FibonacciStrategy`. |
| `exponential` | Static-member factory for `ExponentialStrategy`. |
| `constant` | Static-member factory for `ConstantStrategy`. |

## Invariants

1. An attempt number starts at one, and no more than `RetryConfiguration.maxAttempts` operations are initiated.
2. A successful operation returns immediately and records circuit-breaker success when a breaker is present.
3. A rejected error is rethrown unchanged; an eligible final failure becomes `RetryError.maxAttemptsExceeded`.
4. Timeout and circuit-breaker admission are checked before each operation attempt.
5. Retry delay is calculated by the strategy, transformed by jitter, capped by `maxDelay` when present, and then
   passed to `Task.sleep`.
6. `CircuitBreaker` state and failure count remain actor-isolated. Reaching the failure threshold opens the circuit;
   an elapsed reset timeout admits a half-open request; success in half-open closes it.
7. Retry strategies and jitter policies are `Sendable`, and retried operations cross concurrency boundaries only as
   `@Sendable` async throwing closures.

## Behavioral Examples

### Scenario: Retry succeeds after a transient error

- **Given** an operation that fails once and then succeeds, with at least two attempts configured
- **When** `Retry.execute` runs the operation
- **Then** the first error is retried after the selected delay and the successful value is returned

### Scenario: Error is not retryable

- **Given** a configuration whose `shouldRetry` predicate rejects the operation error
- **When** the operation fails
- **Then** the original error is thrown without starting another attempt

### Scenario: Circuit breaker is open

- **Given** a breaker whose failure threshold has been reached and whose reset timeout has not elapsed
- **When** a retry execution asks for admission
- **Then** the operation is not invoked and `RetryError.circuitBreakerOpen` is thrown

## Error Cases

| Condition | Behavior |
|-----------|----------|
| Every allowed attempt fails with an eligible error | Throw `.maxAttemptsExceeded(attempts:lastError:)` with the final attempt count and error description. |
| Configured timeout is reached before an attempt | Throw `.timeout(duration:)` with the elapsed duration. |
| Circuit breaker denies admission | Throw `.circuitBreakerOpen` before invoking the operation. |
| Retry sleep is cancelled | Propagate the cancellation error thrown by `Task.sleep`; `.cancelled` remains a public representable error case. |
| `executeReturningResult` encounters any thrown error | Return `.failure(error)` instead of throwing. |

## Dependencies

### Consumes

| Module | What is used |
|--------|-------------|
| Swift standard library | Async/await, actors, `Task.sleep`, `Result`, errors, generics, and `Sendable`. |
| Foundation | `Date`, `TimeInterval`, and random time-interval generation. |

### Consumed By

| Module | What is used |
|--------|-------------|
| Package clients | The `retry` library product and its public retry, strategy, jitter, configuration, and circuit-breaker APIs. |

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-07-13 | 0xLeif | Documented the existing public API and behavior for SpecSync 5.0.1 without changing implementation. |
| 2026-07-14 | CHG-0002-document-the-existing-swift-retry-api-at-complete-specsync-coverage: Document the existing Swift Retry API at complete SpecSync coverage |
