//
//  LeetCode104.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 25/09/26.
//

import Foundation

/// Given the root of a binary tree, return its maximum depth.
/// A binary tree's maximum depth is the number of nodes along the longest path from the root node down to the farthest leaf node.

func maxDepth(_ root: TreeNode<Int>?) -> Int {
    guard let root = root else { return 0 }
    return 1 + max(maxDepth(root.left), maxDepth(root.right))
}
