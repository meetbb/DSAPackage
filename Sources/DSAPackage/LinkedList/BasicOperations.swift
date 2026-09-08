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
    func insertAtHead(_ value: T) {
        let node = Node(value)
        node.next = head
        head = node
        if tail == nil {
            tail = node
        }
        count += 1
    }
    
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
}
