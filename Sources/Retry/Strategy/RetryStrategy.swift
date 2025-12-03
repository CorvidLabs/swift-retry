import Foundation

/// Protocol defining a retry delay strategy
public protocol RetryStrategy: Sendable {
    /**
     Calculate the delay before the next retry attempt
     - Parameter attempt: The attempt number (starting from 1)
     - Returns: The delay duration in seconds
     */
    func delay(for attempt: Int) -> TimeInterval
}
