# Storage and Retrieval

Chapter 3 of Part I: how a database lays data out on disk so it can store it and find it again quickly.

## Overview
At the most basic level a database does two things: when you give it data, it **stores** it, and when you ask again later, it **gives it back**. Chapter 2 was about *what shape* your data has (tables, documents, graphs). This chapter goes one layer down: *what actually happens to the bytes*.

Why should an application developer care? You will not write a storage engine, but you *will* choose one. A database tuned for a shopping-cart app and one tuned for a sales-report dashboard are built very differently. Knowing the internals tells you which to pick and how to tune it.

The chapter has **two halves**:
1. **OLTP storage engines** (everyday app traffic): how to store and look up individual records fast. Two families compete: *log-structured* (LSM-trees) and *page-oriented* (B-trees).
2. **Analytics (OLAP) storage**: how to scan billions of rows to answer big questions. The answer is to store data by *column* instead of by row.

The one idea behind almost everything here: **an index trades write speed for read speed**. Without an index, finding data means reading everything. With one, reads are fast, but every write must also update the index.

**Interview one-liner:** "Log-structured engines and B-trees optimise for different things. LSM-trees favour fast writes and B-trees favour predictable reads. Analytics databases go column-oriented so a query only reads the columns it needs."

## Concept Tree

```text
STORAGE AND RETRIEVAL (problem: store data durably, then find it fast)
│
├── 1. DATA STRUCTURES THAT POWER YOUR DATABASE (OLTP: many small reads and writes)
│   │
│   ├── Starting point: an append-only log file + scanning it = fast writes, slow reads
│   │   └── Fix = an INDEX (extra structure that speeds reads but slows writes)
│   │
│   ├── Hash Indexes ─ an in-memory map from key → byte position in the log file
│   │   └── Limits: all keys must fit in RAM, no range queries
│   │
│   ├── SSTables and LSM-Trees ─ log-structured: only ever append, never edit in place
│   │   ├── Constructing and maintaining SSTables ─ sorted segment files, built from an in-memory buffer
│   │   ├── Making an LSM-tree out of SSTables ─ buffer + sorted files merged in the background
│   │   └── Performance optimizations ─ Bloom filters, compaction strategies
│   │
│   ├── B-Trees ─ page-oriented: a sorted tree of fixed-size blocks, edited in place
│   │   ├── Making B-trees reliable ─ write-ahead log (WAL) so a crash cannot corrupt the tree
│   │   └── B-tree optimisations ─ copy-on-write, abbreviated keys, sibling pointers
│   │
│   ├── Comparing B-Trees and LSM-Trees ─ trade-offs, not a winner
│   │   ├── Advantages of LSM-trees ─ faster writes, smaller files, less fragmentation
│   │   └── Downsides of LSM-trees ─ compaction interference, uneven latency, duplicate keys
│   │
│   └── Other Indexing Structures
│       ├── Storing values within the index ─ clustered and covering indexes
│       ├── Multi-column indexes ─ concatenated keys and multi-dimensional (spatial) indexes
│       ├── Full-text search and fuzzy indexes ─ search that tolerates typos and word variants
│       └── Keeping everything in memory ─ in-memory databases (Redis, VoltDB)
│
├── 2. TRANSACTION PROCESSING OR ANALYTICS? (two different jobs for a database)
│   │
│   ├── OLTP (online transaction processing) vs OLAP (online analytic processing)
│   │
│   ├── Data Warehousing ─ a separate read-only copy of the data for analysts
│   │   └── The divergence between OLTP databases and data warehouses ─ same SQL, very different insides
│   │
│   └── Stars and Snowflakes: Schemas for Analytics ─ one big "fact" table surrounded by "dimension" tables
│
├── 3. COLUMN-ORIENTED STORAGE (OLAP: few, huge scans over many rows)
│   │
│   ├── Core idea ─ store each column together, not each row together
│   │
│   ├── Column Compression ─ repeated values in a column squash down very small
│   │   └── Memory bandwidth and vectorized processing ─ feed the CPU whole chunks at once
│   │
│   ├── Sort Order in Column Storage ─ sort rows by a chosen column to speed up and compress more
│   │   └── Several different sort orders ─ keep copies sorted differently for different queries
│   │
│   ├── Writing to Column-Oriented Storage ─ writes are harder, so buffer in memory then merge (LSM again)
│   │
│   └── Aggregation: Data Cubes and Materialised Views ─ pre-computed answers for common totals
│
└── SUMMARY ─ OLTP engines (LSM vs B-tree) for apps, column stores for analytics
```

