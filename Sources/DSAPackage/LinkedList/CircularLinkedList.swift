//
//  CircularLinkedList.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 12/09/26.
//

/// A circular linked list is the same node structure, with one change: the last node's next points back to the first node instead of `nil`.
/// There's no true "end" – traversal loops forever unless you explicitly detect you've come back to where you started.
import Foundation

/// Where is it commonly used:
///     - Round-Robin scheduling – CPU time-slicing, multiplayer game turn order, load balancing across a fixed pool of workers. Each of these is fundamentally "give everyone a turn, then start over" – the exact shape a circular list models directly.
///     - Circular buffers / ring buffers – fixed-size buffers that overwrite the oldest data once full, common in audio/video streaming pipelines (this is close to what AVAudioEngine - style audio processing uses internally for buffering).
///     - Playlist "repeat all" / shuffle queues – a music player looping back to track 1 after the last track is a circular list conceptually, even if the actual implementation uses an array with modulo indexing instead.
///     - The Josephus problem – a classic interview/theory problem (repeatedly eliminating every kth person in a circle) that's the canonical circular-linked-list teaching example, precisely because "circle of people" maps directly onto the structure.

final class CNode<T> {
    var value: T
    var next: CNode<T>?
    
    init(_ value: T) {
        self.value = value
    }
}

final class CircularLinkedList<T: Equatable> {
    
    private(set) var head: CNode<T>?
    private(set) var tail: CNode<T>?
    private(set) var count: Int = 0
    
    // MARK: Insert
    /// Insert at the head: O(1)
    func insertAtHead(_ value: T) {
        let node = CNode(value)
        
        guard let head, let tail else {
            // First node in the list: it points to itself.
            node.next = node
            self.head = node
            self.tail = node
            count += 1
            return
        }
        
        node.next = head
        self.head = node
        tail.next = node
        count += 1
    }
    
    /// Insert at the end. O(1) thanks to the tail pointer.
    func insertAtTail(_ value: T) {
        guard head != nil else {
            insertAtHead(value)
            return
        }
        
        let node = CNode(value)
        node.next = head
        tail?.next = node
        tail = node
        count += 1
    }
    
    // Insert at a specific 0-based position. O(n) to walk to position.
    func insert(_ value: T, at position: Int) {
        guard position > 0, let head else {
            insertAtHead(value)
            return
        }
        
        var current = head
        var index = 0
        while index < position - 1 && current.next !== head {
            current = current.next!
            index += 1
        }
        
        if current === tail {
            insertAtTail(value)
            return
        }
        
        let node = CNode(value)
        node.next = current.next
        current.next = node
        count += 1
    }
    
    // MARK: Delete
    /// Delete the first node O(1)
    @discardableResult
    func deleteFirst() -> Bool {
        guard let head else { return false }
        
        if head === tail {
            self.head = nil
            self.tail = nil
            count -= 1
            return true
        }
        
        self.head = head.next
        tail?.next = self.head // tail must re-point at the new head
        count -= 1
        return true
    }
    
    /// Delete the last node. O(n) – same limitation as the singly linked list: without a `prev` pointer, finding the node *before* tail means walking from `head`. A circular DOUBLY linked list would make this O(1), the same way the plain doubly linked list did.
    @discardableResult
    func deleteLast() -> Bool {
        guard let head, let tail else { return false }
        
        if head === tail {
            self.head = nil
            self.tail = nil
            count -= 1
            return true
        }
        
        var current = head
        while current.next !== tail {
            current = current.next!
        }
        
        current.next = head // close the circle, skipping the old tail
        self.tail = current
        count -= 1
        return true
    }
    
    /// Delete the first node matching `value`, wherever it sits. O(n)
    @discardableResult
    func delete(_ value: T) -> Bool {
        guard let head else { return false }
        
        if head.value == value {
            return deleteFirst()
        }
        
        var previous = head
        var current = head.next
        
        while let node = current, node !== head {
            if node.value == value {
                previous.next = node.next
                if node === tail {
                    tail = previous
                }
                count -= 1
                return true
            }
            previous = node
            current = node.next
        }
        return false
    }
    
    // MARK: Traverse
    /// Walk the list exactly once around and return its values.
    /// Uses `count` as the stopping condition rather than "next == head", which is the safe pattern for circular lists – a plain `while true` loop here would never terminate.
    func traverse() -> [T] {
        guard let head else { return [] }
        
        var results: [T] = []
        var current: CNode<T>? = head
        
        for _ in 0..<count {
            guard let node = current else { break }
            results.append(node.value)
            current = node.next
        }
        return results
    }
    
    var isEmpty: Bool { head == nil }
}


// MARK: - CustomStringConvertible
extension CircularLinkedList: CustomStringConvertible {
    var description: String {
        guard !isEmpty else { return "(empty)" }
        return traverse().map { "\($0)" }.joined(separator: " -> ") + " -> (back to head)"
    }
}
