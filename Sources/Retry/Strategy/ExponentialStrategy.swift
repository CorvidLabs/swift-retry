import Foundation

/// A retry strategy that exponentially increases delay with each attempt
public struct ExponentialStrategy: RetryStrategy {
    private let base: TimeInterval
    private let multiplier: Double

    /**
     Create an exponential backoff retry strategy
     - Parameters:
       - base: The base delay duration
       - multiplier: The multiplier applied exponentially (delay = base * multiplier^attempt)
     */
    public init(base: TimeInterval, multiplier: Double = 2.0) {
        self.base = base
        self.multiplier = multiplier
    }

    public func delay(for attempt: Int) -> TimeInterval {
        base * pow(multiplier, Double(attempt - 1))
    }
}

public extension RetryStrategy where Self == ExponentialStrategy {
    /**
     Create an exponential backoff retry strategy
     - Parameters:
       - base: The base delay duration
       - multiplier: The multiplier applied exponentially (default: 2.0)
     */
    static func exponential(base: TimeInterval, multiplier: Double = 2.0) -> ExponentialStrategy {
        ExponentialStrategy(base: base, multiplier: multiplier)
    }
}