## 1. Data Structures That Power Your Database

### The starting point: a log and the idea of an index
**Big picture.** The simplest possible database is a text file. To *write*, you append a line to the end. To *read*, you scan the file from the start and take the last line matching your key. Appending is about as fast as writing can ever be. Scanning gets slower the more data you have (it is O(n)).

**For a beginner.** Think of a diary. Adding a new entry is trivial: write at the bottom. Finding what you wrote about "dentist" means flipping through every page. The fix is an **index**: like the index at the back of a textbook, it is *extra* information that tells you where to look. The price is that every time you add a page, you must also update the index. That is the central trade-off of the chapter: **well-chosen indexes speed up reads but slow down writes**. Databases do not index everything by default, so you choose indexes based on your queries.

*Term:* a **log** here just means an append-only sequence of records. It is not the same as an application log used for debugging.

### Hash Indexes
**Big picture.** The simplest index for a log file. It exists to turn "scan everything" into "jump straight there". Bitcask (the storage engine in Riak) works this way.

**For a beginner.** Keep a Python dictionary (hash map) in memory. Each key maps to the *byte offset* where its latest value sits in the file. To read, look up the offset and jump to it. To write, append to the file and update the offset in the dictionary.

*Example:* a video-streaming site counts plays per video. The key is the video URL and the value is the play count, which changes constantly. There are lots of writes but not many distinct keys, so all the keys fit in RAM. A hash index is a perfect match.

*How does the file avoid growing forever?* Split the log into **segments**. When one reaches a size limit, close it and start a new one. **Compaction** then throws away duplicate keys within segments, keeping only the newest value, and segments can be merged. Other practical details: deleting a key means appending a special marker called a **tombstone**. After a crash, the in-memory map can be rebuilt by re-reading the segments, or loaded faster from a snapshot. Checksums catch half-written records. Writes happen in one sequence, which is quick.

*Why append instead of overwrite?* Sequential writes are much faster than random ones on disks (and on SSDs). Crash recovery is simpler (an old value is never half overwritten). Merging old segments avoids fragmentation.

*Limitations:*
- The hash table must fit in memory. Keeping it on disk is slow and awkward.
- **No range queries.** You cannot ask for "all keys between kitty00000 and kitty99999". You would have to look up each key.

#### Hash Indexes in Depth
These answers use the book's model (Bitcask-style: an append-only data file plus an in-memory hash map). Real databases vary in the details, and I say so where it matters.

**What a hash index is, and the problem it solves**
A hash index is a lookup table that answers one question very fast: "for this key, where in the data file is its value?" It solves the slowness of reading. Without it, finding one record means reading the file from the start. With it, the database jumps to the right spot in one step. It is built on the same **hash map** (dictionary) that you use in programming. The only twist is that the values stored in the map are *file positions*, not the data itself.

**Why not just search through all the records?**
Scanning is fine for 100 records and painful for 100 million. A scan takes time proportional to the amount of data (O(n)): double the data, double the wait. A hash lookup takes roughly the same time whether you have a thousand keys or a billion (O(1) on average). Think of finding one customer's file in a warehouse. Walking every aisle works but takes hours. Asking the front desk, "Where is customer 4521?" and being told "aisle 9, shelf 3" takes seconds. The cost is that the front desk has to be kept up to date every time a file moves.

**A simple real-world example**
Take a hotel with a front-desk board. The board lists each guest name and their room number. The guests' belongings are in the rooms (the data file). The board is the index.
- Guest arrives: you put them in the next free room (append), then write their name and room on the board.
- Someone asks for "Priya": you read the board (one quick lookup), walk to room 214, and find her.
- Priya moves to room 305: you do not clear out room 214. You simply put her in 305 and *change the board*. Room 214 holds stale data that will be cleaned up later (that is compaction).

**What the index actually stores**
Only two things per entry:
1. The **key** (e.g. the video URL or user ID).
2. The **byte offset** (the exact position in the data file where the latest value for that key starts). If there are several segment files, it also tells you which file.

It does not store the value, only a pointer to it. Because entries are this small, millions of keys fit in memory.

**Where it lives: memory, disk, or both?**
- The **index itself lives in memory (RAM)**. That is where the speed comes from.
- The **data lives on disk** in the append-only log file.
- The index is *also* backed up to disk in a limited way. If the database restarts, the memory is gone. It can rebuild the index by re-reading the whole log (slow for big files), or load a **snapshot** of the index saved on disk (fast). So disk is used for safety and fast recovery, but lookups use the in-memory copy.
- Note: some relational databases (e.g. PostgreSQL) offer hash indexes that live on disk. That is a different implementation of the idea. What is described here is the book's in-memory design.

