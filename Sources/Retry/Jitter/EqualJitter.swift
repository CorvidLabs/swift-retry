import Foundation

/// Equal jitter: returns half the delay plus a random value between 0 and the other half
public struct EqualJitter: Jitter {
    public init() {}

    public func apply(to delay: TimeInterval, attempt: Int) -> TimeInterval {
        let half = delay / 2.0
        return half + TimeInterval.random(in: 0...half)
    }
}

public extension Jitter where Self == EqualJitter {
    /// Equal jitter: returns half the delay plus a random value between 0 and the other half
    static var equal: EqualJitter {
        EqualJitter()
    }
}
