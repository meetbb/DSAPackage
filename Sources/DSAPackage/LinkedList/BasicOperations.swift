//
//  BasicOperations.swift
//  
//
//  Created by Meet Brahmbhatt on 08/09/26.
//
import Foundation

/// Basic singly-linked list operations - insert, delete, traverse.

final class Node<T> {
    var value: T
    var next: Node<T>?
    
    init(_ value: T) {
        self.value = value
    }
}

final class LinkedList<T: Equatable> {
    
    private(set) var head: Node<T>?
    private var tail: Node<T>?
    private(set) var count: Int = 0
    
    // MARK: Insert
    /// Insert at the front: O(1)
    func insertAtHead(_ value: T) {
        let node = Node(value)
        node.next = head
        head = node
        if tail == nil {
            tail = node
        }
        count += 1
    }
    
    /// Insert at the end: O(1) thanks to the tail pointer.
    /// However, in worst case, if it re-walks the list each time then: O(n)
    func insertAtTail(_ value: T) {
        let node = Node(value)
        if let tail = tail {
            tail.next = node
        } else {
            head = node
        }
        tail = node
        count += 1
    }
    
    /// Insert at a specific 0-based position. O(n) - must walk to position.
    func insert(_ value: T, at position: Int) {
        guard position > 0, let head else {
            insertAtHead(value)
            return
        }
        
        var current = head
        var index = 0
        while index < position - 1, let next = current.next {
            current = next
            index += 1
        }
        
        let node = Node(value)
        node.next = current.next
        current.next = node
        if node.next == nil {
            tail = node
        }
        count += 1
    }
    
    // MARK: Delete
    /// Delete the first node matching `value` O(n)
    @discardableResult
    func delete(_ value: T) -> Bool {
        guard let head else { return false }
        
        if head.value == value {
            self.head = head.next
            if self.head == nil {
                tail = nil
            }
            count -= 1
            return true
        }
        
        var previous = head
        var current = head.next
        while let node = current {
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
    
    /// Delete the node at a specific 0-based position. O(n)
    @discardableResult
    func deleteAt(_ position: Int) -> Bool {
        guard let head, position >= 0 else { return false }
        
        if position == 0 {
            self.head = head.next
            if self.head == nil {
                tail = nil
            }
            count -= 1
            return true
        }
        
        var previous = head
        var index = 0
        while index < position - 1, let next = previous.next {
            previous = next
            index += 1
        }
        
        guard let target = previous.next else { return false }
        previous.next = target.next
        if target === tail {
            tail = previous
        }
        
        count -= 1
        return true
    }
    
    /// Delete the last node (tail). O(n) even though we have a `tail` pointer –
    /// a singly linked list can't walk backward, so removing the tail means
    /// finding the `second-to-last` node by walking from head.
    @discardableResult
    func deleteLast() -> Bool {
        guard let head else { return false }
        
        if head.next == nil {
            self.head = nil
            count -= 1
            return true
        }
        
        var current = head
        while let next = current.next, next.next != nil {
            current = next
        }
        
        current.next = nil
        tail = current
        count -= 1
        return true
    }
    
    /// Delete the entire list: O(n)
    /// `head = nil` alone would technically work - dropping the only reference
    /// to the first node let's ARC deallocate it, which then deallocates its `next`
    /// and so on down the chain. The problem: that chain of deinits is RECURSIVE,
    /// one stack frame per node. For a short list that's fine. For a list of tens of
    /// thousands of nodes, it can overflow the stack and crash – a well-known Swift
    /// gotcha for linked structures.
    ///
    /// The fix is to unlink nodes one at a time ourselves, iteratively, so each node's
    /// reference count hits zero and it deallocates immediately – before we ever touch
    /// the next one.
    func deleteList() {
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
    
    // MARK: Traverse/Search
    func traverse() -> [T] {
        var results: [T] = []
        var current = head
        while let node = current {
            results.append(node.value)
            current = node.next
        }
        return results
    }
    
    /// O(n) search – returns true if `value` exists in the list.
    func contains(_ value: T) -> Bool {
        var current = head
        while let node = current {
            if node.value == value {
                return true
            }
        }
        return false
    }
}