**What happens when you insert a record**
Say you save `user:42 → "Meet"`.
1. The database **appends** a new line (`user:42,Meet`) to the end of the current data file. It always writes at the end.
2. It notes the byte offset where that line started (say byte 8,000).
3. It updates the in-memory hash map: `user:42 → 8,000`.
If `user:42` already existed, step 3 simply replaces the old offset. The old line stays in the file until compaction removes it. So an **update is just another insert**, and the newest entry wins.

**How the database decides where to store a record**
There are two separate "where" questions, and they have different answers.
- **Where does the record go on disk?** Always at the end of the log. There is no deciding. That is exactly why writes are so fast.
- **Where does the index entry go in memory?** This is where the **hash function** works. It takes the key (`user:42`), turns it into a number, and uses that number to pick a slot (bucket) in the hash map's array. The same key always gives the same number, so you can find the slot again later.

*Analogy:* a coat-check desk. Your coat goes on the next free hook (append). The *ticket system* decides which cubby holds your ticket slip (hash function picks the slot), and the slip says which hook your coat is on.

**What happens when two different keys land on the same slot (collision)**
This is called a **collision** and it is normal. A hash function squeezes a huge number of possible keys into a limited number of slots, so two keys will sometimes get the same one. The hash map handles it internally, and the data in the file is never affected. The two common ways:
- **Chaining:** each slot holds a small list. Both entries go in the list. To look up, you go to the slot and compare the actual key text of each entry until one matches (`user:42` vs `user:97`).
- **Open addressing:** if the slot is taken, try the next free slot, and remember how to find it.

This is why the hash map stores the *full key*, not just the hash. The hash only narrows the search. The key comparison confirms the match. A good hash function spreads keys evenly, so each slot has only a few entries and the lookup stays fast. Do not confuse this with the same key appearing twice, which is an *update*, not a collision.

**How a lookup works, step by step**
Say you ask for `user:42`.
1. Run the hash function on `user:42` to get a slot number.
2. Go to that slot in the in-memory hash map. If other keys share it, compare full keys until you find `user:42`. If it is not there, the key does not exist (that is the end of the search, no disk read needed).
3. Read the stored value: the byte offset, say 8,000 in segment file 3.
4. Jump straight to that offset on disk (one seek) and read the record.
5. Return the value.

So a lookup costs one in-memory lookup and at most one disk read. With several segments, the map already says which segment has the *newest* value, so you do not hunt through all of them.

**Does it store the data or just the location?**
Only the location. The index is a map from key to location. The real data sits in the log file. Remember this idea, because it comes back later: a **clustered index** (see "Storing values within the index") is the variant that stores the whole row inside the index itself.

**Updating a value that is already indexed**
The database never edits the old line in the file. It does the same thing as an insert:
1. Append the new version (`user:42,Meet B.`) to the end of the log.
2. Change the key's entry in the hash map to point at the new offset.

From that moment every lookup lands on the new version. The old version is still sitting in the file, unreachable, and wastes space until **compaction** runs. Compaction reads the segments, keeps only the newest value for each key, and writes them to a fresh segment. In the hotel example: Priya moved rooms, the board was changed, and the old room is cleaned later.

**Deleting a record**
You cannot erase a line from the middle of an append-only file, so a delete is also an *append*. The database writes a special marker called a **tombstone** for that key (think "user:42 → DELETED"). Then:
- The in-memory index is updated so the key is removed or marked deleted. A lookup now finds nothing.
- The old value and the tombstone both stay in the file for the moment.
- During compaction, when the merge sees the tombstone, it drops the key *and all its older values*. After that, the tombstone itself can be discarded too, and the space is genuinely freed.

Why not just delete the old line? Because it would break the "only ever append" rule that makes writes fast and crash recovery simple. The tombstone is the "cross it off the list" note that is written *at the end of the notebook*, not by tearing out a page.

**Unexpected shutdown (crash or power cut)**
The data file is safe because it is on disk, and everything already written to it survives. The **hash index is not safe by itself, because it lives in RAM and RAM is wiped**. So when the database restarts, the index is not simply "still there". It must be restored in one of two ways:
- **Rebuild:** read every segment from start to finish and re-create the key → offset entries. This is correct but can take a long time with big files, because it reads all the data.
- **Load a snapshot:** the database may have saved a copy of the index to disk from time to time. On restart it loads that copy and is back quickly. (Bitcask does this.)

