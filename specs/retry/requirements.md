---
spec: retry.spec.md
---

## User Stories

- As a package client, I want to retry an asynchronous throwing operation under explicit attempt, delay, timeout,
  and error-selection policies so transient failures can recover predictably.
- As a package client, I want reusable delay and jitter policies so concurrent retries can be tuned without changing
  the operation.
- As a service owner, I want an actor-isolated circuit breaker so repeated failures can stop new attempts and later
  probe recovery safely.
- As a maintainer, I want the existing public contract mapped to source and tests so non-semantic governance changes
  cannot silently alter runtime behavior.

## Constraints

- The migration changes governance and documentation only; it does not modify `Sources/` or `Tests/`.
- Public retry execution remains async/await based and accepts `@Sendable` operations.
- Delay values are expressed as Foundation `TimeInterval` seconds.
- The package's existing platform and Swift-version declarations remain authoritative; this specification does not
  broaden compatibility.

## Out of Scope

- Performing network requests or other retried work.
- Persisting circuit state across process launches or sharing it between breaker instances.
- Logging, metrics, tracing, rate limiting, queues, or distributed coordination.
- Changing the retry algorithms, public API, package manifest, or test suite as part of this migration.

### REQ-retry-001

The retry executor SHALL invoke the supplied `@Sendable` async throwing operation no more than the configured
`maxAttempts`, return the first successful value immediately, and represent final eligible exhaustion as
`RetryError.maxAttemptsExceeded` with the final attempt count and error description.

Acceptance Criteria

- A first-attempt success returns without another operation invocation.
- A later success returns after only the preceding failed attempts.
- A final eligible failure reports the configured attempt count and final error description.

### REQ-retry-002

The retry executor SHALL use `RetryConfiguration.shouldRetry` to decide error eligibility, rethrow rejected errors
unchanged, support typed error sets through `forErrors`, and map throwing execution to `Result` when
`executeReturningResult` is selected.

Acceptance Criteria

- A rejected error starts no additional attempt and retains its original error value.
- `forErrors` retries only matching values of the supplied `Error & Equatable` type.
- Result-based execution returns `.success` for a value and `.failure` for every thrown error.

### REQ-retry-003

The retry executor SHALL check configured elapsed timeout before each operation attempt, calculate delay with the
selected strategy and jitter, cap the transformed delay at `maxDelay` when present, and asynchronously sleep before
the next attempt.

Acceptance Criteria

- An elapsed timeout throws `RetryError.timeout` before invoking the next operation attempt.
- The strategy receives the current one-based attempt number.
- A jittered delay above `maxDelay` is capped before `Task.sleep`.

### REQ-retry-004

`RetryConfiguration` SHALL provide the shipped default, conservative, and aggressive presets without changing their
attempt, delay-cap, or timeout values.

Acceptance Criteria

- Default uses three attempts with no maximum delay or timeout.
- Conservative uses five attempts, a 30-second maximum delay, and a 120-second timeout.
- Aggressive uses ten attempts, a 60-second maximum delay, and a 300-second timeout.

### REQ-retry-005

Retry strategies SHALL calculate constant, linear, exponential, and Fibonacci delays according to their current
one-based formulas.

Acceptance Criteria

- Constant delay is invariant across attempts.
- Linear delay is `base + increment * (attempt - 1)`.
- Exponential delay is `base * multiplier^(attempt - 1)` and defaults the multiplier to two.
- Fibonacci delay multiplies the base by zero for nonpositive attempts, one for attempts one and two, and the
  subsequent Fibonacci value thereafter.

### REQ-retry-006

Jitter policies SHALL transform delays within the bounds defined by no jitter, full jitter, equal jitter, and
decorrelated jitter.

Acceptance Criteria

- No jitter returns the input delay exactly.
- Full jitter stays from zero through the input delay.
- Equal jitter stays from half through all of the input delay.
- Decorrelated jitter stays from its configured base through three times the input delay.

### REQ-retry-007

`CircuitBreaker` SHALL actor-isolate failure accounting and implement the closed, open, and half-open lifecycle using
its configured failure threshold and reset timeout.

Acceptance Criteria

- A new or reset breaker is closed, has no recorded failures, and allows requests.
- Reaching the failure threshold opens the breaker and denies requests until the reset timeout elapses.
- The first admission after the timeout moves the breaker to half-open and clears the failure count.
- Success in half-open closes the breaker; recorded failures continue to participate in threshold accounting.

### REQ-retry-008

Public retry policy and error values SHALL preserve their concurrency and diagnostic contracts: configuration,
strategies, jitter, retry errors, and circuit states remain `Sendable`; circuit mutation remains actor-isolated; and
errors and states retain their associated-value equality and descriptions.

Acceptance Criteria

- `RetryConfiguration`, `RetryStrategy`, `Jitter`, `RetryError`, and `CircuitState` are usable across their declared
  concurrency boundaries.
- Concurrent breaker access is serialized by the actor.
- Retry errors and circuit states compare associated values and expose their current diagnostic descriptions.

