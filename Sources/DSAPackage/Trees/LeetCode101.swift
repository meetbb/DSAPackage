//
//  LeetCode101.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 25/09/26.
//

import Foundation

enum LeetCode101 {
    /// Given the root of a binary tree, check whether it is a mirror of itself (i.e., symmetric around its center).
    static func isSymmetricTree(_ root: TreeNode<Int>?) -> Bool {
        return isMirror(root?.left, root?.right)
    }

    static func isMirror(_ p: TreeNode<Int>?, _ q: TreeNode<Int>?) -> Bool {
        if p == nil && q == nil {
            return true
        }

        if p == nil || q == nil {
            return false
        }

        return p!.value == q!.value && isMirror(p!.left, q!.right) && isMirror(p!.right, q!.left)
    }
}
