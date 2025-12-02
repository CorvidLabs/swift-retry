import Foundation

/// A circuit breaker that prevents cascading failures by stopping retry attempts
/// when a failure threshold is exceeded
public actor CircuitBreaker {
    private var state: CircuitState
    private var failureCount: Int
    private let failureThreshold: Int
    private let resetTimeout: TimeInterval

    /// Create a circuit breaker
    /// - Parameters:
    ///   - failureThreshold: Number of consecutive failures before opening the circuit
    ///   - resetTimeout: Time to wait before transitioning from open to half-open
    public init(
        failureThreshold: Int = 5,
        resetTimeout: TimeInterval = 60.0
    ) {
        self.state = .closed
        self.failureCount = 0
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }

    /// Get the current state of the circuit breaker
    public var currentState: CircuitState {
        state
    }

    /// Record a successful operation
    public func recordSuccess() {
        failureCount = 0
        if case .halfOpen = state {
            state = .closed
        }
    }

    /// Record a failed operation
    public func recordFailure() {
        failureCount += 1

        if failureCount >= failureThreshold {
            state = .open(openedAt: Date())
        }
    }

    /// Check if an operation should be allowed
    /// - Returns: `true` if the operation can proceed, `false` if blocked
    public func shouldAllowRequest() -> Bool {
        switch state {
        case .closed:
            return true

        case let .open(openedAt):
            let elapsed = Date().timeIntervalSince(openedAt)
            if elapsed >= resetTimeout {
                state = .halfOpen
                failureCount = 0
                return true
            }
            return false

        case .halfOpen:
            return true
        }
    }

    /// Reset the circuit breaker to closed state
    public func reset() {
        state = .closed
        failureCount = 0
    }
}
