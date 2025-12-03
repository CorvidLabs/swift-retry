import Foundation

/// A retry strategy that uses a constant delay between attempts
public struct ConstantStrategy: RetryStrategy {
    private let constantDelay: TimeInterval

    /**
     Create a constant delay retry strategy
     - Parameter delay: The fixed delay between retry attempts
     */
    public init(delay: TimeInterval) {
        self.constantDelay = delay
    }

    public func delay(for attempt: Int) -> TimeInterval {
        constantDelay
    }
}

public extension RetryStrategy where Self == ConstantStrategy {
    /**
     Create a constant delay retry strategy
     - Parameter delay: The fixed delay between retry attempts
     */
    static func constant(_ delay: TimeInterval) -> ConstantStrategy {
        ConstantStrategy(delay: delay)
    }
}
