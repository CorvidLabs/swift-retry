import Foundation
import Testing
@testable import Retry

actor AttemptCounter {
    private var count = 0

    func increment() -> Int {
        count += 1
        return count
    }

    func get() -> Int {
        count
    }

    func reset() {
        count = 0
    }
}

@Suite("Basic Retry")
struct BasicRetryTests {
    @Test("Successful operation on first attempt")
    func successfulOperationOnFirstAttempt() async throws {
        let counter = AttemptCounter()

        let result = try await Retry.execute(maxAttempts: 3) {
            _ = await counter.increment()
            return "Success"
        }

        #expect(result == "Success")
        let attempts = await counter.get()
        #expect(attempts == 1)
    }

    @Test("Successful operation after retries")
    func successfulOperationAfterRetries() async throws {
        let counter = AttemptCounter()

        let result = try await Retry.execute(maxAttempts: 5) {
            let attempt = await counter.increment()
            if attempt < 3 {
                throw URLError(.networkConnectionLost)
            }
            return "Success"
        }

        #expect(result == "Success")
        let attempts = await counter.get()
        #expect(attempts == 3)
    }

    @Test("Failure after max attempts")
    func failureAfterMaxAttempts() async {
        let counter = AttemptCounter()

        do {
            _ = try await Retry.execute(maxAttempts: 3) {
                _ = await counter.increment()
                throw URLError(.networkConnectionLost)
            }
            Issue.record("Should have thrown an error")
        } catch let error as RetryError {
            if case let .maxAttemptsExceeded(attempts, _) = error {
                #expect(attempts == 3)
                let actualAttempts = await counter.get()
                #expect(actualAttempts == 3)
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

@Suite("Strategy")
struct StrategyBasicTests {
    @Test("Constant strategy")
    func constantStrategy() {
        let strategy = ConstantStrategy(delay: 2.0)

        #expect(strategy.delay(for: 1) == 2.0)
        #expect(strategy.delay(for: 2) == 2.0)
        #expect(strategy.delay(for: 5) == 2.0)
    }

    @Test("Linear strategy")
    func linearStrategy() {
        let strategy = LinearStrategy(base: 1.0, increment: 0.5)

        #expect(strategy.delay(for: 1) == 1.0)
        #expect(strategy.delay(for: 2) == 1.5)
        #expect(strategy.delay(for: 3) == 2.0)
        #expect(strategy.delay(for: 4) == 2.5)
    }

    @Test("Exponential strategy")
    func exponentialStrategy() {
        let strategy = ExponentialStrategy(base: 1.0, multiplier: 2.0)

        #expect(strategy.delay(for: 1) == 1.0)
        #expect(strategy.delay(for: 2) == 2.0)
        #expect(strategy.delay(for: 3) == 4.0)
        #expect(strategy.delay(for: 4) == 8.0)
    }

    @Test("Fibonacci strategy")
    func fibonacciStrategy() {
        let strategy = FibonacciStrategy(base: 1.0)

        #expect(strategy.delay(for: 1) == 1.0)
        #expect(strategy.delay(for: 2) == 1.0)
        #expect(strategy.delay(for: 3) == 2.0)
        #expect(strategy.delay(for: 4) == 3.0)
        #expect(strategy.delay(for: 5) == 5.0)
        #expect(strategy.delay(for: 6) == 8.0)
    }
}

@Suite("Jitter Basic")
struct JitterBasicTests {
    @Test("No jitter")
    func noJitter() {
        let jitter = NoJitter()
        let delay = 5.0

        #expect(jitter.apply(to: delay, attempt: 1) == delay)
        #expect(jitter.apply(to: delay, attempt: 5) == delay)
    }

    @Test("Full jitter bounds")
    func fullJitter() {
        let jitter = FullJitter()
        let delay = 10.0

        for _ in 1...10 {
            let jittered = jitter.apply(to: delay, attempt: 1)
            #expect(jittered >= 0.0 && jittered <= delay)
        }
    }

    @Test("Equal jitter bounds")
    func equalJitter() {
        let jitter = EqualJitter()
        let delay = 10.0

        for _ in 1...10 {
            let jittered = jitter.apply(to: delay, attempt: 1)
            let half = delay / 2.0
            #expect(jittered >= half && jittered <= delay)
        }
    }

    @Test("Decorrelated jitter")
    func decorrelatedJitter() {
        let base = 1.0
        let jitter = DecorrelatedJitter(base: base)
        let delay = 10.0

        for _ in 1...10 {
            let jittered = jitter.apply(to: delay, attempt: 1)
            #expect(jittered >= base)
        }
    }
}

@Suite("Circuit Breaker Basic")
struct CircuitBreakerBasicTests {
    @Test("Closed state")
    func closedState() async {
        let breaker = CircuitBreaker(failureThreshold: 3)

        let allowed = await breaker.shouldAllowRequest()
        #expect(allowed)

        let state = await breaker.currentState
        #expect(state == .closed)
    }

    @Test("Opens after failures")
    func opensAfterFailures() async {
        let breaker = CircuitBreaker(failureThreshold: 3, resetTimeout: 1.0)

        await breaker.recordFailure()
        await breaker.recordFailure()
        await breaker.recordFailure()

        let state = await breaker.currentState
        if case .open = state {
            // Success
        } else {
            Issue.record("Circuit breaker should be open")
        }

        let allowed = await breaker.shouldAllowRequest()
        #expect(!allowed)
    }

    @Test("Transitions to half-open")
    func transitionsToHalfOpen() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 0.1)

        await breaker.recordFailure()
        await breaker.recordFailure()

        try await Task.sleep(nanoseconds: 150_000_000)

        let allowed = await breaker.shouldAllowRequest()
        #expect(allowed)
    }

    @Test("Closes after success")
    func closesAfterSuccess() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 0.1)

        await breaker.recordFailure()
        await breaker.recordFailure()

        try await Task.sleep(nanoseconds: 150_000_000)

        _ = await breaker.shouldAllowRequest()
        await breaker.recordSuccess()

        let state = await breaker.currentState
        #expect(state == .closed)
    }

