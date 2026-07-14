---
change: CHG-0002-document-the-existing-swift-retry-api-at-complete-specsync-coverage
artifact: design
---

# Design

The canonical `retry` companion maps every Swift file in `Sources/retry`. Its main spec records module ownership,
the public types and protocols, all parser-visible member names, invariants, examples, errors, and dependencies.
Stable requirements separate attempt execution, error eligibility, timing, configuration presets, strategies,
jitter, circuit-breaker lifecycle, and concurrency. Context and testing companions make implementation navigation
and evidence explicit.

The status is active because the companion describes shipped behavior rather than proposed work. No new API,
algorithm, dependency, or test is introduced. Exact formulas and state transitions are copied semantically from
source, while the testing companion records the observed six-file, twelve-suite, sixty-four-case inventory.
