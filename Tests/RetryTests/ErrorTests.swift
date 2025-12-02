import Testing
@testable import Retry

@Suite("Errors")
struct ErrorTests {
    @Test("Max attempts exceeded error")
    func maxAttemptsExceededError() {
        let error = RetryError.maxAttemptsExceeded(attempts: 5, lastError: "Network timeout")

        #expect(error.description.contains("5"))
        #expect(error.description.contains("Network timeout"))
    }

    @Test("Timeout error")
    func timeoutError() {
        let error = RetryError.timeout(duration: 30.5)

        #expect(error.description.contains("30.5"))
        #expect(error.description.contains("timed out"))
    }

    @Test("Circuit breaker open error")
    func circuitBreakerOpenError() {
        let error = RetryError.circuitBreakerOpen

        #expect(error.description.contains("Circuit breaker"))
        #expect(error.description.contains("open"))
    }

    @Test("Cancelled error")
    func cancelledError() {
        let error = RetryError.cancelled

        #expect(error.description.contains("cancelled"))
    }

    @Test("Error equality")
    func errorEquality() {
        let error1 = RetryError.maxAttemptsExceeded(attempts: 3, lastError: "Test")
        let error2 = RetryError.maxAttemptsExceeded(attempts: 3, lastError: "Test")
        let error3 = RetryError.maxAttemptsExceeded(attempts: 4, lastError: "Test")
        let error4 = RetryError.maxAttemptsExceeded(attempts: 3, lastError: "Different")

        #expect(error1 == error2)
        #expect(error1 != error3)
        #expect(error1 != error4)

        let timeout1 = RetryError.timeout(duration: 30.0)
        let timeout2 = RetryError.timeout(duration: 30.0)
        let timeout3 = RetryError.timeout(duration: 60.0)

        #expect(timeout1 == timeout2)
        #expect(timeout1 != timeout3)

        let cb1 = RetryError.circuitBreakerOpen
        let cb2 = RetryError.circuitBreakerOpen

        #expect(cb1 == cb2)

        let cancelled1 = RetryError.cancelled
        let cancelled2 = RetryError.cancelled

        #expect(cancelled1 == cancelled2)

        #expect(error1 != timeout1)
        #expect(timeout1 != cb1)
        #expect(cb1 != cancelled1)
    }

    @Test("Error is Sendable")
    func errorIsSendable() {
        Task {
            let error = RetryError.maxAttemptsExceeded(attempts: 3, lastError: "Test")
            _ = error.description
        }
    }
}
