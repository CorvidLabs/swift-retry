# Changelog

All notable changes to swift-retry will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-01

### Added
- Initial release of swift-retry package
- Pure Swift 6 implementation with strict concurrency support
- Full Sendable conformance throughout
- Core retry engine with async/await support
- Multiple retry strategies:
  - Constant delay strategy
  - Linear backoff strategy
  - Exponential backoff strategy
  - Fibonacci sequence strategy
- Jitter implementations to prevent thundering herd:
  - No jitter
  - Full jitter (random 0 to delay)
  - Equal jitter (half + random half)
  - Decorrelated jitter (AWS-style)
- Circuit breaker pattern implementation:
  - Configurable failure threshold
  - Automatic state transitions (closed, open, half-open)
  - Reset timeout configuration
- Flexible retry configuration:
  - Max attempts control
  - Max delay capping
  - Overall timeout support
  - Custom retry predicates
  - Error-specific retry configuration
- Result-based API for non-throwing contexts
- Protocol-oriented design for extensibility
- Static member syntax support for clean API
- Comprehensive test coverage (64 tests)
- Platform support:
  - iOS 15+
  - macOS 12+
  - tvOS 15+
  - watchOS 8+
  - visionOS 1+

### Documentation
- Complete README with usage examples
- API documentation comments
- Example code file demonstrating all features
- Changelog for version tracking

[0.1.0]: https://github.com/CorvidLabs/swift-retry/releases/tag/0.1.0
