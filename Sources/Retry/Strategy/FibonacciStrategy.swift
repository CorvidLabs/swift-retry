import Foundation

/// A retry strategy that uses Fibonacci sequence for delay calculation
public struct FibonacciStrategy: RetryStrategy {
    private let base: TimeInterval

    /// Create a Fibonacci sequence retry strategy
    /// - Parameter base: The base unit of time multiplied by the Fibonacci number
    public init(base: TimeInterval) {
        self.base = base
    }

    public func delay(for attempt: Int) -> TimeInterval {
        base * TimeInterval(fibonacci(attempt))
    }

    private func fibonacci(_ n: Int) -> Int {
        guard n > 0 else { return 0 }
        guard n > 2 else { return 1 }

        var previous = 1
        var current = 1

        for _ in 3...n {
            let next = previous + current
            previous = current
            current = next
        }

        return current
    }
}

public extension RetryStrategy where Self == FibonacciStrategy {
    /// Create a Fibonacci sequence retry strategy
    /// - Parameter base: The base unit of time multiplied by the Fibonacci number
    static func fibonacci(base: TimeInterval) -> FibonacciStrategy {
        FibonacciStrategy(base: base)
    }
}