Two more crash details. First, the crash may have happened *while a record was being appended*, leaving a half-written record at the end of the file. Each record carries a **checksum** (a small number computed from its contents), so on restart the database can detect the half-written record and ignore it. Second, writes are normally acknowledged only when they are safely on disk, so a fully acknowledged write is never lost.

**When the index is too big for memory**
This is the main weakness. The design only works while *all keys fit in RAM*. Note that it is the **keys**, not the values, that must fit, since values stay on disk. So you can store far more data than your RAM size, but not more *distinct keys* than it can hold.

If the keys outgrow memory you have these options:
- **Keep the hash map on disk.** Technically possible, but it performs badly. A hash function sends neighbouring keys to unrelated places, so every lookup is a *random* disk access. Growing the table is expensive, and collisions need fiddly logic. You lose the speed that made the idea attractive.
- **Split the data across several machines** (partitioning, Part II), so each machine holds only some of the keys.
- **Switch to a different structure** such as an LSM-tree or B-tree. That is the main reason those exist, and the next sections cover them.

**How much faster is it? A worked example**
The numbers below are rough, illustrative figures to show the *scale* of the difference. They are not benchmarks, and real hardware varies.

Imagine 100 million records of about 100 bytes each, which is about 10 GB of data on an SSD.
- **No index (scan):** to find one user, read up to the whole 10 GB. At a few hundred MB per second that is roughly **tens of seconds** for *one* lookup. Two thousand lookups per second is impossible.
- **Hash index:** the in-memory lookup takes well under a microsecond to a few microseconds, then one disk read of about 100 bytes costs on the order of 0.1 ms on an SSD (around 10 ms on a spinning disk). That is **about a tenth of a millisecond**.

That is roughly a **hundred-thousand-fold improvement** for this one lookup, and the gap *widens* as data grows, because the scan gets slower but the hash lookup does not. The memory cost: 100 million keys with, say, 20-byte keys, an 8-byte offset, and some overhead is on the order of **several GB of RAM**. You pay memory to buy speed.

**When a hash index makes things worse**
It is not "slower than scanning" in a strict sense, but it can be the wrong tool or a net loss when:
- **Keys are too many for memory.** The index spills to swap or disk and gets slower, or the process runs out of memory.
- **You run range or sorted queries** (say, all orders from last week). The index cannot help, so you scan or do thousands of single lookups. Keeping the index also adds cost to every write for no benefit.
- **The table is small.** For a few hundred rows, a scan is already instant and the index is overhead.
- **Writes are heavy but reads are rare.** Every write updates the index in memory. It is cheap here, but the index uses RAM that could have been used for caching.
- **You restart often with huge files.** Rebuilding the index on startup can be slow if there is no snapshot.
- **The hash function is poor.** Too many collisions make slots crowded and lookups slow down toward a scan of a short list.

**Why range searches don't work**
The key idea: **hashing deliberately destroys ordering**. A good hash function scatters keys randomly across slots. `kitty00001` and `kitty00002` look almost identical to you, but their hashes land in completely different places. So the hash map has no concept of "next key" or "keys between A and B".

Imagine a coat-check where tickets are filed into cubbies by a random scramble of the ticket number. If you want all tickets from 100 to 200, the only way is to check ticket 100, then 101, then 102, one at a time, each through the scramble. If the keys are not numbers, or there are gaps, you do not even know which keys to try. The only alternative is scanning *every* entry in the map and filtering, which is a full scan again.

**Can it find all records with a value greater than X?**
No, not efficiently. "Greater than" is a range query ("from X up to infinity"), so the same problem applies. A hash index only answers **equality** questions: "give me the record whose key *equals* this". To answer "greater than 100" you must examine every key, which is a full scan. Use a sorted structure (SSTable/LSM-tree or B-tree) for that. Two small clarifications: this limitation applies both to range conditions on the *key* and to conditions on the *value*, since the hash map is organised by key only.

**Comparison with other index types**

| | Hash index (in-memory, as in the book) | SSTable / LSM-tree | B-tree |
|---|---|---|---|
| Lookup by exact key | Excellent, usually one memory lookup + one disk read | Good, may check several files (Bloom filters help) | Good, a few page reads down the tree |
| Range queries | **No** | **Yes**, keys are sorted | **Yes**, keys are sorted |
| Number of keys | Limited by RAM | Not limited by RAM (sparse index) | Not limited by RAM |
| Write speed | Very fast (append + update map) | Very fast (memtable, sequential writes) | Slower (in-place page writes + WAL) |
| Data kept sorted? | No | Yes | Yes |
| Typical fit | Few keys, many updates (counters, caches, sessions) | Write-heavy workloads at large scale | General-purpose, most relational databases |

