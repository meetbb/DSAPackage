# LinkedList

Notes on singly and doubly linked lists — core operations, complexity, and why this
data structure earns its place in real iOS systems rather than staying a pure
interview exercise.

## Why a LinkedList at all

Swift's `Array` is contiguous memory with value semantics — it's what you reach for
almost every time. A `Node` here is a `class` (reference type), so ARC handles
deallocation automatically; there's no manual `malloc`/`free` the way a C
implementation would need. That's the first mental shift coming from a
C/Java-oriented textbook into Swift.

## Core operations and complexity

| Operation | Singly linked | Doubly linked | Notes |
|---|---|---|---|
| Insert at head | O(1) | O(1) | Same for both |
| Insert at tail | O(1)* | O(1) | *Only O(1) if you maintain a `tail` pointer |
| Delete at head | O(1) | O(1) | Same for both |
| Delete at tail | O(n) | O(1) | Singly can't walk backward from `tail` |
| Delete by value | O(n) | O(n) | Both must search first |
| Delete a node you already hold a reference to (not tail) | O(1) via value-copy trick | O(1) | See below |
| Traverse | O(n) | O(n) | Same for both |
| Memory per node | 1 pointer | 2 pointers | Doubly costs more at scale |

**The delete-by-reference trick:** if you already hold a reference to the node to
delete (and it isn't the tail), copy the next node's value into it, then delete the
next node instead. O(1), no `prev` pointer required. This is a large part of why
singly linked lists remain useful even with an O(n) general delete.

## Files in this folder

- `BasicOperations.swift` — `Node`, `LinkedList`: `insertAtHead`, `insertAtTail`,
  `insert(at:)`, `delete(_:)`, `deleteAt(_:)`, `deleteLast()`, `deleteAll()`,
  `traverse()`, `contains(_:)`.

## `deleteAll()` — a Swift-specific gotcha

`head = nil` alone technically works: dropping the only reference to the first node
lets ARC deallocate it, which deallocates its `next`, and so on down the chain. The
problem is that chain of deinits is **recursive** — one stack frame per node. For a
long list (tens of thousands of nodes), this can overflow the stack and crash. The
fix is to unlink nodes iteratively from the front, so each one deallocates
immediately instead of building a deinit call chain:

```swift
func deleteAll() {
    var current = head
    while let node = current {
        let next = node.next
        node.next = nil
        current = next
    }
    head = nil
    tail = nil
    count = 0
}
```

## Where LinkedLists show up in real iOS work

- **`UIResponder.next`** — the responder chain is a literal singly linked list.
  Event/action dispatch walks it node by node looking for a handler. Forward-only
  access, so singly is the correct choice — no `prev` is ever needed.
- **LRU caching** — the mechanism behind image/network caches (the pattern behind
  `NSCache`-style eviction, and what libraries like SDWebImage/Kingfisher implement
  internally). A doubly linked list + dictionary gives O(1) lookup, O(1)
  move-to-front, and O(1) evict-oldest — no other combination hits all three. See
  `LC0146_LRUCache.swift`.
- **Hash table collision chains** — separate-chaining hash tables resolve
  collisions with a singly linked list per bucket. You only ever traverse a bucket
  forward, so paying for `prev` on every entry would be pure waste.

## Singly vs doubly: when each wins

Doubly linked lists don't strictly dominate — they trade memory and bookkeeping
(every insert/delete now touches *two* pointers instead of one) for O(1) backward
traversal and O(1) tail deletion.

**Reach for singly when:**
- Access is forward-only (stacks, parser token streams, hash bucket chains,
  `UIResponder` chains).
- Memory matters at scale (millions of nodes — hash chains, adjacency lists).
- You want structural sharing: two lists can safely share a common tail, since
  nothing points backward into the shared segment. (This is why Lisp-style lists
  and Swift's `indirect enum` list patterns are singly linked — it's what makes
  copy-free sharing possible. A doubly linked list can't share a tail this way,
  since the shared tail's `prev` couldn't point to two different predecessors at
  once.)

**Reach for doubly when:**
- You need O(1) removal of an arbitrary, already-known node from the middle
  (LRU cache eviction).
- You need O(1) backward traversal or O(1) tail operations without re-walking
  from head.

The honest rule of thumb: singly linked is the leaner, correct-by-default choice.
Doubly linked is what you reach for specifically when the access pattern demands
going backward — not the general-purpose upgrade it might first appear to be.
