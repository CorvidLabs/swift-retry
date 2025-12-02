# SwiftRetry

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-lightgrey.svg)
![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)

A robust, protocol-oriented retry library for Swift 6 with comprehensive backoff strategies, jitter support, and circuit breaker patterns.

## Features

- **Pure Swift 6** with strict concurrency checking
- **Sendable** and thread-safe throughout
- **Multiple retry strategies**: Constant, Linear, Exponential, Fibonacci
- **Jitter support**: Full, Equal, Decorrelated, and None
- **Circuit Breaker** pattern to prevent cascading failures
- **Flexible configuration** with predicates and timeouts
- **No external dependencies** (except swift-docc-plugin)
- **Comprehensive test coverage**

## Platform Support

- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+
- visionOS 1+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CorvidLabs/swift-retry.git", from: "0.1.0")
]
```

## Quick Start

### Basic Usage

```swift
import Retry

let result = try await Retry.execute(maxAttempts: 3) {
    try await fetchData()
}
```

### With Exponential Backoff and Jitter

```swift
let result = try await Retry.execute(
    maxAttempts: 5,
    strategy: .exponential(base: 1.0, multiplier: 2.0),
    jitter: .full
) {
    try await networkRequest()
}
```

### With Circuit Breaker

```swift
let breaker = CircuitBreaker(failureThreshold: 5, resetTimeout: 60.0)

let result = try await Retry.execute(
    maxAttempts: 3,
    strategy: .fibonacci(base: 1.0),
    circuitBreaker: breaker
) {
    try await externalAPICall()
}
```

### With Configuration

```swift
let config = RetryConfiguration(
    maxAttempts: 5,
    maxDelay: 30.0,
    timeout: 120.0,
    shouldRetry: { error in
        // Only retry network errors
        return error is URLError
    }
)

let result = try await Retry.execute(
    configuration: config,
    strategy: .exponential(base: 2.0),
    jitter: .decorrelated()
) {
    try await operation()
}
```

## Retry Strategies

### Constant
Fixed delay between retries:
```swift
.constant(2.0) // 2 second delay each time
```

### Linear
Linearly increasing delay:
```swift
.linear(base: 1.0, increment: 0.5)
// Delays: 1.0, 1.5, 2.0, 2.5...
```

### Exponential
Exponential backoff:
```swift
.exponential(base: 1.0, multiplier: 2.0)
// Delays: 1.0, 2.0, 4.0, 8.0...
```

### Fibonacci
Fibonacci sequence delays:
```swift
.fibonacci(base: 1.0)
// Delays: 1.0, 1.0, 2.0, 3.0, 5.0, 8.0...
```

## Jitter Types

### No Jitter
Uses exact delay from strategy:
```swift
jitter: .none
```

### Full Jitter
Random delay between 0 and calculated delay:
```swift
jitter: .full
```

### Equal Jitter
Half delay + random half:
```swift
jitter: .equal
```

### Decorrelated Jitter
AWS-style decorrelated jitter:
```swift
jitter: .decorrelated(base: 1.0)
```

## Circuit Breaker

Prevent cascading failures by opening the circuit after a threshold:

```swift
let breaker = CircuitBreaker(
    failureThreshold: 5,  // Open after 5 failures
    resetTimeout: 60.0     // Try again after 60 seconds
)

// Use with retry
let result = try await Retry.execute(
    maxAttempts: 3,
    circuitBreaker: breaker
) {
    try await operation()
}

// Check state
let state = await breaker.currentState // .closed, .open, or .halfOpen

// Reset manually if needed
await breaker.reset()
```

## Error Handling

The library provides specific error types:

```swift
do {
    let result = try await Retry.execute(maxAttempts: 3) {
        try await operation()
    }
} catch RetryError.maxAttemptsExceeded(let attempts, let lastError) {
    print("Failed after \(attempts) attempts: \(lastError)")
} catch RetryError.timeout(let duration) {
    print("Timed out after \(duration) seconds")
} catch RetryError.circuitBreakerOpen {
    print("Circuit breaker is open")
} catch {
    print("Operation failed: \(error)")
}
```

## Result-Based API

For non-throwing contexts:

```swift
let result = await Retry.executeReturningResult(
    maxAttempts: 3,
    strategy: .exponential(base: 1.0)
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

## Advanced Configuration

### Predefined Configurations

```swift
// Default: 3 attempts, no limits
.default

// Conservative: 5 attempts with timeouts
.conservative

// Aggressive: 10 attempts with longer timeouts
.aggressive
```

### Custom Error Filtering

```swift
enum APIError: Error, Equatable {
    case rateLimit
    case serverError
    case badRequest
}

let config = RetryConfiguration.forErrors(
    maxAttempts: 5,
    retryableErrors: Set([APIError.rateLimit, APIError.serverError])
)

// Only retries on rateLimit and serverError
try await Retry.execute(configuration: config, strategy: .exponential(base: 2.0)) {
    try await apiCall()
}
```

## Design Philosophy

This library follows protocol-oriented design principles:

- **Protocols over classes**: `RetryStrategy` and `Jitter` are protocols
- **Value types**: Strategies and configurations are structs
- **Composition**: Mix and match strategies, jitter, and circuit breakers
- **Type safety**: Strong typing prevents runtime errors
- **Sendable**: Safe for concurrent use with async/await
- **Clean API**: Static member syntax for common cases

## Testing

Run tests with:
```bash
swift test
```

Build the package:
```bash
swift build
```

## License

MIT

## Contributing

Contributions welcome! Please ensure:
- Swift 6 compatibility
- Sendable conformance
- Comprehensive tests
- Documentation for public APIs
