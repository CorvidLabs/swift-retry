import Foundation
import Testing
@testable import Retry

@Suite("Configuration")
struct ConfigurationTests {
    @Test("Default configuration")
    func defaultConfiguration() {
        let config = RetryConfiguration.default

        #expect(config.maxAttempts == 3)
        #expect(config.maxDelay == nil)
        #expect(config.timeout == nil)
        #expect(config.shouldRetry(URLError(.networkConnectionLost)))
    }

    @Test("Conservative configuration")
    func conservativeConfiguration() {
        let config = RetryConfiguration.conservative

        #expect(config.maxAttempts == 5)
        #expect(config.maxDelay == 30.0)
        #expect(config.timeout == 120.0)
    }

    @Test("Aggressive configuration")
    func aggressiveConfiguration() {
        let config = RetryConfiguration.aggressive

        #expect(config.maxAttempts == 10)
        #expect(config.maxDelay == 60.0)
        #expect(config.timeout == 300.0)
    }

    @Test("Custom configuration")
    func customConfiguration() {
        let config = RetryConfiguration(
            maxAttempts: 7,
            maxDelay: 15.0,
            timeout: 90.0,
            shouldRetry: { _ in false }
        )

        #expect(config.maxAttempts == 7)
        #expect(config.maxDelay == 15.0)
        #expect(config.timeout == 90.0)
        #expect(!config.shouldRetry(URLError(.networkConnectionLost)))
    }

    @Test("Should retry predicate")
    func shouldRetryPredicate() {
        enum TestError: Error {
            case temporary
            case permanent
        }

        let config = RetryConfiguration(
            shouldRetry: { error in
                guard let testError = error as? TestError else { return false }
                return testError == .temporary
            }
        )

        #expect(config.shouldRetry(TestError.temporary))
        #expect(!config.shouldRetry(TestError.permanent))
        #expect(!config.shouldRetry(URLError(.badURL)))
    }

    @Test("For errors configuration")
    func forErrorsConfiguration() {
        enum NetworkError: Error, Equatable {
            case timeout
            case connectionLost
            case badResponse
        }

        let retryableErrors: Set<NetworkError> = [.timeout, .connectionLost]
        let config = RetryConfiguration.forErrors(
            maxAttempts: 5,
            maxDelay: 10.0,
            retryableErrors: retryableErrors
        )

        #expect(config.maxAttempts == 5)
        #expect(config.maxDelay == 10.0)

        #expect(config.shouldRetry(NetworkError.timeout))
        #expect(config.shouldRetry(NetworkError.connectionLost))
        #expect(!config.shouldRetry(NetworkError.badResponse))
        #expect(!config.shouldRetry(URLError(.badURL)))
    }

    @Test("Configuration is Sendable")
    func configurationIsSendable() {
        let config = RetryConfiguration(
            maxAttempts: 3,
            shouldRetry: { _ in true }
        )

        Task {
            _ = config.maxAttempts
            _ = config.shouldRetry(URLError(.networkConnectionLost))
        }
    }
}
