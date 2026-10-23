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

##### Response time vs latency (two words that are easy to mix up)
The book separates them (this is a precise-usage point; in casual conversation people use "latency" loosely for both):
- **Response time** is what the *client sees*: the full wait from sending the request to getting the answer. It includes the actual processing time (**service time**), network delays, and queueing delays.
- **Latency** is only the time a request is *waiting to be handled* (the "latent", idle part), before any work starts on it.

So latency is **one slice inside** response time, not the whole journey. In a sentence: *response time = waiting + processing + network travel*, and "latency" names the waiting part.

Also, even identical requests take different times. Causes include a context switch to a background process, a lost network packet that TCP has to resend, a garbage-collection pause, a page fault that reads from disk, or even vibration in the rack. So response time is a spread of values, never a single number.

##### Why the average is a poor measure, and how p50, p95, p99 and p999 connect
- The **mean (average)** of response times hides the spread. A few extremely slow requests drag it up, and it does not tell you how many users actually felt that slowness. (The problem is averaging *response times*, not "the average number of requests".)
- The **median (p50)** is better because it tells you what a *typical* user experiences. If p50 = 200 ms, half of requests finish in under 200 ms. But p50 alone says nothing about the slow half.
- p95, p99 and p999 are the same idea as p50, just **zooming into the slow end**. Imagine 1,000 requests sorted from fastest to slowest:

| Percentile | Which request in the sorted list | Meaning |
|---|---|---|
| p50 | the 500th | half are faster |
| p95 | the 950th | only the slowest 50 (5%) are worse than this |
| p99 | the 990th | only the slowest 10 (1%) are worse |
| p999 | the 999th | only the single slowest request (0.1%) is worse |

Each step up shows a rarer, worse experience. Use p50 for "typical", and p95/p99/p999 for "how bad does it get for unlucky users". Higher percentiles cost more to improve and have more random noise, so teams usually pick one or two (commonly p99) as their targets.

##### SLO vs SLA, with an example
Both are promises about service quality, usually written in percentiles. The difference is who they are made to and what happens if they are broken.
- **SLO (Service Level Objective)**: an *internal goal*. "Our API's p99 response time should stay under 1 s." If it slips, the team investigates. Nobody is paid back.
- **SLA (Service Level Agreement)**: a *contract with customers* that has consequences. "If monthly uptime falls below 99.9%, or p99 stays above 1 s, we refund 10% of your bill."

Easy way to remember: **SLO = what we aim for. SLA = what we have promised to pay for if we miss.** Teams normally set the SLO stricter than the SLA so they get a warning before they break the contract.

##### Head-of-line blocking
A server can only work on a small number of requests at the same time. Requests that arrive wait in a queue. **Head-of-line blocking** happens when a few slow requests at the front of the queue hold up the fast requests *behind* them, even though those fast ones would finish instantly if they were served on their own.

Analogy: one supermarket checkout lane. The person at the front has a huge cart with a price problem. The three people behind them with one item each all wait, though each needs only 10 seconds. (Limit of the analogy: servers can often run several requests in parallel, but it still happens whenever every slot is occupied by slow ones.)

Why it matters for measuring:
- A small number of slow requests make many *other* requests slow, so the slowness shows up at the client's response time even though the server's own processing time for those requests was small.
- This is why response time must be **measured on the client side**.
- When load-testing, the test client must send requests **independently of how fast the earlier ones finish**. If it waits for each response before sending the next, it keeps the queue artificially short and makes the system look better than it is.

##### Tail latency amplification (worked example)
One user action (opening a page) often needs many backend calls. Even if they run in parallel, the page waits for the **slowest** one. Suppose each backend call is slow only 1% of the time (it is "fast" 99% of the time). With 100 calls per page:

chance that *at least one* call is slow = 1 − 0.99¹⁰⁰ ≈ **63%**

So a rare 1% problem per call turns into a slow page for roughly 2 out of 3 users. That is why high percentiles matter most in services that are called many times per user request.

##### Calculating percentiles for a monitoring dashboard (plain-language version of the book's two paragraphs)
**The goal:** a dashboard that shows, say, the median and p99 response time over the *last 10 minutes*, refreshed every minute. The window "rolls" forward: each minute the oldest minute drops out and the newest minute comes in.

