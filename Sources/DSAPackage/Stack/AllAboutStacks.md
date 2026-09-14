#  All About Stacks

### 1. Overall purpose of Stacks
A **Stack** is a linear data structure that follows **LIFO**(Last In, First Out) – the last element added is the first one removed. Think of a stack of plates: you add to the top and remove from the top.

**Why it matters conceptually:**
- It models any process where you need to "remember where you came from" and unwind in reverse order
- It's the natural fit for problems involving **nesting, backtracking, or reversal** – matching parantheses, undo operations, DFS traversal, expression evaluation
- Every function call in every programming language uses a stack internally (the call stack) – this is why deep recursion causes stack overflow

**Core guarantee:** O(1) push, O(1) pop, O(1) peek – as long as you use the right underlying structure (array-based, not linked-list-with-traversal).

### 2. Real-time applications in iOS Development
This is where it gets relevant in iOS:
- UINavigationController :– Literally implemented as a stack – `pushViewController`/`popViewController`. Your entire navigation flow is LIFO.
- Undo/Redo functionality :– Two stacks: one for undo history, one for redo. Common in note apps, drawing apps, text editors.
- Browser-style back navigation :– `WKWebView`'s back/forward list, or custom in-app navigation history you track manually.
- JSON/XML parsing :– Validating nested brackets/tags, or building a parser that tracks nesting depth.
- Expression evaluation :– Calculator apps – converting infix to postfix, evaluating expressions with parantheses.
- Function call stack debugging :– Understanding crash logs/stack traces – every frame is a stack push.
- Recursive DFS in view hierarchies :– Walking a UIView subview tree, or a Core Data relationship graph, depth-first.
- Syntax highlighting in code editors :– Tracking nested braces `{ }`, brackets `[ ]` to detect mismatches (relevant if you ever build dev tooling).

