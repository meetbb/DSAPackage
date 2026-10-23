# Designing Data-Intensive Applications

A top-down map of Martin Kleppmann's book, one level deeper at a time.

## Overview
When we think about designing Data-Intensive applications, we should think about it in 3 important parts.
- #### The Foundations of Data Systems
- #### Distributed Data
- #### Derived Data

Each part has its individual core concepts which are really essential to get a deeper understanding of system designing. I will give you the high-level picture of these three parts then we will go one level deeper in each part. First of all, we will get the high-level map of the foundations of data systems.

#### The Foundations of Data Systems has 4 important sub-branches (Chapters 1–4):
- Reliable, Scalable, and Maintainable Applications
- Data Models and Query Languages
- Storage and Retrieval
- Encoding and Evolution

#### Distributed Data has 5 important concepts in its sub-branches (Chapters 5–9):
- Replication
- Partitioning
- Transactions
- The Trouble with Distributed Systems
- Consistency and Consensus

#### Derived Data has 3 important concepts (Chapters 10–12):
- Batch Processing
- Stream Processing
- The Future of Data Systems

## Concept Tree

Read this top to bottom every day. Say each branch out loud: what it is, why it exists, then the example.

```text
DATA-INTENSIVE APPLICATIONS (problem: data is big, complex, fast-changing, not CPU-bound)
│
├── PART I: FOUNDATIONS OF DATA SYSTEMS (building blocks of any data system)
│   │
│   ├── Ch 1: Reliable, Scalable, Maintainable
│   │   │
│   │   ├── RELIABILITY: keeps working when things break
│   │   │   ├── Fault (one part) vs Failure (whole system) → goal: fault tolerance
│   │   │   ├── Hardware faults → redundancy (independent, so copies help)
│   │   │   ├── Software faults → testing, isolation, restart (correlated, copies don't help)
│   │   │   └── Human errors → good interfaces, sandboxes, fast rollback (Chaos Monkey)
│   │   │
│   │   ├── SCALABILITY: keeps working when it grows
│   │   │   ├── 1. Describe LOAD → load parameters
│   │   │   │   └── Twitter timeline: fan-out on read vs on write → hybrid for celebrities
│   │   │   ├── 2. Describe PERFORMANCE
│   │   │   │   ├── Throughput (batch) vs Response time (online)
│   │   │   │   │   └── Response time = waiting (latency) + processing + network
│   │   │   │   ├── Use percentiles, not the average
│   │   │   │   │   ├── p50 = typical user
│   │   │   │   │   └── p95 / p99 / p999 = the slow tail (zoom into slow end)
│   │   │   │   ├── Why the tail matters
│   │   │   │   │   ├── Best customers are often the slowest (Amazon)
│   │   │   │   │   ├── Head-of-line blocking: slow requests hold up fast ones behind
│   │   │   │   │   └── Tail latency amplification: 1% slow x 100 calls = 63% slow pages
│   │   │   │   ├── Targets: SLO (internal goal) vs SLA (contract with consequences)
│   │   │   │   └── Monitoring: rolling window → approximate (t-digest) → add histograms,
│   │   │   │       never average percentiles
│   │   │   └── 3. COPING with load
│   │   │       ├── Scale up (bigger machine) vs scale out (more machines), usually a mix
│   │   │       ├── Elastic (auto) vs manual scaling
│   │   │       ├── Stateless is easy to spread, stateful is hard
│   │   │       └── No magic scaling sauce: design around your load parameters
│   │   │
│   │   └── MAINTAINABILITY: people can keep working on it for years
│   │       ├── Operability → easy to run
│   │       ├── Simplicity → easy to understand (remove accidental complexity, use abstraction)
│   │       └── Evolvability → easy to change
│   │
│   ├── Ch 2: Data Models and Query Languages
│   ├── Ch 3: Storage and Retrieval
│   └── Ch 4: Encoding and Evolution
│
├── PART II: DISTRIBUTED DATA (data spread over many machines)
│   ├── Ch 5: Replication
│   ├── Ch 6: Partitioning
│   ├── Ch 7: Transactions
│   ├── Ch 8: The Trouble with Distributed Systems
│   └── Ch 9: Consistency and Consensus
│
└── PART III: DERIVED DATA (data computed from other data)
    ├── Ch 10: Batch Processing
    ├── Ch 11: Stream Processing
    └── Ch 12: The Future of Data Systems
```

Chapters not yet studied are left as single lines. Grow the tree one branch at a time as you learn them.

## Topics

### The Three Parts

- <doc:Part1-FoundationsOfDataSystems>
- <doc:Part2-DistributedData>
- <doc:Part3-DerivedData>
