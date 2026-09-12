# Memory-Efficient (XOR) Doubly Linked List
**Conventional DLL**: each node stores two pointers – `prev` and `next`. For a node of size N, you pay for 2 pointers per node (16 bytes on a 64-bit system, just for links).

**XOR Linked List**: each node stores one field, usually called `npx`(node pointer XOR), which holds the XOR of the addresses of the previous and next node:
	`npx = addr(prev) XOR addr(next)`
You cut pointer storage in half – one field instead of two.

### Why this works
XOR has a self-inverse property: `A XOR B XOR B = A`. So if you're traversing and you know the address of the node you came from (prev), you can recover the next node's address:
	`next = npx(current) XOR addr(prev)`
Then you move forward: the node you just came from becomes the new "prev," and you repeat.
- For the head node, `prev` is treated as address 0(NULL), so `npx(head) = 0 XOR addr(next) = addr(next)`.
- For the tail, `next` is NULL, so `npx(tail) = addr(prev) XOR 0 = addr(prev)`.

To traverse forward, you need to seed the process with the address of the head's "previous" (0) and the head itself – then each step computes the next address using XOR against the previous one. Same logic works walking backward.

#### The catch
This is a classic interview/theory concept, but it's rarely useable in real code:
1. **No garbage collection language can do this**. It requires raw pointer arithmetic and XOR on address – you need direct access to memory addresses as integers (C/C++ style), which isn't available in managed-memory languages.
2. **Breaks with moving/compacting memory**. Any runtime that moves objects (GC compaction, ARC doesn't move memory but many managed runtimes do) would invalidate the stored XOR value.
3. **No random access, hard to debug,** and modern compilers/CPUs make the "savings" from 2 pointers -> 1 pointer questionable next to cache-locality costs.
4. Not thread-safe or easily inspectable – a debugger can't just show you "the next pointer."

So it's mostly asked in interviews as a "how would you save memory in a pointer-based structure" trick question, not something you'd deploy.

**Bottom line**: In Swift, the realistic "memory-efficient"