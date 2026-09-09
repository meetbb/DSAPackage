//
//  DoublyLinkedList.swift
//  
//
//  Created by Meet Brahmbhatt on 09/09/26.
//
import Foundation

/// Basic doubly-linked-list operations - insert at head/tail/position, delete
/// first/last/intermediate node.
///
/// The key difference from Singly LinkedList: every node carries a `prev`
/// pointer in addition to `next`. That's what makes delete-at-tail O(1) here,
/// versus O(n) in the singly linked version.
final class DNode<T> {
    var value: T
    var prev: DNode<T>?
    var next: DNode<T>?
    
    init(_ value: T) {
        self.value = value
    }
}

final class DoublyLinkedList<T: Equatable> {
    
    private(set) var head: DNode<T>?
    private(set) var tail: DNode<T>?
    private(set) var count: Int = 0
    
    // MARK: Insert
    /// Insert at the front. O(1)
    func insertAtHead(_ value: T) {
        let node = DNode(value)
        node.next = head
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
        count += 1
    }
    
    /// Insert at the end. O(1) thanks to the tail pointer
    func insertAtTail(_ value: T) {
        let node = DNode(value)
        node.prev = tail
        tail?.next = node
        tail = node
        if head == nil {
            head = node
        }
        count += 1
    }
    
    /// Insert at a specific 0-based position. O(n) to walk to position,
    /// but the actual splice is O(1) once we're there – unlike the singly
    /// linked version, we don't need a separate "previous" walk, because
    /// each node already knows its own `prev`
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
        
        if current === tail {
            insertAtTail(value)
            return
        }
        
        let node = DNode(value)
        let next = current.next
        
        node.prev = current
        node.next = next
        current.next = node
        next?.prev = node
        
        count += 1
    }
    
    // MARK: Delete
    /// Delete the first node: O(1)
    @discardableResult
    func deleteFirst() -> Bool {
        guard let head else { return false }
        
        let next = head.next
        next?.prev = nil
        self.head = next
        if next == nil {
            tail = nil
        }
        
        head.next = nil // fully dispatch the removed node
        count -= 1
        return true
    }
    
    /// Delete the last node. O(1) – this is the operation a `prev`
    /// pointer exists to make cheap. A singly linked list has to walk from `head`
    /// to find the second-to-last node O(n); here `tail.prev` already is that node.
    @discardableResult
    func deleteLast() -> Bool {
        guard let tail else {
            return false
        }
        
        let previous = tail.prev
        previous?.next = nil
        self.tail = previous
        if previous == nil {
            head = nil
        }
        
        tail.prev = nil // fully dispatch the removed node
        count -= 1
        return true
    }
    
    /// Delete an intermediate node at a specific 0-based position.
    /// O(n) to find it by walking from head, but O(1) to unlink once found -
    /// no "previous" tracking needed during the walk, since `node.prev` is
    /// already there.
    @discardableResult
    func deleteAt(_ position: Int) -> Bool {
        guard position > 0, let head else {
            return false
        }
        
        if position == 0 {
            return deleteFirst()
        }
        
        var current: DNode<T>? = head
        var index = 0
        
        while let node = current, index < position {
            current = node.next
            index += 1
        }
        
        guard let target = current else { return false }
        if target === tail { return deleteLast() }
        
        target.prev?.next = target.next
        target.next?.prev = target.prev
        
        target.prev = nil // fully dispatch the removed node
        target.next = nil
        count -= 1
        return true
    }
    
    /// Delete the first node matching `value`, wherever it sits: O(n).
    @discardableResult
    func delete(_ value: T) -> Bool {
        var current = head
        while let node = current {
            if node.value == value {
                if node === head {
                    return deleteFirst()
                }
                
                if node === tail {
                    return deleteLast()
                }
                node.prev?.next = node.next
                node.next?.prev = node.prev
                node.prev = nil
                node.next = nil
                count -= 1
                return true
            }
            current = node.next
        }
        return false
    }
    
    // MARK: Traverse
    /// Forward traversal. O(n)
    func traverse() -> [T] {
        var result: [T] = []
        var current = head
        while let node = current {
            result.append(node.value)
            current = node.next
        }
        return result
    }
    
    func traverseBackward() -> [T] {
        var result: [T] = []
        var current = tail
        while let node = current {
            result.append(node.value)
            current = node.prev
        }
        return result
    }
    
    var isEmpty: Bool {
        head == nil
    }
}

// MARK: - CustomStringConvertible
 
extension DoublyLinkedList: CustomStringConvertible {
    var description: String {
        traverse().map { "\($0)" }.joined(separator: " <-> ")
    }
}
