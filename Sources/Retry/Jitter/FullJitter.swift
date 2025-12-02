import Foundation

/// Full jitter: returns a random value between 0 and the calculated delay
public struct FullJitter: Jitter {
    public init() {}

    public func apply(to delay: TimeInterval, attempt: Int) -> TimeInterval {
        TimeInterval.random(in: 0...delay)
    }
}

public extension Jitter where Self == FullJitter {
    /// Full jitter: returns a random value between 0 and the calculated delay
    static var full: FullJitter {
        FullJitter()
    }
}
