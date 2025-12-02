import Foundation

/// Decorrelated jitter: AWS-style jitter that maintains some correlation with previous delays
/// while adding randomness to prevent synchronization
public struct DecorrelatedJitter: Jitter {
    private let base: TimeInterval

    /// Create a decorrelated jitter
    /// - Parameter base: The base delay used as a lower bound
    public init(base: TimeInterval = 1.0) {
        self.base = base
    }

    public func apply(to delay: TimeInterval, attempt: Int) -> TimeInterval {
        let upperBound = delay * 3.0
        return TimeInterval.random(in: base...upperBound)
    }
}

public extension Jitter where Self == DecorrelatedJitter {
    /// Decorrelated jitter: AWS-style jitter that maintains some correlation with previous delays
    /// - Parameter base: The base delay used as a lower bound (default: 1.0)
    static func decorrelated(base: TimeInterval = 1.0) -> DecorrelatedJitter {
        DecorrelatedJitter(base: base)
    }
}
