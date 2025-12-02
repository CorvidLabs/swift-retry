import Testing
@testable import Retry

@Suite("Strategy")
struct StrategyTests {
    @Test("Constant strategy consistency")
    func constantStrategyConsistency() {
        let strategy = ConstantStrategy(delay: 5.0)

        for attempt in 1...100 {
            #expect(strategy.delay(for: attempt) == 5.0)
        }
    }

    @Test("Linear strategy growth")
    func linearStrategyGrowth() {
        let strategy = LinearStrategy(base: 2.0, increment: 1.5)

        #expect(strategy.delay(for: 1) == 2.0)
        #expect(strategy.delay(for: 2) == 3.5)
        #expect(strategy.delay(for: 3) == 5.0)
        #expect(strategy.delay(for: 10) == 15.5)
    }

    @Test("Exponential strategy growth")
    func exponentialStrategyGrowth() {
        let strategy = ExponentialStrategy(base: 0.5, multiplier: 3.0)

        #expect(strategy.delay(for: 1) == 0.5)
        #expect(strategy.delay(for: 2) == 1.5)
        #expect(strategy.delay(for: 3) == 4.5)
        #expect(strategy.delay(for: 4) == 13.5)
    }

    @Test("Exponential strategy default multiplier")
    func exponentialStrategyDefaultMultiplier() {
        let strategy = ExponentialStrategy(base: 1.0)

        #expect(strategy.delay(for: 1) == 1.0)
        #expect(strategy.delay(for: 2) == 2.0)
        #expect(strategy.delay(for: 3) == 4.0)
    }

    @Test("Fibonacci strategy sequence")
    func fibonacciStrategySequence() {
        let strategy = FibonacciStrategy(base: 1.0)

        // Fibonacci: 1, 1, 2, 3, 5, 8, 13, 21...
        #expect(strategy.delay(for: 1) == 1.0)
        #expect(strategy.delay(for: 2) == 1.0)
        #expect(strategy.delay(for: 3) == 2.0)
        #expect(strategy.delay(for: 4) == 3.0)
        #expect(strategy.delay(for: 5) == 5.0)
        #expect(strategy.delay(for: 6) == 8.0)
        #expect(strategy.delay(for: 7) == 13.0)
        #expect(strategy.delay(for: 8) == 21.0)
    }

    @Test("Fibonacci strategy large numbers")
    func fibonacciStrategyLargeNumbers() {
        let strategy = FibonacciStrategy(base: 1.0)

        let delay = strategy.delay(for: 20)
        #expect(delay > 0)
    }
}
