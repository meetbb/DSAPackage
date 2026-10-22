# Part I: The Foundations of Data Systems

The building blocks that every data system, single-node or distributed, is made from.

## Overview
Chapters 1–4 of the book:
1. Reliable, Scalable, and Maintainable Applications
2. Data Models and Query Languages
3. Storage and Retrieval
4. Encoding and Evolution

## Chapter 1: Reliable, Scalable, and Maintainable Applications
Most apps today are **data-intensive**, not compute-intensive. Their hard problems are *how much* data there is, *how complicated* it is, and *how fast it changes*. Raw CPU speed is rarely the bottleneck.

To build such an app well, the book asks three questions:

| Concern | The question | Sub-branches |
|---|---|---|
| **Reliability** | Does it keep working when things break? | Hardware faults, Software errors, Human errors |
| **Scalability** | Does it keep working when it gets bigger? | Describing load, Describing performance, Coping with load |
| **Maintainability** | Can people keep working on it for years? | Operability, Simplicity, Evolvability |

**Interview one-liner:** "A good data system keeps working when things break, keeps working as it grows, and stays easy for new people to change."

### Reliability: "It keeps working even when things break"
Things *will* break. A reliable system is one where a broken part does not take the whole app down. "Working correctly" means:
- It does what the user expects.
- It tolerates user mistakes and unexpected use.
- It is fast enough for the use case.
- It prevents unauthorized access and abuse.

Two words you must not mix up:
- **Fault**: one *part* of the system misbehaves (a disk dies).
- **Failure**: the *whole system* stops serving the user.

We cannot get to zero faults, so the goal is a **fault-tolerant** design: faults happen, but they never turn into failures.

| Source of faults | Example | Typical defense |
|---|---|---|
| **Hardware** | Disks crash, RAM goes bad, power cut. In a cluster of 10,000 disks, expect about one to die per day. | Redundancy (RAID, backup power, spare machines). Increasingly, software that survives the loss of a whole machine. |
| **Software** | A bug that crashes every server at once (the 2012 leap-second bug hung many Linux servers). A runaway process eats all CPU or memory. One failing service drags down others (cascading failure). | Careful design and testing, process isolation, letting processes crash and restart, monitoring in production. |
| **Human** | A bad config push. Studies cited in the book suggest configuration mistakes by operators cause more outages than hardware does. | Well-designed interfaces that make the right thing easy, sandboxes to experiment safely, thorough testing, fast rollbacks, clear monitoring, and training. |

**Why hardware and software faults differ:** hardware faults are mostly independent (one disk dying rarely kills another), so redundancy works. Software faults are often *correlated* (the same bug hits every server), so redundancy alone does not save you.

**Bonus idea:** Netflix's *Chaos Monkey* deliberately kills random servers in production to prove the system really tolerates faults.

**Interview one-liner:** "Reliability means tolerating faults so they never become failures, whether the cause is hardware, software, or people."

### Scalability: "It keeps working when it gets bigger"
Scalability is **not** a yes/no label. The honest question is: *"If the system grows in a particular way, what are our options for coping?"* Answering it takes three steps.

#### 1. Describing load
Pick a few numbers, called **load parameters**, that capture what your system is being asked to do. The right ones depend on the system: requests per second to a web server, the read/write ratio in a database, the number of simultaneous users in a chat room, or the hit rate on a cache.

**Example, Twitter's home timeline:** the book uses roughly 4.6k tweets/sec on average (12k at peak) being posted, but about 300k requests/sec to *read* home timelines. The hard part is not the tweets, it is **fan-out**: each user follows many people and is followed by many.

| Approach | How it works | Trade-off |
|---|---|---|
| 1. Query at read time | Store tweets once. When someone opens their timeline, look up everyone they follow and merge those tweets. | Cheap writes, **expensive reads**. |
| 2. Fan-out on write | When someone tweets, push it into a pre-built timeline "mailbox" for every follower. | **Cheap reads**, expensive writes. Fast to read, but one celebrity with millions of followers means millions of writes per tweet. |
| Hybrid (what Twitter moved to) | Use approach 2 for most users, but treat celebrities with approach 1 and merge at read time. | More complex, but fits the real load. |

The lesson: the *distribution* of followers per user is the key load parameter, not just the tweet count.

#### 2. Describing performance
Once load is described, ask two questions: if load grows and resources stay the same, how is performance affected? And how many resources do we need to add to keep performance the same?

- **Throughput** = how much work per second (batch systems care most about this).
- **Response time** = how long a client waits (online systems care most about this).

Response time is not one number, it is a **distribution**, so don't use the average. Use **percentiles**:

| Percentile | Meaning |
|---|---|
| **p50 (median)** | Half of requests are faster than this, half are slower. |
| **p95 / p99 / p999** | 95% / 99% / 99.9% of requests are faster than this. The slow ones are called **tail latencies**. |

**Why tail latency matters:** the slowest requests often belong to your *best* customers (they have the most data). The book notes Amazon found a 100 ms slowdown cost about 1% in sales. Also, if one page load needs several backend calls, it only takes one slow call to make the whole page slow (**tail latency amplification**).

**SLO and SLA:** services often promise targets in percentile terms, e.g. "median under 200 ms and p99 under 1 s".

#### 3. Approaches for coping with load
- **Scaling up (vertical):** move to a more powerful machine. Simple, but gets very expensive.
- **Scaling out (horizontal):** spread load across many smaller machines (a *shared-nothing* architecture).
- **Elastic systems** add resources automatically when load rises. Good for unpredictable load. Manually scaled systems are simpler and have fewer surprises.
- **Stateless services** are easy to spread across machines. **Stateful data systems** are harder to distribute, which is why Part II exists. A common early move is to keep the database on one machine until cost or availability forces you to distribute it.
- **There is no magic scaling sauce.** An architecture that suits one load (say, many small reads) can fail for another (say, few huge writes). Design around your assumptions about which operations are common and which are rare.

**Interview one-liner:** "Scalability is about describing your load and performance with real numbers, then choosing how to add capacity without a redesign."

### Maintainability: "People can keep working on it for years"
Most of a system's cost is not building it, it is **maintaining** it: fixing bugs, keeping it running, adapting it to new use cases, and paying off technical debt. Nobody enjoys working on legacy systems, so design software to avoid becoming one. Three principles:

| Principle | Plain English | What it looks like in practice |
|---|---|---|
| **Operability** | Make life easy for the operations team. | Good monitoring and visibility into runtime behavior. Support for automation and standard tools. Good documentation ("if I do X, what happens?"). Predictable behavior with sensible defaults, and the freedom to override them. Avoiding dependence on a single machine so it can be taken down for maintenance. |
| **Simplicity** | Make it easy for new engineers to understand. | Remove **accidental complexity** (complexity that comes from the implementation, not the problem). The best tool is **abstraction**: hide the messy details behind a clean interface (high-level languages hide machine code, SQL hides on-disk data structures). |
| **Evolvability** | Make it easy to change later. | Requirements always change: new use cases, new platforms, new legal rules. Simple systems and good abstractions are easier to modify. Agile practices such as automated tests and refactoring help. Also called *extensibility* or *plasticity*. |

**Interview one-liner:** "Maintainability is making the system easy to run, easy to understand, and easy to change, because that is where most of the cost lives."