In short: a hash index is the simplest and fastest for "get this exact key" on a small key space, and the others trade a bit of that raw speed for sorting and for being independent of RAM size.

**Practical limitations to understand before using one**
1. **All keys must fit in memory.** The first thing to estimate is the number of distinct keys times the size per entry.
2. **Equality only.** No ranges, no "greater than", no "starts with", no sorted output, no "next/previous".
3. **Not durable on its own.** The index is in RAM, so you need a snapshot or a rebuild strategy, and restarts can be slow.
4. **Stale data piles up** until compaction runs. You need enough disk space and compaction must keep pace with writes.
5. **Deletes are not instant.** Space is released only after compaction.
6. **Concurrency needs care.** Many threads touching the same hash map and the same files need proper design (the book notes a common pattern is one writer thread and many reader threads, because the files are append-only and immutable once closed).
7. **Only one index per key.** It indexes the key you chose. Searching by anything else (email instead of user ID) requires another index or a scan.
8. **Collisions and resizing cost something.** A badly sized or badly hashed map degrades.

Good fit: counters, session stores, caches, "latest value for key" lookups, with lots of updates to a limited set of keys. Poor fit: reporting, ranges, huge key spaces, and anything that needs sorted results.

### SSTables and LSM-Trees
**Big picture.** Hash indexes cannot do range queries and are limited by RAM. The fix is to keep the segment files **sorted by key**. A segment sorted by key is a **Sorted String Table (SSTable)**. A database built by stacking SSTables with an in-memory buffer is an **LSM-tree** (Log-Structured Merge-tree). LevelDB, RocksDB, Cassandra, HBase, and Lucene's term dictionary use this idea.

**For a beginner.** Sorting gives you three superpowers:
1. **Merging is easy and cheap.** Merging two sorted files is like merging two sorted piles of cards: look at the top of each pile, take the smaller one. It works even if the files are bigger than memory. When the same key appears in several files, the newest file wins.
2. **A sparse index is enough.** You do not need every key in memory. If you know where "handbag" and "handsome" are, then "handiwork" must be between them. So keep one key per few kilobytes and scan a small block.
3. **Blocks can be compressed**, saving disk space and I/O.

#### Constructing and maintaining SSTables
Sorting data as it arrives sounds expensive, since writes arrive in random order. The trick is to sort in memory first:
1. Writes go into an in-memory sorted tree called a **memtable** (a red-black or AVL tree).
2. When the memtable gets big (a few MB), write it to disk as a new SSTable file. It is already sorted. New writes go into a fresh memtable.
3. **Read:** check the memtable, then the newest SSTable, then the next older, and so on.
4. In the background, **merge and compact** SSTable files, dropping overwritten or deleted values.
5. **Crash safety:** the memtable is only in RAM, so each write is *also* appended to a separate plain log file on disk. It is not sorted and exists only to rebuild the memtable after a crash. It is thrown away once the memtable is flushed.

*Analogy:* a post office sorting letters. Letters arrive in random order and you drop them in a sorting tray (memtable). When the tray is full, you file the sorted batch into a labelled box (SSTable). Later, you merge boxes so there are fewer to look through.

