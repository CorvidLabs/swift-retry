import Foundation

/// The state of a circuit breaker
public enum CircuitState: Sendable, Equatable {
    /// Normal operation - requests are allowed through
    case closed

    /// Failure threshold exceeded - requests are blocked
    case open(openedAt: Date)

    /// Testing if the service has recovered - limited requests allowed
    case halfOpen

    public static func == (lhs: CircuitState, rhs: CircuitState) -> Bool {
        switch (lhs, rhs) {
        case (.closed, .closed):
            return true
        case let (.open(lDate), .open(rDate)):
            return lDate == rDate
        case (.halfOpen, .halfOpen):
            return true
        default:
            return false
        }
    }
}

extension CircuitState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .closed:
            return "closed"
        case let .open(openedAt):
            return "open (since \(openedAt))"
        case .halfOpen:
            return "half-open"
        }
    }
}
