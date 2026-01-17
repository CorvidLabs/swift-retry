import Foundation

/// Main retry execution engine with async/await support
public enum Retry {
    /**
     Execute an operation with retry logic
     - Parameters:
       - maxAttempts: Maximum number of retry attempts
       - strategy: Delay strategy between retries
       - jitter: Jitter to apply to delays
       - circuitBreaker: Optional circuit breaker to prevent cascading failures
       - configuration: Additional retry configuration
       - operation: The async operation to execute
     - Returns: The result of the operation
     - Throws: The last error if all retries fail, or a RetryError
     */
    public static func execute<Output>(
        maxAttempts: Int = 3,
        strategy: some RetryStrategy = ConstantStrategy(delay: 1.0),
        jitter: some Jitter = NoJitter(),
        circuitBreaker: CircuitBreaker? = nil,
        configuration: RetryConfiguration? = nil,
        operation: @Sendable () async throws -> Output
    ) async throws -> Output {
        let config = configuration ?? RetryConfiguration(maxAttempts: maxAttempts)
        let startTime = Date()

        var lastError: Error?

        for attempt in 1...config.maxAttempts {
            // Check timeout
            if let timeout = config.timeout {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed >= timeout {
                    throw RetryError.timeout(duration: elapsed)
                }
            }

            // Check circuit breaker
            if let breaker = circuitBreaker {
                let allowed = await breaker.shouldAllowRequest()
                guard allowed else {
                    throw RetryError.circuitBreakerOpen
                }
            }

            do {
                let result = try await operation()

                // Record success in circuit breaker
                if let breaker = circuitBreaker {
                    await breaker.recordSuccess()
                }

                return result

            } catch {
                lastError = error

                // Record failure in circuit breaker
                if let breaker = circuitBreaker {
                    await breaker.recordFailure()
                }

                // Check if we should retry this error
                guard config.shouldRetry(error) else {
                    throw error
                }

                // If this was the last attempt, throw the error
                guard attempt < config.maxAttempts else {
                    throw RetryError.maxAttemptsExceeded(
                        attempts: attempt,
                        lastError: String(describing: error)
                    )
                }

                // Calculate delay with jitter
                let baseDelay = strategy.delay(for: attempt)
                var delayWithJitter = jitter.apply(to: baseDelay, attempt: attempt)

                // Apply max delay cap if specified
                if let maxDelay = config.maxDelay {
                    delayWithJitter = min(delayWithJitter, maxDelay)
                }

                // Wait before next attempt
                try await Task.sleep(nanoseconds: UInt64(delayWithJitter * 1_000_000_000))
            }
        }

        // This should never be reached, but satisfies the compiler
        throw lastError ?? RetryError.maxAttemptsExceeded(
            attempts: config.maxAttempts,
            lastError: "Unknown error"
        )
    }

    /**
     Execute an operation with a full configuration object
     - Parameters:
       - configuration: Retry configuration
       - strategy: Delay strategy between retries
       - jitter: Jitter to apply to delays
       - circuitBreaker: Optional circuit breaker
       - operation: The async operation to execute
     - Returns: The result of the operation
     - Throws: The last error if all retries fail, or a RetryError
     */
    public static func execute<Output>(
        configuration: RetryConfiguration,
        strategy: some RetryStrategy,
        jitter: some Jitter = NoJitter(),
        circuitBreaker: CircuitBreaker? = nil,
        operation: @Sendable () async throws -> Output
    ) async throws -> Output {
        try await execute(
            maxAttempts: configuration.maxAttempts,
            strategy: strategy,
            jitter: jitter,
            circuitBreaker: circuitBreaker,
            configuration: configuration,
            operation: operation
        )
    }

    /**
     Execute an operation with minimal configuration (convenience method)
     - Parameters:
       - maxAttempts: Maximum number of retry attempts
       - operation: The async operation to execute
     - Returns: The result of the operation
     - Throws: The last error if all retries fail, or a RetryError
     */
    public static func execute<Output>(
        maxAttempts: Int = 3,
        operation: @Sendable () async throws -> Output
    ) async throws -> Output {
        try await execute(
            maxAttempts: maxAttempts,
            strategy: ConstantStrategy(delay: 1.0),
            jitter: NoJitter(),
            operation: operation
        )
    }
}

// MARK: - Result-based API

public extension Retry {
    /**
     Execute an operation and return a Result
     - Parameters:
       - maxAttempts: Maximum number of retry attempts
       - strategy: Delay strategy between retries
       - jitter: Jitter to apply to delays
       - circuitBreaker: Optional circuit breaker
       - configuration: Additional retry configuration
       - operation: The async operation to execute
     - Returns: A Result containing either the success value or the final error
     */
    static func executeReturningResult<Output>(
        maxAttempts: Int = 3,
        strategy: some RetryStrategy = ConstantStrategy(delay: 1.0),
        jitter: some Jitter = NoJitter(),
        circuitBreaker: CircuitBreaker? = nil,
        configuration: RetryConfiguration? = nil,
        operation: @Sendable () async throws -> Output
    ) async -> Result<Output, Error> {
        do {
            let result = try await execute(
                maxAttempts: maxAttempts,
                strategy: strategy,
                jitter: jitter,
                circuitBreaker: circuitBreaker,
                configuration: configuration,
                operation: operation
            )
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
}
