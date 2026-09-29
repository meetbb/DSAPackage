//
//  LeetCode100.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 25/09/26.
//

import Foundation

enum LeetCode100 {
    /// Given the roots of two binary trees p and q, write a function to check if they are the same or not.
    /// Two binary trees are considered the same if they are structurally identical, and the nodes have the same value.
    static func isSameTree(_ p: TreeNode<Int>?, _ q: TreeNode<Int>?) -> Bool {
        guard let p = p, let q = q else {
            return p == nil && q == nil
        }
        return p.value == q.value && isSameTree(p.left, q.left) && isSameTree(p.right, q.right)
    }
}
