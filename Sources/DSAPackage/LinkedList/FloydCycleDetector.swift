//
//  FloydCycleDetector.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 14/09/26.
//

import Foundation

// MARK: Node Definition
class ListNode<T> {
    var value: T
    var next: ListNode?
    
    init(_ value: T) {
        self.value = value
    }
}

// MARK: Floyd's Cycle Detection
struct FloydCycleDetector<T> {
    
    /// Detects whether a cycle exists in the linked list.
    /// Time: `O(n)`, Space: `O(1)`
    static func hasCycle(_ head: ListNode<T>?) -> Bool {
        var slow = head
        var fast = head
        
        while fast != nil && fast?.next != nil {
            slow = slow?.next
            fast = fast?.next?.next
            
            if slow === fast {
                return true
            }
        }
        return false
    }
    
    /// Returns the node where the cycle begins, or nil if no cycle.
    /// Time: `O(n)`, Space: `O(1)`
    static func detectCycleStart(_ head: ListNode<T>?) -> ListNode<T>? {
        var slow = head
        var fast = head
        
        // Phase 1: Determine if a cycle exists, find meeting point
        while fast != nil && fast?.next != nil {
            slow = slow?.next
            fast = fast?.next?.next
            if slow === fast {
                break
            }
        }
        
        // No cycle
        if fast == nil || fast?.next == nil {
            return nil
        }
        
        // Phase 2: Find the entry point of the cycle
        slow = head
        while slow !== fast {
            slow = slow?.next
            fast = fast?.next
        }
        return slow
    }
    
    /// Returns the length of the cycle, or 0 if no cycle.
    static func cycleLength(_ head: ListNode<T>?) -> Int {
        var slow = head
        var fast = head
        
        while fast != nil && fast?.next != nil {
            slow = slow?.next
            fast = fast?.next?.next
            
            if slow === fast {
                var length = 1
                var temp = slow?.next
                while temp !== slow {
                    temp = temp?.next
                    length += 1
                }
                return length
            }
        }
        return 0
    }
}
