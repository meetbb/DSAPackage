//
//  BasicOperations.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 19/09/26.
//

import Foundation

// MARK: Node Definition

/// A generic binary tree node. `T` must be comparable so we can use
/// the same node type for both plain binary trees and BSTs.
final class TreeNode<T: Comparable> {
    var value: T
    var left: TreeNode?
    var right: TreeNode?
    
    init(_ value: T, left: TreeNode? = nil, right: TreeNode? = nil) {
        self.value = value
        self.left = left
        self.right = right
    }
}

// MARK: Tree Operations

enum TreeOperations<T: Comparable> {
    
    // MARK: Insert (BST)
    /// Inserts a value into a BST, preserving the left<node<right invariant.
    /// Recursive. O(h) time where h = tree height (O(log n) balanced, O(n) degenerate).
    static func insert(_ root: TreeNode<T>?, _ value: T) -> TreeNode<T> {
        guard let root = root else { return TreeNode(value) }
        
        if value < root.value {
            root.left = insert(root.left, value)
        } else {
            root.right = insert(root.right, value)
        }
        // Equal values: no-op (no duplicates). Adjust if you want a multiset.
        return root
    }
    
    // MARK: Search (BST)
    
    /// Searches a BST for a value using the ordering invariant to prune
    /// half the tree at each step. O(h) time, O(h) space (recursion stack).
    static func search(_ root: TreeNode<T>?, _ target: T) -> Bool {
        guard let root = root else { return false }
        if root.value == target {
            return true
        }
        return target < root.value ? search(root.left, target) : search(root.right, target)
    }
    
    // MARK: Delete (BST)
    
    /// Deletes a value from a BST, handling all three cases:
    /// leaf, one child, two children (successor swap).
    static func delete(_ root: TreeNode<T>?, _ value: T) -> TreeNode<T>? {
        guard let root = root else { return nil }
        
        if value < root.value {
            root.left = delete(root.left, value)
        } else if value > root.value {
            root.right = delete(root.right, value)
        } else {
            // Found the node to delete
            if root.left == nil {
                return root.right
            }
            if root.right == nil {
                return root.left
            }
            
            // Two children: replace value with in-order successor
            // (smallest value in right subtree), then delete that successor.
            let successor = minNode(root.right!)
            root.value = successor.value
            root.right = delete(root.right, successor.value)
        }
        return root
    }
    
    private static func minNode(_ node: TreeNode<T>) -> TreeNode<T> {
        var current = node
        
        while let next = current.left {
            current = next
        }
        return current
    }
    
    // MARK: DFS Traversals - Recursive
    
    static func inorder(_ root: TreeNode<T>?) -> [T] {
        guard let root = root else { return [] }
        return inorder(root.left) + [root.value] + inorder(root.right)
    }
    
    static func preorder(_ root: TreeNode<T>?) -> [T] {
        guard let root = root else { return [] }
        return [root.value] + inorder(root.left) + inorder(root.right)
    }
    
    static func postorder(_ root: TreeNode<T>?) -> [T] {
        guard let root = root else { return [] }
        return inorder(root.left) + inorder(root.right) + [root.value]
    }
    
    // MARK: DFS Traversal - Iterative (in-order, using an explicit stack)
    /// Same result as `inorder`, but without recursion - useful when tree depth could blow the call stack,
    /// or when an interviewer asks "now do it without recursion."
    static func inorderIterative(_ root: TreeNode<T>?) -> [T] {
        var result: [T] = []
        var stack: [TreeNode<T>] = []
        var current = root
        
        while current != nil || !stack.isEmpty {
            while let node = current {
                stack.append(node)
                current = node.left
            }
            
            let node = stack.removeLast()
            result.append(node.value)
            current = node.right
        }
        return result
    }
    
    // MARK: BFS Traversal (level-order)
    /// Visits nodes level by level, left to right. Needs a queue (FIFO)
    /// rather than a stack, because we want siblings before children.
    static func levelOrder(_ root: TreeNode<T>?) -> [[T]] {
        guard let root = root else { return [] }
        var result: [[T]] = []
        var queue: [TreeNode<T>] = [root]
        
        while !queue.isEmpty {
            var level: [T] = []
            var nextQueue: [TreeNode<T>] = []
            
            for node in queue {
                level.append(node.value)
                if let left = node.left {
                    nextQueue.append(left)
                }
                if let right = node.right {
                    nextQueue.append(right)
                }
            }
            result.append(level)
            queue = nextQueue
        }
        return result
    }
    
    // MARK: Height/Depth
    /// Height = number of edges on the longest path from this node to a leaf.
    /// An empty tree has height -1; a single node has height 0.
    static func height(_ root: TreeNode<T>?) -> Int {
        guard let root = root else { return -1 }
        return 1 + max(height(root.left), height(root.right))
    }
    
    // MARK: Node/Leaf Counts
    static func countNodes(_ root: TreeNode<T>?) -> Int {
        guard let root = root else { return 0 }
        return 1 + countNodes(root.left) + countNodes(root.right)
    }
}