**The naive way:** keep every response time from the last 10 minutes in a list. Every minute, sort the list and read off the values at the 50%, 95% and 99% positions (as in the table above). It is simple and exact, but at thousands of requests per second the list gets huge, and sorting it again and again wastes CPU and memory.

**The smarter way:** use algorithms that keep a *compact summary* of the data instead of every value, and give an answer that is very close to the true percentile. The book names **forward decay**, **t-digest** and **HdrHistogram**. You do not need their internals for now, only the idea: *trade a tiny bit of accuracy for far less CPU and memory*.

**Warning about combining data:** never *average percentiles*. For example, to merge two servers:
- Server A handled 10,000 requests with p99 = 100 ms.
- Server B handled 10 requests with p99 = 2,000 ms.
- Averaging gives 1,050 ms, a number that describes neither server nor the combined traffic. Server A's 10,000 requests are nearly all that matters, but the average treats both equally.

The correct way is to keep a **histogram**: buckets of response times (0-10 ms, 10-20 ms, ...) with a count of requests in each bucket. Histograms from different servers or minutes can be **added bucket by bucket**, and the percentile is then read from the combined histogram. The same applies when you want a coarser time resolution (e.g. combining 10 one-minute results into 10 minutes).

##### Open questions from the notes: quick status
| Question | Answer |
|---|---|
| Is latency the overall time and response time what the client waited? | Partly wrong: response time is the overall time the client waits. Latency is the waiting-to-be-handled part inside it. |
| How do p95, p99, p999 connect to p50? | Same idea, zoomed further into the slow end of the sorted list. |
| SLO vs SLA? | SLO = internal target. SLA = contract with consequences. |
| Head-of-line blocking? | Slow requests at the front of a queue delay the fast ones behind them. |
| Percentile calculation paragraphs? | Rolling window, sort-everything is simple but costly, approximate summaries are cheaper, and combine histograms, never average percentiles. |

#### 3. Approaches for coping with load
The guiding question: *when our load parameters grow, how do we keep performance good?*
- **Scaling up (vertical):** move to a more powerful machine. Simple, but gets very expensive.
- **Scaling out (horizontal):** spread load across many smaller machines (a *shared-nothing* architecture).
- **In practice it is a mix, not an either/or choice.** A few fairly powerful machines can be simpler and cheaper than a large fleet of tiny virtual machines.
- **Elastic systems** add resources automatically when load rises. Good for unpredictable load. Manually scaled systems are simpler and have fewer surprises.
- The book's view is that, as tools for distributed systems improve, distributed setups may become the default even for modest loads. That is a prediction, not today's rule.
- **Stateless services** are easy to spread across machines. **Stateful data systems** are harder to distribute, which is why Part II exists. A common early move is to keep the database on one machine until cost or availability forces you to distribute it.
- **There is no magic scaling sauce.** An architecture that suits one load (say, many small reads) can fail for another (say, few huge writes). Design around your assumptions about which operations are common and which are rare. Those assumptions are exactly your **load parameters**, which links this section back to "Describing load".

**Interview one-liner:** "Scalability is about describing your load and performance with real numbers, then choosing how to add capacity without a redesign."

### Maintainability: "People can keep working on it for years"
Most of a system's cost is not building it, it is **maintaining** it: fixing bugs, keeping it running, adapting it to new use cases, and paying off technical debt. Nobody enjoys working on legacy systems, so design software to avoid becoming one. Three principles:

| Principle | Plain English | What it looks like in practice |
|---|---|---|
| **Operability** | Make life easy for the operations team. | Good monitoring and visibility into runtime behavior. Support for automation and standard tools. Good documentation ("if I do X, what happens?"). Predictable behavior with sensible defaults, and the freedom to override them. Avoiding dependence on a single machine so it can be taken down for maintenance. |
| **Simplicity** | Make it easy for new engineers to understand. | Remove **accidental complexity** (complexity that comes from the implementation, not the problem). The best tool is **abstraction**: hide the messy details behind a clean interface (high-level languages hide machine code, SQL hides on-disk data structures). |
| **Evolvability** | Make it easy to change later. | Requirements always change: new use cases, new platforms, new legal rules. Simple systems and good abstractions are easier to modify. Agile practices such as automated tests and refactoring help. Also called *extensibility* or *plasticity*. |

**Interview one-liner:** "Maintainability is making the system easy to run, easy to understand, and easy to change, because that is where most of the cost lives."
