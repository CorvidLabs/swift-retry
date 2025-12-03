import Foundation

/// Protocol for adding randomness to retry delays to prevent thundering herd problem
public protocol Jitter: Sendable {
    /**
     Apply jitter to a calculated delay
     - Parameters:
       - delay: The base delay calculated by the retry strategy
       - attempt: The current attempt number
     - Returns: The jittered delay
     */
    func apply(to delay: TimeInterval, attempt: Int) -> TimeInterval
}

/// No jitter applied - uses the exact delay from the strategy
public struct NoJitter: Jitter {
    public init() {}

    public func apply(to delay: TimeInterval, attempt: Int) -> TimeInterval {
        delay
    }
}

public extension Jitter where Self == NoJitter {
    /// No jitter - uses the exact delay from the strategy
    static var none: NoJitter {
        NoJitter()
    }
}
