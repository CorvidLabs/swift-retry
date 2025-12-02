import Foundation

/// Errors that can occur during retry operations
public enum RetryError: Error, Sendable, Equatable {
    /// Maximum number of retry attempts exceeded
    case maxAttemptsExceeded(attempts: Int, lastError: String)

    /// Operation timed out before completion
    case timeout(duration: TimeInterval)

    /// Circuit breaker is open, preventing retry attempts
    case circuitBreakerOpen

    /// The retry operation was cancelled
    case cancelled

    public static func == (lhs: RetryError, rhs: RetryError) -> Bool {
        switch (lhs, rhs) {
        case let (.maxAttemptsExceeded(lAttempts, lError), .maxAttemptsExceeded(rAttempts, rError)):
            return lAttempts == rAttempts && lError == rError
        case let (.timeout(lDuration), .timeout(rDuration)):
            return lDuration == rDuration
        case (.circuitBreakerOpen, .circuitBreakerOpen):
            return true
        case (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
}

extension RetryError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .maxAttemptsExceeded(attempts, lastError):
            return "Maximum retry attempts (\(attempts)) exceeded. Last error: \(lastError)"
        case let .timeout(duration):
            return "Operation timed out after \(duration) seconds"
        case .circuitBreakerOpen:
            return "Circuit breaker is open, preventing retry attempts"
        case .cancelled:
            return "Retry operation was cancelled"
        }
    }
}
