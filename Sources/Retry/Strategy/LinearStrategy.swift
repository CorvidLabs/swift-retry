import Foundation

/// A retry strategy that linearly increases delay with each attempt
public struct LinearStrategy: RetryStrategy {
    private let base: TimeInterval
    private let increment: TimeInterval

    /**
     Create a linear backoff retry strategy
     - Parameters:
       - base: The initial delay for the first retry
       - increment: The amount to increase delay with each attempt
     */
    public init(base: TimeInterval, increment: TimeInterval) {
        self.base = base
        self.increment = increment
    }

    public func delay(for attempt: Int) -> TimeInterval {
        base + (increment * TimeInterval(attempt - 1))
    }
}

public extension RetryStrategy where Self == LinearStrategy {
    /**
     Create a linear backoff retry strategy
     - Parameters:
       - base: The initial delay for the first retry
       - increment: The amount to increase delay with each attempt
     */
    static func linear(base: TimeInterval, increment: TimeInterval) -> LinearStrategy {
        LinearStrategy(base: base, increment: increment)
    }
}