    @Test("Retry with circuit breaker")
    func retryWithCircuitBreaker() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 10.0)
        let counter = AttemptCounter()

        do {
            _ = try await Retry.execute(
                maxAttempts: 5,
                circuitBreaker: breaker
            ) {
                _ = await counter.increment()
                throw URLError(.networkConnectionLost)
            }
            Issue.record("Should have thrown an error")
        } catch {
            let attempts = await counter.get()
            #expect(attempts <= 3)
        }
    }
}

@Suite("Configuration")
struct ConfigurationBasicTests {
    @Test("With max delay")
    func withMaxDelay() async throws {
        let config = RetryConfiguration(maxAttempts: 3, maxDelay: 2.0)
        let strategy = ExponentialStrategy(base: 1.0, multiplier: 10.0)
        let counter = AttemptCounter()
        let startTime = Date()

        do {
            _ = try await Retry.execute(
                configuration: config,
                strategy: strategy
            ) {
                _ = await counter.increment()
                throw URLError(.networkConnectionLost)
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            #expect(duration < 6.0)
        }
    }

    @Test("With timeout")
    func withTimeout() async throws {
        let config = RetryConfiguration(maxAttempts: 10, timeout: 0.5)

        do {
            _ = try await Retry.execute(
                configuration: config,
                strategy: .constant(0.3)
            ) {
                throw URLError(.networkConnectionLost)
            }
            Issue.record("Should have thrown timeout error")
        } catch let error as RetryError {
            if case .timeout = error {
                // Success
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Should retry predicate")
    func shouldRetryPredicate() async throws {
        enum CustomError: Error {
            case retryable
            case fatal
        }

        let config = RetryConfiguration(
            maxAttempts: 5,
            shouldRetry: { error in
                guard let customError = error as? CustomError else { return false }
                return customError == .retryable
            }
        )

        let counter = AttemptCounter()

        do {
            _ = try await Retry.execute(
                configuration: config,
                strategy: .constant(0.01)
            ) {
                let attempt = await counter.increment()
                if attempt < 3 {
                    throw CustomError.retryable
                }
                return "Success"
            }
        } catch {
            Issue.record("Should have succeeded: \(error)")
        }

        let attempts = await counter.get()
        #expect(attempts == 3)

        await counter.reset()
        do {
            _ = try await Retry.execute(
                configuration: config,
                strategy: .constant(0.01)
            ) {
                _ = await counter.increment()
                throw CustomError.fatal
            }
            Issue.record("Should have thrown fatal error")
        } catch let error as CustomError {
            #expect(error == .fatal)
            let attempts = await counter.get()
            #expect(attempts == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

@Suite("Result API")
struct ResultAPITests {
    @Test("Execute returning result success")
    func executeReturningResultSuccess() async {
        let result = await Retry.executeReturningResult(maxAttempts: 3) {
            return "Success"
        }

        switch result {
        case let .success(value):
            #expect(value == "Success")
        case let .failure(error):
            Issue.record("Should have succeeded: \(error)")
        }
    }

    @Test("Execute returning result failure")
    func executeReturningResultFailure() async {
        let result = await Retry.executeReturningResult(maxAttempts: 2) {
            throw URLError(.networkConnectionLost)
        }

        switch result {
        case .success:
            Issue.record("Should have failed")
        case .failure:
            break // Expected
        }
    }
}

@Suite("Integration")
struct IntegrationTests {
    @Test("Full integration")
    func fullIntegration() async throws {
        let breaker = CircuitBreaker(failureThreshold: 5)
        let config = RetryConfiguration(
            maxAttempts: 5,
            maxDelay: 3.0
        )

        let counter = AttemptCounter()

        let result = try await Retry.execute(
            configuration: config,
            strategy: .exponential(base: 0.1, multiplier: 2.0),
            jitter: .full,
            circuitBreaker: breaker
        ) {
            let attempt = await counter.increment()
            if attempt < 3 {
                throw URLError(.networkConnectionLost)
            }
            return "Success after \(attempt) attempts"
        }

        let attempts = await counter.get()
        #expect(attempts == 3)
        #expect(result.contains("Success"))
    }

    @Test("Static member syntax")
    func staticMemberSyntax() async throws {
        _ = try? await Retry.execute(
            maxAttempts: 2,
            strategy: .constant(1.0),
            jitter: .none
        ) {
            return "test"
        }

        _ = try? await Retry.execute(
            maxAttempts: 2,
            strategy: .linear(base: 1.0, increment: 0.5),
            jitter: .full
        ) {
            return "test"
        }

        _ = try? await Retry.execute(
            maxAttempts: 2,
            strategy: .exponential(base: 1.0, multiplier: 2.0),
            jitter: .equal
        ) {
            return "test"
        }

        _ = try? await Retry.execute(
            maxAttempts: 2,
            strategy: .fibonacci(base: 1.0),
            jitter: .decorrelated(base: 0.5)
        ) {
            return "test"
        }
    }
}
