import Foundation
import Testing
@testable import Retry

@Suite("Jitter")
struct JitterTests {
    @Test("No jitter returns exact delay")
    func noJitterReturnsExactDelay() {
        let jitter = NoJitter()
        let delays = [0.1, 1.0, 5.0, 10.0, 100.0]

        for delay in delays {
            for attempt in 1...10 {
                #expect(jitter.apply(to: delay, attempt: attempt) == delay)
            }
        }
    }

    @Test("Full jitter bounds")
    func fullJitterBounds() {
        let jitter = FullJitter()
        let delay = 20.0
        let iterations = 1000

        for attempt in 1...5 {
            for _ in 1...iterations {
                let jittered = jitter.apply(to: delay, attempt: attempt)
                #expect(jittered >= 0.0)
                #expect(jittered <= delay)
            }
        }
    }

    @Test("Full jitter randomness")
    func fullJitterRandomness() {
        let jitter = FullJitter()
        let delay = 10.0
        var results = Set<TimeInterval>()

        for _ in 1...100 {
            results.insert(jitter.apply(to: delay, attempt: 1))
        }

        #expect(results.count > 50)
    }

    @Test("Equal jitter bounds")
    func equalJitterBounds() {
        let jitter = EqualJitter()
        let delay = 20.0
        let half = delay / 2.0
        let iterations = 1000

        for attempt in 1...5 {
            for _ in 1...iterations {
                let jittered = jitter.apply(to: delay, attempt: attempt)
                #expect(jittered >= half)
                #expect(jittered <= delay)
            }
        }
    }

    @Test("Equal jitter randomness")
    func equalJitterRandomness() {
        let jitter = EqualJitter()
        let delay = 10.0
        var results = Set<TimeInterval>()

        for _ in 1...100 {
            results.insert(jitter.apply(to: delay, attempt: 1))
        }

        #expect(results.count > 50)
    }

    @Test("Decorrelated jitter bounds")
    func decorrelatedJitterBounds() {
        let base = 2.0
        let jitter = DecorrelatedJitter(base: base)
        let delay = 10.0
        let upperBound = delay * 3.0
        let iterations = 1000

        for attempt in 1...5 {
            for _ in 1...iterations {
                let jittered = jitter.apply(to: delay, attempt: attempt)
                #expect(jittered >= base)
                #expect(jittered <= upperBound)
            }
        }
    }

    @Test("Decorrelated jitter randomness")
    func decorrelatedJitterRandomness() {
        let jitter = DecorrelatedJitter(base: 1.0)
        let delay = 5.0
        var results = Set<TimeInterval>()

        for _ in 1...100 {
            results.insert(jitter.apply(to: delay, attempt: 1))
        }

        #expect(results.count > 50)
    }

    @Test("Decorrelated jitter default base")
    func decorrelatedJitterDefaultBase() {
        let jitter = DecorrelatedJitter()
        let delay = 5.0

        for _ in 1...100 {
            let jittered = jitter.apply(to: delay, attempt: 1)
            #expect(jittered >= 1.0) // Default base is 1.0
        }
    }

    @Test("Jitter with zero delay")
    func jitterWithZeroDelay() {
        let jitters: [any Jitter] = [
            NoJitter(),
            FullJitter(),
            EqualJitter(),
            DecorrelatedJitter(base: 0.0)
        ]

        for jitter in jitters {
            let result = jitter.apply(to: 0.0, attempt: 1)
            #expect(result >= 0.0)
        }
    }

    @Test("Jitter with small delays")
    func jitterWithSmallDelays() {
        let jitters: [any Jitter] = [
            FullJitter(),
            EqualJitter()
        ]

        let smallDelay = 0.001

        for jitter in jitters {
            for _ in 1...100 {
                let result = jitter.apply(to: smallDelay, attempt: 1)
                #expect(result >= 0.0)
                #expect(result <= smallDelay)
            }
        }
    }
}
