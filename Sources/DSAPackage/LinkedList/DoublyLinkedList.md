# Doubly Linked List

Notes on doubly linked lists — what the extra `prev` pointer buys you, the
operations it makes O(1) that singly linked can't, and where this specific
structure shows up in real systems. Companion to `README.md` (singly linked)
in this same folder.

## What changes vs. singly linked

Every `DNode` carries a `prev` pointer alongside `next`. That one addition is
the entire reason this structure exists — it converts several O(n) operations
from the singly linked list into O(1):

| Operation | Singly linked | Doubly linked | Why |
|---|---|---|---|
| Insert at head | O(1) | O(1) | No change |
| Insert at tail | O(1)* | O(1) | *Singly needs a maintained `tail` pointer too |
| Delete first | O(1) | O(1) | No change |
| Delete last | **O(n)** | **O(1)** | `tail.prev` already IS the new tail — no walk from `head` needed |
| Delete an intermediate node you already hold | O(1) via value-copy trick | O(1) directly | Doubly doesn't need the trick — `node.prev` is already known |
| Traverse forward | O(n) | O(n) | Same |
| Traverse backward | **not possible** | O(n) | The capability singly structurally lacks |
| Memory per node | 1 pointer | 2 pointers | Doubly costs more at scale |

The cost: **every insert and delete now touches two pointers instead of
one** — `node.prev` and `node.next` on both sides of the splice. Miss updating
one side and you get a silently broken or one-directional link, which is a
more common bug source here than in the singly linked version.

## Functions in `DoublyLinkedList.swift`

- `insertAtHead(_:)` — O(1)
- `insertAtTail(_:)` — O(1)
- `insert(_:at:)` — O(n) to reach the position, O(1) splice once there
- `deleteFirst()` — O(1)
- `deleteLast()` — O(1) (the operation this whole structure exists to make cheap)
- `deleteAt(_:)` — intermediate node by position, O(n) to find, O(1) to unlink
- `delete(_:)` — intermediate node by value, O(n) to find, O(1) to unlink
- `traverse()` — forward, O(n)
- `traverseBackward()` — backward, O(n) — impossible on a singly linked list

All delete paths fully detach the removed node (`prev = nil`, `next = nil`)
before returning, so no stale pointer keeps referencing back into the live
list after removal.

## Why the extra pointer is worth it here

This is the structure behind the **LRU Cache** covered earlier
(`LC0146_LRUCache.swift`): a cache needs three things simultaneously —
O(1) lookup, O(1) move-to-front on access, and O(1) evict-the-oldest. The
dictionary gives lookup; the doubly linked list gives the other two. Evicting
the oldest is a `deleteLast()`, and it has to be O(1) or the cache defeats its
own purpose under load. A singly linked list cannot do this without an O(n)
walk to find the node before `tail` — which is exactly why the LRU Cache
specifically requires doubly, not singly.

**Other places doubly linked lists show up in real systems:**
- **Undo/redo history** — moving backward *and* forward through a sequence of
  states is the textbook doubly linked use case; a purely forward structure
  can't support "redo" cheaply.
- **Browser back/forward navigation** — same shape: you need to move in both
  directions through visited history without re-deriving it.
- **Music/video "previous track" controls** — skipping backward through a
  playback queue needs `prev`, not just `next`.
- **A deque (double-ended queue)** — O(1) push/pop at both ends is exactly
  what a doubly linked list (or a doubly linked list under the hood) provides.

## The honest takeaway

Doubly linked isn't a strict upgrade over singly linked — it's a deliberate
trade of memory and bookkeeping (two pointers per node, twice the splice
surface for bugs) for O(1) backward traversal and O(1) tail deletion. Reach
for it specifically when the access pattern requires going backward or
requires cheap removal from an arbitrary known position (LRU eviction,
undo/redo, back/forward navigation) — not as a default replacement for the
singly linked list.
