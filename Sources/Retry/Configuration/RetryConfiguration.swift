import Foundation

/// Configuration for retry behavior
public struct RetryConfiguration: Sendable {
    /// Maximum number of retry attempts
    public let maxAttempts: Int

    /// Maximum delay allowed between retries
    public let maxDelay: TimeInterval?

    /// Overall timeout for all retry attempts
    public let timeout: TimeInterval?

    /// Predicate to determine if an error should trigger a retry
    public let shouldRetry: @Sendable (Error) -> Bool

    /// Create a retry configuration
    /// - Parameters:
    ///   - maxAttempts: Maximum number of retry attempts (default: 3)
    ///   - maxDelay: Maximum delay allowed between retries (default: nil)
    ///   - timeout: Overall timeout for all retry attempts (default: nil)
    ///   - shouldRetry: Predicate to determine if retry should occur (default: always retry)
    public init(
        maxAttempts: Int = 3,
        maxDelay: TimeInterval? = nil,
        timeout: TimeInterval? = nil,
        shouldRetry: @escaping @Sendable (Error) -> Bool = { _ in true }
    ) {
        self.maxAttempts = maxAttempts
        self.maxDelay = maxDelay
        self.timeout = timeout
        self.shouldRetry = shouldRetry
    }

    /// Create a configuration that retries for specific error types
    /// - Parameters:
    ///   - maxAttempts: Maximum number of retry attempts
    ///   - maxDelay: Maximum delay allowed between retries
    ///   - timeout: Overall timeout for all retry attempts
    ///   - retryableErrors: Set of error types that should trigger a retry
    public static func forErrors<E: Error & Equatable>(
        maxAttempts: Int = 3,
        maxDelay: TimeInterval? = nil,
        timeout: TimeInterval? = nil,
        retryableErrors: Set<E>
    ) -> RetryConfiguration {
        RetryConfiguration(
            maxAttempts: maxAttempts,
            maxDelay: maxDelay,
            timeout: timeout,
            shouldRetry: { error in
                guard let typedError = error as? E else { return false }
                return retryableErrors.contains(typedError)
            }
        )
    }
}

public extension RetryConfiguration {
    /// Default configuration with 3 attempts and no limits
    static var `default`: RetryConfiguration {
        RetryConfiguration()
    }

    /// Conservative configuration with 5 attempts and timeouts
    static var conservative: RetryConfiguration {
        RetryConfiguration(
            maxAttempts: 5,
            maxDelay: 30.0,
            timeout: 120.0
        )
    }

    /// Aggressive configuration with 10 attempts
    static var aggressive: RetryConfiguration {
        RetryConfiguration(
            maxAttempts: 10,
            maxDelay: 60.0,
            timeout: 300.0
        )
    }
}
