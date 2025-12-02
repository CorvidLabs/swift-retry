import Foundation
import Retry

// MARK: - Basic Examples

/// Simple retry with default settings
func basicRetry() async throws {
    let result = try await Retry.execute(maxAttempts: 3) {
        try await fetchUserData()
    }
    print("User data: \(result)")
}

/// Retry with exponential backoff and jitter
func exponentialBackoffExample() async throws {
    let result = try await Retry.execute(
        maxAttempts: 5,
        strategy: .exponential(base: 1.0, multiplier: 2.0),
        jitter: .full
    ) {
        try await makeAPICall()
    }
    print("API response: \(result)")
}

/// Retry with circuit breaker pattern
func circuitBreakerExample() async throws {
    let circuitBreaker = CircuitBreaker(
        failureThreshold: 5,
        resetTimeout: 60.0
    )

    let result = try await Retry.execute(
        maxAttempts: 3,
        strategy: .linear(base: 1.0, increment: 0.5),
        circuitBreaker: circuitBreaker
    ) {
        try await callExternalService()
    }
    print("Service response: \(result)")
}

/// Advanced configuration with custom error handling
func advancedConfigurationExample() async throws {
    let config = RetryConfiguration(
        maxAttempts: 7,
        maxDelay: 30.0,
        timeout: 120.0,
        shouldRetry: { error in
            // Only retry on network errors
            if let urlError = error as? URLError {
                return [
                    .networkConnectionLost,
                    .timedOut,
                    .cannotConnectToHost
                ].contains(urlError.code)
            }
            return false
        }
    )

    let result = try await Retry.execute(
        configuration: config,
        strategy: .fibonacci(base: 1.0),
        jitter: .decorrelated(base: 0.5)
    ) {
        try await performNetworkOperation()
    }
    print("Result: \(result)")
}

/// Using Result-based API
func resultBasedExample() async {
    let result = await Retry.executeReturningResult(
        maxAttempts: 5,
        strategy: .exponential(base: 2.0),
        jitter: .equal
    ) {
        try await downloadFile()
    }

    switch result {
    case let .success(data):
        print("Downloaded \(data.count) bytes")
    case let .failure(error):
        print("Failed to download: \(error)")
    }
}

/// Error-specific retry configuration
func errorSpecificRetryExample() async throws {
    enum DatabaseError: Error, Equatable {
        case connectionTimeout
        case deadlock
        case constraintViolation
    }

    let config = RetryConfiguration.forErrors(
        maxAttempts: 5,
        maxDelay: 10.0,
        retryableErrors: Set([
            DatabaseError.connectionTimeout,
            DatabaseError.deadlock
        ])
    )

    try await Retry.execute(
        configuration: config,
        strategy: .exponential(base: 0.5)
    ) {
        try await performDatabaseOperation()
    }
}

// MARK: - Mock Functions

func fetchUserData() async throws -> String {
    "User{id: 123, name: \"John\"}"
}

func makeAPICall() async throws -> String {
    "API Response"
}

func callExternalService() async throws -> String {
    "Service OK"
}

func performNetworkOperation() async throws -> String {
    "Network operation completed"
}

func downloadFile() async throws -> Data {
    Data()
}

func performDatabaseOperation() async throws {
    // Database operation
}

// MARK: - Running Examples

@main
struct ExampleRunner {
    static func main() async {
        do {
            print("=== Basic Retry ===")
            try await basicRetry()

            print("\n=== Exponential Backoff ===")
            try await exponentialBackoffExample()

            print("\n=== Circuit Breaker ===")
            try await circuitBreakerExample()

            print("\n=== Advanced Configuration ===")
            try await advancedConfigurationExample()

            print("\n=== Result-Based API ===")
            await resultBasedExample()

            print("\n=== Error-Specific Retry ===")
            try await errorSpecificRetryExample()

            print("\nAll examples completed successfully!")
        } catch {
            print("Error: \(error)")
        }
    }
}
