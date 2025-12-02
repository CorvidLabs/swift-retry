import Testing
import Foundation
@testable import Retry

@Suite("Circuit Breaker")
struct CircuitBreakerTests {
    @Test("Initial state is closed")
    func initialStateIsClosed() async {
        let breaker = CircuitBreaker()

        let state = await breaker.currentState
        #expect(state == .closed)

        let allowed = await breaker.shouldAllowRequest()
        #expect(allowed)
    }

    @Test("Failures increment count")
    func failuresIncrementCount() async {
        let breaker = CircuitBreaker(failureThreshold: 5)

        await breaker.recordFailure()
        let allowed1 = await breaker.shouldAllowRequest()
        #expect(allowed1)

        await breaker.recordFailure()
        let allowed2 = await breaker.shouldAllowRequest()
        #expect(allowed2)
    }

    @Test("Circuit opens at threshold")
    func circuitOpensAtThreshold() async {
        let breaker = CircuitBreaker(failureThreshold: 3)

        await breaker.recordFailure()
        await breaker.recordFailure()

        let closedState = await breaker.currentState
        #expect(closedState == .closed)

        await breaker.recordFailure()

        let openState = await breaker.currentState
        if case .open = openState {
            // Success
        } else {
            Issue.record("Circuit should be open, got: \(openState)")
        }

        let allowed = await breaker.shouldAllowRequest()
        #expect(!allowed)
    }

    @Test("Circuit stays open during timeout")
    func circuitStaysOpenDuringTimeout() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 1.0)

        await breaker.recordFailure()
        await breaker.recordFailure()

        let allowed1 = await breaker.shouldAllowRequest()
        #expect(!allowed1)

        try await Task.sleep(nanoseconds: 500_000_000)

        let allowed2 = await breaker.shouldAllowRequest()
        #expect(!allowed2)
    }

    @Test("Circuit transitions to half-open after timeout")
    func circuitTransitionsToHalfOpenAfterTimeout() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 0.2)

        await breaker.recordFailure()
        await breaker.recordFailure()

        let allowed1 = await breaker.shouldAllowRequest()
        #expect(!allowed1)

        try await Task.sleep(nanoseconds: 250_000_000)

        let allowed2 = await breaker.shouldAllowRequest()
        #expect(allowed2)

        let state = await breaker.currentState
        #expect(state == .halfOpen)
    }

    @Test("Success in half-open closes circuit")
    func successInHalfOpenClosesCircuit() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 0.1)

        await breaker.recordFailure()
        await breaker.recordFailure()

        try await Task.sleep(nanoseconds: 150_000_000)

        _ = await breaker.shouldAllowRequest()

        let halfOpenState = await breaker.currentState
        #expect(halfOpenState == .halfOpen)

        await breaker.recordSuccess()

        let closedState = await breaker.currentState
        #expect(closedState == .closed)

        let allowed = await breaker.shouldAllowRequest()
        #expect(allowed)
    }

    @Test("Success in closed resets failure count")
    func successInClosedResetsFailureCount() async {
        let breaker = CircuitBreaker(failureThreshold: 3)

        await breaker.recordFailure()
        await breaker.recordFailure()

        await breaker.recordSuccess()

        await breaker.recordFailure()
        await breaker.recordFailure()

        let state = await breaker.currentState
        #expect(state == .closed)
    }

    @Test("Reset method")
    func resetMethod() async {
        let breaker = CircuitBreaker(failureThreshold: 2)

        await breaker.recordFailure()
        await breaker.recordFailure()

        let openState = await breaker.currentState
        if case .open = openState {
            // Success
        } else {
            Issue.record("Circuit should be open")
        }

        await breaker.reset()

        let closedState = await breaker.currentState
        #expect(closedState == .closed)

        let allowed = await breaker.shouldAllowRequest()
        #expect(allowed)
    }

    @Test("Concurrent access")
    func concurrentAccess() async throws {
        let breaker = CircuitBreaker(failureThreshold: 10)

        await withTaskGroup(of: Void.self) { group in
            for _ in 1...5 {
                group.addTask {
                    await breaker.recordFailure()
                }
            }

            for _ in 1...5 {
                group.addTask {
                    await breaker.recordSuccess()
                }
            }

            for _ in 1...10 {
                group.addTask {
                    _ = await breaker.shouldAllowRequest()
                }
            }
        }

        let state = await breaker.currentState
        #expect(state != nil)
    }

    @Test("Multiple reset cycles")
    func multipleResetCycles() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 0.1)

        // First cycle
        await breaker.recordFailure()
        await breaker.recordFailure()

        let allowed1 = await breaker.shouldAllowRequest()
        #expect(!allowed1)

        try await Task.sleep(nanoseconds: 150_000_000)
        _ = await breaker.shouldAllowRequest()
        await breaker.recordSuccess()

        let state1 = await breaker.currentState
        #expect(state1 == .closed)

        // Second cycle
        await breaker.recordFailure()
        await breaker.recordFailure()

        let allowed2 = await breaker.shouldAllowRequest()
        #expect(!allowed2)

        try await Task.sleep(nanoseconds: 150_000_000)
        _ = await breaker.shouldAllowRequest()
        await breaker.recordSuccess()

        let state2 = await breaker.currentState
        #expect(state2 == .closed)
    }

    @Test("Circuit state description")
    func circuitStateDescription() {
        let closed = CircuitState.closed
        #expect(closed.description == "closed")

        let halfOpen = CircuitState.halfOpen
        #expect(halfOpen.description == "half-open")

        let openedAt = Date()
        let open = CircuitState.open(openedAt: openedAt)
        #expect(open.description.contains("open"))
    }

    @Test("Circuit state equality")
    func circuitStateEquality() {
        #expect(CircuitState.closed == CircuitState.closed)
        #expect(CircuitState.halfOpen == CircuitState.halfOpen)

        let date1 = Date()
        let date2 = Date(timeIntervalSinceNow: 100)

        #expect(CircuitState.open(openedAt: date1) == CircuitState.open(openedAt: date1))
        #expect(CircuitState.open(openedAt: date1) != CircuitState.open(openedAt: date2))

        #expect(CircuitState.closed != CircuitState.halfOpen)
        #expect(CircuitState.closed != CircuitState.open(openedAt: date1))
    }
}
