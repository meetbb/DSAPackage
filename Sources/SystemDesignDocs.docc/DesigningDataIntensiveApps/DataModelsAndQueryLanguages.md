# Data Models and Query Languages

Chapter 2 of Part I: how we *shape* data, and how we *ask* for it.

## Overview
A **data model** is the way you describe your data to the system (tables? documents? a graph?). A **query language** is how you ask questions about it. This choice matters more than almost any other, because it affects how the software is written *and* how we think about the problem.

Applications are built in layers, and each layer hides the one below it as a clean model (this is the **abstraction** idea from Chapter 1's Simplicity):
1. The real world: people, orders, actions.
2. Your app models it as objects and data structures, plus APIs to change them.
3. Those are stored as JSON, XML, tables, or graphs in a database.
4. The database represents that as bytes in memory, on disk, or on a network.
5. Hardware represents the bytes as electrical currents, magnetic fields, and so on.

This chapter lives at layers 2 and 3. Chapter 3 (Storage and Retrieval) goes down to layer 4.

**Interview one-liner:** "A data model decides what is easy and what is hard to express, so pick the one whose shape matches how your data is actually connected."

## Concept Tree

```text
DATA MODELS AND QUERY LANGUAGES
│
├── 1. Relational model vs Document model
│   ├── Relational: tables of rows, SQL, joins          (the long-time default)
│   ├── Document: self-contained JSON-like records       (MongoDB, CouchDB)
│   ├── Why NoSQL appeared: scale, open source, specialized queries, less rigid schemas
│   ├── Object-relational mismatch → the ORM "translation layer"
│   ├── One-to-many: a résumé fits naturally in one document (locality)
│   ├── Many-to-one / many-to-many: need references and joins → relational is stronger
│   ├── Schema-on-read (document) vs schema-on-write (relational)
│   └── Convergence: each model is borrowing from the other
│
├── 2. Query languages
│   ├── Declarative (SQL: say WHAT you want)
│   ├── Imperative (loops: say HOW to get it)
│   └── MapReduce: in between, a mix of both
│
└── 3. Graph-like data models
    ├── Property graph: vertices + edges (Neo4j), query with Cypher
    ├── Triple-store: (subject, predicate, object), query with SPARQL
    └── Datalog: older, rule-based, the foundation for the others
```

## 1. Relational Model vs Document Model

### The relational model
Data is organized into **relations** (tables), each a collection of **tuples** (rows). Proposed by Edgar Codd in 1970. It won because it hid implementation details behind a clean interface (SQL) and was general enough for business data processing: transactions, batch reports, and so on.

### Why NoSQL appeared
"NoSQL" is a catchy label, not a technology. The book's reasons for its rise:
- Need for greater **scalability** than relational databases handled easily, including very large datasets or very high write rates.
- A preference for **free and open source** software.
- Need for **specialized queries** the relational model does not do well.
- Frustration with **rigid schemas** and a wish for a more dynamic, expressive model.

The book's prediction (an interpretation of a trend, not a rule): relational and non-relational stores will be used **side by side**. This is called **polyglot persistence**.

### The object-relational mismatch
Most app code is object-oriented, but data lives in tables. Translating between the two needs an awkward layer. This disconnect is called **impedance mismatch** (borrowed from electronics). **ORMs** (Hibernate, ActiveRecord) reduce the boilerplate but cannot hide the difference fully.

### One-to-many: why documents feel natural
Take a LinkedIn-style résumé. One person has many jobs, many schools, many contact details.
- **Relational:** split into `users`, `positions`, `education`, `contact_info` tables linked by a `user_id`. Reading one résumé means several queries or a multi-way join.
- **Document:** store the whole résumé as one JSON document. The tree structure of one-to-many is visible directly, and it is all in one place (**locality**), so one read fetches everything.

### Many-to-one and many-to-many: where documents get weaker
Suppose the résumé stores `region_id` and `industry_id` rather than the text "Greater Seattle Area".
- **Why use an ID?** One place to update, consistent spelling, no ambiguity, and easy localization. The ID is meaningless to humans so it never needs to change, while the text it points to can. Copying the text everywhere is **duplication**, which must be updated in every copy (this is **normalization** vs **denormalization**).
- **The catch:** normalized data requires **joins**. Document databases historically supported joins weakly, so the app has to do them in code. As an app grows, data tends to become more interconnected (people referencing organizations, schools, other people), pushing toward many-to-many relationships.

| | Relational | Document |
|---|---|---|
| Strength | Joins, many-to-one, many-to-many | Locality, flexible shape, matches app objects |
| Weakness | Mismatch with objects, rigid schema | Weak joins, awkward for many-to-many |
| Best when | Data is highly interconnected | Data is tree-like, loaded as a whole |

### Schema flexibility: schema-on-read vs schema-on-write
- **Schema-on-write** (relational): the database enforces structure when you *write*. Like static type checking.
- **Schema-on-read** (document): structure is implicit and only interpreted when you *read*. Like dynamic type checking.

Example: you want to split a `name` field into `first_name` and `last_name`.
- Document: start writing new documents with the new fields, and have app code handle old documents that lack them.
- Relational: run a migration (`ALTER TABLE ...`, then update rows). Usually fine, though on a huge table it can be slow.

Document stores suit data where items do not all have the same structure (many different types, or structure set by an outside system you do not control). If every record *is* the same shape, a schema is useful documentation and protection.

### Data locality for queries
A document is usually stored as one continuous chunk, so reading the whole thing is fast. But if you need only a small part, the database may still load the entire document, and updates often rewrite all of it. So keep documents **fairly small** and avoid writes that grow them.

### Convergence
- Most relational databases now support JSON/XML columns.
- Some document databases (RethinkDB) support relational-style joins.

Each model is borrowing from the other, which is a good sign.

## 2. Query Languages for Data

### Declarative vs imperative
| | Imperative | Declarative |
|---|---|---|
| You say | **How**: step-by-step instructions | **What**: the pattern of the result you want |
| Example | A loop over all animals that appends sharks to a list | `SELECT * FROM animals WHERE family = 'Sharks'` |
| Who decides how? | You | The **query optimizer** |

Why declarative usually wins:
- It is shorter and easier to work with.
- It hides the database engine's internals, so the engine can **improve** (new indexes, better storage) without you changing queries.
- It lends itself to **parallel execution**, since it says nothing about order. Imperative code, tied to a specific order, is hard to parallelize.

Not just SQL: on the web, **CSS selectors** are declarative ("style every `li.selected > p`") while doing the same with JavaScript DOM loops is imperative and clumsier.

### MapReduce querying
**MapReduce** (popularized by Google) is a model for processing large data across many machines. It sits between the two styles: the overall query is declared, but the two pieces of logic are code snippets you write.
- **map** runs once per document and emits key-value pairs.
- **reduce** combines all values that share a key.

Constraints: both functions must be **pure** (use only their input, no extra queries, no side effects), so the database can run them anywhere, in any order, and re-run them after a crash. Downsides: you must write two coordinated functions, which is harder than one SQL query. Because of this, some MapReduce databases (MongoDB) added a declarative **aggregation pipeline** that looks like a subset of SQL in JSON form.

## 3. Graph-Like Data Models
When many-to-many relationships are *everywhere*, it is more natural to model data as a **graph**.
- **Vertices** (nodes) are things. **Edges** (relationships) connect them.
- Examples: social graphs (people, friendships), the web graph (pages, links), road or rail networks.
- Famous algorithms run on graphs: shortest path (navigation apps), PageRank (web search).
- Graphs are not limited to one kind of thing. Facebook keeps people, locations, events, check-ins, and comments in one graph.

### Property graphs (Neo4j, Titan, InfiniteGraph)
- Each **vertex** has: an ID, sets of incoming and outgoing edges, and key-value **properties**.
- Each **edge** has: an ID, its tail vertex, its head vertex, a **label** describing the relationship, and key-value properties.
- Any vertex can connect to any other. No schema says which kinds of things may link.
- You can traverse in either direction from a vertex, so one graph can hold many different relationship types.
- Great for **evolvability**: add new kinds of links as the app changes.

Querying with **Cypher** (Neo4j's declarative language). For example, "find people who emigrated from the US to Europe" is a pattern: `(person) -[:BORN_IN]-> () -[:WITHIN*0..]-> (us:Location {name:'United States'})` and a similar `LIVES_IN` pattern for Europe. The `*0..` means "follow this edge zero or more times", which a plain SQL join cannot express easily (it needs **recursive common table expressions**, and gets very long).

Key point: in SQL you must know in advance which joins you need. In a graph, a traversal of *variable length* is a one-liner.

### Triple-stores and SPARQL
Same underlying idea, different vocabulary. All information is stored as three-part statements: **(subject, predicate, object)**, e.g. `(Lucy, bornIn, Idaho)`.
- The object is either a primitive value (making the predicate a property) or another vertex (making the predicate an edge).
- **RDF** is the data format, and **SPARQL** is the query language. They came from the **Semantic Web** idea (websites publishing machine-readable data), which has seen limited uptake but its tooling is useful.

### Datalog
An older language (1980s) that underlies later ones (e.g. Datomic, Cascalog). Data is `predicate(subject, object)`. You define **rules** that build new predicates from old ones, and rules can call themselves recursively. Less friendly to read, but very powerful for complex queries built up in small reusable steps.

### Graph databases vs the network model (a common confusion)
The 1970s **CODASYL (network) model** also connected records to each other, but differs from graphs: it had a fixed schema about which records could nest in which, you reached a record by following access paths (like pointers), and querying was imperative and hard to change. Graph databases let any vertex link to any other, use IDs and indexes to find things, and offer declarative languages.

## Big Picture: Choosing a Model
| Your data looks like... | Lean toward |
|---|---|
| Self-contained, tree-shaped records loaded together (profiles, résumés, CMS pages) | Document |
| Structured, many-to-one and many-to-many links, strong joins and reports | Relational |
| Highly connected, variable-depth relationships (social, fraud rings, routes) | Graph |

No model is best for everything. As the book frames it, each model is a trade-off between what is **easy to express** and what is **hard to express**.

### Connections to other chapters
- Chapter 1 *Maintainability*: abstraction (SQL hides storage) and evolvability (schema flexibility).
- Chapter 3 *Storage and Retrieval*: how these models are laid out on disk.
- Chapter 4 *Encoding and Evolution*: how schema changes work across versions of data (schema-on-read depends on this).
- Part II *Partitioning*: how document locality interacts with spreading data over machines.

## Self-Check Questions
Try to answer from memory before re-reading:
1. What is the object-relational mismatch, and how does a document model reduce it?
2. Why store `region_id` instead of the region's name, and what does that cost you?
3. Schema-on-read vs schema-on-write: what changes when you split `name` into two fields?
4. Why does a declarative language let the database improve without breaking your queries?
5. Why can SQL struggle with "follow this edge any number of times", and how does Cypher do it?
6. What is the difference between a property graph and a triple-store?

> Note: this file was written from the standard content of Chapter 2 and has not yet been compared with your own daily notes. The specifics here (e.g. exact examples) are an overview. Add your own observations and open questions below.

## My Notes and Open Questions
-

---
Back to the main chapter list: <doc:Part1-FoundationsOfDataSystems>