#### Making an LSM-tree out of SSTables
This whole recipe is the **LSM-tree** (the idea goes back to the log-structured file system and to Google's Bigtable paper). Lucene, the engine behind Elasticsearch and Solr, uses a similar approach for its term dictionary (word → list of documents containing it).

#### Performance optimizations
- **Slow lookup for missing keys.** To prove a key does *not* exist, you must check the memtable and every SSTable. The fix is a **Bloom filter**: a small memory-efficient structure that says "this key is *definitely not* in this file" or "it *might* be". A "definitely not" lets you skip the file. It can give false "might be" answers but never false "definitely not".
- **When and how to merge.** Two common strategies are **size-tiered** (merge smaller, newer SSTables into larger ones; HBase, Cassandra) and **leveled** (split key range into smaller SSTables and move data into "levels"; LevelDB, RocksDB, Cassandra). Leveled does less work per merge but uses more of it overall.

### B-Trees
**Big picture.** The *most widely used* index structure. Introduced in 1970 and standard in almost all relational databases and many non-relational ones. It also keeps keys sorted (so range queries work) but has a very different philosophy from LSM-trees.

**For a beginner.** LSM-trees write new data into new files and never touch old ones. A B-tree instead breaks the database into fixed-size **pages** (typically 4 KB) and **overwrites pages in place**. One page can be read or written at a time, which matches how disks work.

Pages are arranged as a tree. Each page holds keys and references to child pages. Each child covers a *range* of keys.

*Analogy:* a library. The entrance sign says "A–M this way, N–Z that way". Follow it to a hallway that says "A–C, D–F...". Keep narrowing until you reach the shelf (a **leaf page**) holding the book. The number of child references in a page is the **branching factor** (often hundreds). That is why B-trees stay shallow: a four-level tree with 4 KB pages and a branching factor of 500 can store up to about 256 TB.

- **Update:** find the leaf page, change the value, write the page back.
- **Insert:** find the right page. If it is full, **split** it into two half-full pages and update the parent. This keeps the tree **balanced**, so a lookup always takes about O(log n) steps.

#### Making B-trees reliable
Overwriting in place is risky. Splitting a page means writing several pages, and if the database crashes midway, you can end up with an **orphan page** (nobody points to it) and a corrupted index. The fix is a **write-ahead log (WAL)**, also called a **redo log**: an append-only file where *every change is written first*. After a crash, the database replays the WAL to restore a consistent tree. Another subtlety is **concurrency**: several threads touching the tree at once need protection, usually with lightweight locks called **latches**. LSM-trees have it easier here because they merge in the background and swap whole files atomically.

*Analogy:* before moving house you write the plan down in a notebook. If you are interrupted halfway, you read the notebook and carry on.

#### B-tree optimisations
- **Copy-on-write:** some databases (e.g. LMDB) write a modified page to a *new location* and update the parent pointers, instead of overwriting. This avoids needing a WAL for crash safety and helps concurrency.
- **Abbreviated keys:** store only enough of the key in interior pages to act as a signpost. This fits more keys per page, giving a higher branching factor and a shallower tree.
- **Sibling pointers:** leaf pages can point to their left and right neighbours so range scans do not have to go back up the tree.
- **Layout:** many engines try to keep leaf pages next to each other on disk, though this is hard to maintain as the tree grows. Other variants (fractal trees) borrow ideas from log-structured designs.

### Comparing B-Trees and LSM-Trees
**Big picture.** There is no winner, only trade-offs. The common rule of thumb: LSM-trees are typically *faster for writes* and B-trees typically *faster for reads*. But benchmarks depend heavily on your workload, so you must test with your own.

#### Advantages of LSM-trees
- **Lower write amplification.** *Write amplification* means one logical write causing several physical writes to disk over time. A B-tree writes every change at least twice (WAL plus the page itself, and entire pages even for tiny changes). LSM-trees also rewrite data during compaction, but often come out lower, especially for write-heavy loads. This matters because SSDs wear out with writes and because disk bandwidth is a bottleneck.
- **Higher write throughput**, partly because they write sequentially in compact files.
- **Better compression** and **less fragmentation**, so smaller files on disk. B-trees leave unused space inside pages.

#### Downsides of LSM-trees
- **Compaction interferes with live traffic.** Background merging competes for disk bandwidth, so a few requests become very slow (hurting high percentiles, which links back to Chapter 1). If writes outrun compaction, unmerged files pile up, reads slow down, and the disk can fill, and many engines do not warn you.
- **Duplicate keys** may exist in several files until compaction, which makes strong *transactional* locking on a key range harder. In a B-tree each key lives in exactly one place, so locks can attach to the tree directly.

### Other Indexing Structures
**Big picture.** So far we indexed by *primary key* (one unique key per record). Real apps also search by other things (all users in Berlin, all posts with a tag). These are **secondary indexes**, and they are built from the same B-tree or LSM ideas. The difference is that keys in a secondary index are **not unique**, so you either add the row ID to make keys unique or keep a list of matching row IDs.

#### Storing values within the index
Where does the actual row live? In a **heap file** (rows stored in no particular order), with indexes just pointing into it. Following the pointer costs an extra hop. Alternatives:
- **Clustered index:** the row is stored *inside* the index itself (e.g. MySQL InnoDB's primary key). One fewer hop, but the row can live in only one index.
- **Covering index** (index with included columns): the index also stores *some* columns, so certain queries are answered from the index alone.
- Trade-off: both speed up reads but need more disk space and slow writes, plus extra effort to keep data consistent.

#### Multi-column indexes
- **Concatenated index:** combine several columns into one key, like a phone book sorted by (last name, first name). Useful for "last name = Smith", but useless for "first name = Anna" alone.
- **Multi-dimensional index:** queries like "restaurants between this latitude *and* this longitude" need both ranges at once. A normal B-tree cannot do this efficiently, so geospatial databases use specialised structures such as **R-trees**. The same idea applies to searching products by colour ranges or weather by date and temperature.

#### Full-text search and fuzzy indexes
Normal indexes need exact keys. Search engines must match typos ("recieve"), plurals, and synonyms. Lucene stores its term dictionary as an SSTable-like structure in memory and handles fuzzy lookups by searching words within a small **edit distance** (one or two letters changed), using an automaton related to a trie. This is a conceptual preview of search engines, not something to master now.

#### Keeping everything in memory
Disks are cheap but awkward to work with. RAM has become cheap enough that many datasets *fit in memory*. **In-memory databases** (Memcached for caching, Redis, VoltDB, MemSQL) keep data in RAM. Some are fine losing data on restart (caches). Others stay durable by writing a log to disk, taking periodic snapshots, or replicating to other machines.

**Common misconception:** in-memory databases are *not* fast just because they avoid reading from disk. A disk-based engine with enough RAM also caches hot data. They are faster mainly because they skip the overhead of encoding data into disk-friendly formats. They can also use data structures that are hard to do on disk, such as priority queues and sets. The **anti-caching** approach even lets them handle datasets bigger than memory by evicting cold records to disk.

## 2. Transaction Processing or Analytics?

### OLTP vs OLAP
**Big picture.** Everything so far suits **OLTP** (*online transaction processing*): an app reads or writes a few records at a time, by key, with low latency. A "transaction" here just means a logical unit of work such as a sale, an order, or a comment. It does *not* necessarily mean ACID guarantees (that is Chapter 7). A second type of work looks very different: **OLAP** (*online analytic processing*). Analysts want to scan millions or billions of records and compute totals, such as "total revenue per store in January" or "how much more did we sell during the banana promotion?"

| | OLTP | OLAP |
|---|---|---|
| Used by | End users via the app | Analysts, managers |
| Typical read | A few rows by key | Aggregate over a huge number of rows |
| Typical write | Small, random, latency-critical | Bulk import (ETL) or event stream |
| Data | Latest state | History over time |
| Size | GB to TB | TB to PB |
| Bottleneck | Disk seek time | Disk bandwidth |

**For a beginner.** Think of a cashier versus an accountant. The cashier handles one customer at a time, fast. The accountant sums up a year of receipts. You would not want the accountant's huge calculations slowing the cashier's till. That brings us to warehouses.

### Data Warehousing
A **data warehouse** is a separate database holding a **read-only copy** of data from all the company's OLTP systems (sales, inventory, website, etc.). Data is pulled out, cleaned up and loaded in a process called **ETL** (*Extract, Transform, Load*). Analysts can then run heavy queries without hurting the live systems. Warehouse examples: Snowflake, BigQuery, Redshift, Teradata.

#### The divergence between OLTP databases and data warehouses
Both usually speak SQL, so they look similar from outside, but their insides are optimised for opposite goals. Many vendors support only one or the other. Warehouses also tend to be indexed little, since analytic queries scan huge ranges, which is why the next sections focus on *storage layout* instead of indexes.

### Stars and Snowflakes: Schemas for Analytics
**Big picture.** Warehouses use a common, simple layout so analysts can find things.

**For a beginner.** In a **star schema**, one central **fact table** records each *event* (one row per sale: when, which product, which store, which customer, price). Many columns are not data but **foreign keys** pointing at small surrounding **dimension tables** that describe the *who, what, where, when, how* (product details, store details, a date table). Drawn out, it looks like a star. A **snowflake schema** breaks dimensions into sub-dimensions (product → brand → category). It is more normalised but harder to work with, so many analysts prefer stars.

*Example:* a supermarket's fact table `sales` has billions of rows. A `dim_product` table says which items are fresh fruit. A query "sales of fresh fruit in Q4 per store" joins the huge fact table to these small dimensions. Fact tables are often very wide (100+ columns), which sets up the next section.

## 3. Column-Oriented Storage

### The core idea
**Big picture.** A typical analytic query touches only 3 or 4 of the 100+ columns in a fact table. But a row-oriented database reads *every column of every row* from disk and then discards what it does not need. That is slow and wasteful.

**For a beginner.** Row-oriented storage is like a stack of filled-in paper forms. To add up everyone's age you must pick up every form. **Column-oriented** storage is like one long list *per field*: all ages together, all names together. To sum ages you read only the age list. The rows are rebuilt by position: the 23rd entry in every column file belongs to the same row. Parquet is a well-known column-oriented file format. Do not confuse this with the "column families" in Cassandra and HBase, which still store each row together.

### Column Compression
Values in one column are very repetitive (a "country" column in a billion rows has only about 200 different values). **Bitmap encoding** turns each distinct value into a bit string saying which rows have it, and **run-length encoding** shrinks long runs of zeros. A column can end up hundreds of times smaller than the raw data.

*Analogy:* instead of writing "France" a million times, write "France: rows 1–1,000,000".

#### Memory bandwidth and vectorized processing
Reading from disk is one bottleneck. Another is moving data from **main memory into the CPU cache**. Compressed columns fit more values per CPU cache line. Modern CPUs can also apply **SIMD** (*single instruction, multiple data*) operations to whole blocks of values at once with no function-call overhead, and compressed columns are designed to feed such tight loops. This is called **vectorized processing**.

### Sort Order in Column Storage
Columns are stored in the *same row order* so rows can be matched by position. You can choose to sort rows by a particular column (like "date"), and it works for the whole table at once (you cannot sort each column independently, or the positions would not match).
- **Why sort?** Queries filtering on that column (e.g. last month) read only a small slice. Also, the **first sort column compresses extremely well**, because identical values sit together in long runs (a second sort column helps less).
- Pick the sort key from the queries people run most.

#### Several different sort orders
Since data in a warehouse is replicated anyway for reliability, you can store each replica in a *different* sort order and use whichever matches the query. This is similar to having several secondary indexes, but here the *data itself* is rearranged, not just pointed to.

### Writing to Column-Oriented Storage
Column stores make reads great but writes harder. Inserting a row in the middle of a sorted, compressed column means rewriting every column file. B-trees' update-in-place cannot work. Instead the **LSM-tree idea** returns: writes go into an in-memory sorted store (row- or column-oriented), then are merged to disk in bulk. Queries must look at both the disk columns and the recent in-memory writes. This is how Vertica works and is hidden from the analyst.

### Aggregation: Data Cubes and Materialised Views
Analysts keep running the same aggregates (COUNT, SUM, AVG, MIN, MAX). **Materialised view:** a stored copy of the *result* of a query, written to disk. A normal (virtual) view is just a saved query. A materialised view is real data, so it must be refreshed when the underlying data changes, making writes costlier.

A **data cube** (OLAP cube) is a special case: a grid of pre-computed aggregates by several dimensions (e.g. total sales by date × product). To get "sales per product on one day", you look up a cell instead of scanning billions of rows. Downsides: it can only answer questions it was built for. It lacks the flexibility of raw data, so warehouses keep raw data and use cubes only as a performance boost.

## Summary (Big Picture)
- **Two worlds:** OLTP (app traffic, row-oriented, indexed) and OLAP (analytics, column-oriented, scan-heavy).
- **OLTP has two families:**

| | LSM-trees (log-structured) | B-trees (page-oriented) |
|---|---|---|
| Write pattern | Append only, merge later | Overwrite pages in place |
| Examples | LevelDB, RocksDB, Cassandra, HBase | PostgreSQL, MySQL (InnoDB), most relational DBs |
| Strength | Write throughput, compact files | Predictable reads, one copy per key |
| Weakness | Compaction can disturb latency | Write amplification, fragmentation |

- **OLAP** wins by reading only the needed columns, compressing them hard, and using the CPU efficiently.
- **Chapter 4** continues with how this data is *encoded* when it is stored or sent over a network.

## Self-Check Questions
Try to answer these from memory before re-reading:
1. Why is appending to a log fast, and what does an index cost?
2. What can a hash index not do, and how do SSTables fix it?
3. Walk through what happens when you write then read a key in an LSM-tree. What is a memtable, and why is there a separate log file?
4. What is a Bloom filter, and what problem does it solve?
5. How does a B-tree differ from an LSM-tree in how it handles updates? Why does it need a WAL?
6. What is write amplification, and which structure tends to suffer more?
7. What is the difference between OLTP and OLAP? Why have a separate warehouse?
8. What is a star schema?
9. Why is a column store faster for analytics but harder to write to?
10. Why does a sorted column compress better?

> Note: this file was written from the standard content of Chapter 3 (first edition of the book) and its structure was checked against your 31 Oct notes. Specific figures and examples are summaries or my own illustrations, not quotes or page references. Check them against your copy of the book and add your own observations below.

## My Notes and Open Questions
-

---
Back to the main chapter list: <doc:Part1-FoundationsOfDataSystems>
