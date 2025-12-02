# Swift Retry - Quick Reference

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/swift-retry.git", from: "1.0.0")
]
```

## Basic Usage

```swift
import Retry

// Simple retry
let result = try await Retry.execute(maxAttempts: 3) {
    try await operation()
}
```

## Retry Strategies

```swift
// Constant delay
.constant(2.0)                                    // 2s, 2s, 2s...

// Linear backoff
.linear(base: 1.0, increment: 0.5)               // 1s, 1.5s, 2s...

// Exponential backoff
.exponential(base: 1.0, multiplier: 2.0)         // 1s, 2s, 4s, 8s...

// Fibonacci sequence
.fibonacci(base: 1.0)                            // 1s, 1s, 2s, 3s, 5s...
```

## Jitter Options

```swift
.none                                             // No randomization
.full                                             // Random(0, delay)
.equal                                            // delay/2 + Random(0, delay/2)
.decorrelated(base: 1.0)                         // Random(base, delay * 3)
```

## Complete Examples

### With Strategy and Jitter
```swift
try await Retry.execute(
    maxAttempts: 5,
    strategy: .exponential(base: 1.0, multiplier: 2.0),
    jitter: .full
) {
    try await networkCall()
}
```

### With Circuit Breaker
```swift
let breaker = CircuitBreaker(
    failureThreshold: 5,
    resetTimeout: 60.0
)

try await Retry.execute(
    maxAttempts: 3,
    circuitBreaker: breaker
) {
    try await externalAPI()
}
```

### With Configuration
```swift
let config = RetryConfiguration(
    maxAttempts: 5,
    maxDelay: 30.0,
    timeout: 120.0,
    shouldRetry: { error in
        error is URLError
    }
)

try await Retry.execute(
    configuration: config,
    strategy: .exponential(base: 2.0),
    jitter: .decorrelated()
) {
    try await operation()
}
```

### Error-Specific Retry
```swift
enum APIError: Error, Equatable {
    case rateLimit
    case serverError
    case badRequest
}

let config = RetryConfiguration.forErrors(
    maxAttempts: 5,
    retryableErrors: Set([.rateLimit, .serverError])
)

try await Retry.execute(
    configuration: config,
    strategy: .fibonacci(base: 1.0)
) {
    try await apiCall()
}
```

### Result-Based API
```swift
let result = await Retry.executeReturningResult(
    maxAttempts: 3,
    strategy: .constant(1.0)
) {
    try await operation()
}

switch result {
case .success(let value):
    print("Success: \(value)")
case .failure(let error):
    print("Failed: \(error)")
}
```

## Predefined Configurations

```swift
.default        // 3 attempts, no limits
.conservative   // 5 attempts, 30s max delay, 120s timeout
.aggressive     // 10 attempts, 60s max delay, 300s timeout
```

## Error Handling

```swift
do {
    try await Retry.execute { ... }
} catch RetryError.maxAttemptsExceeded(let attempts, let lastError) {
    print("Failed after \(attempts) attempts")
} catch RetryError.timeout(let duration) {
    print("Timed out after \(duration)s")
} catch RetryError.circuitBreakerOpen {
    print("Circuit breaker is open")
} catch RetryError.cancelled {
    print("Operation cancelled")
} catch {
    print("Other error: \(error)")
}
```

## Circuit Breaker States

```swift
let breaker = CircuitBreaker(...)

await breaker.currentState  // .closed, .open, or .halfOpen
await breaker.recordSuccess()
await breaker.recordFailure()
await breaker.reset()
```

## Key Features

- Pure Swift 6 with strict concurrency
- Sendable throughout
- No external dependencies (except swift-docc-plugin)
- Protocol-oriented design
- Type-safe with generics
- Actor-based circuit breaker
- Comprehensive test coverage

## Platform Support

- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+
- visionOS 1+
