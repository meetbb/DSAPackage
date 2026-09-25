//
//  LeetCode111.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 25/09/26.
//

import Foundation

/// Given a binary tree, find its minimum depth.
/// The minimum depth is the number of nodes along the shortest path from the root node down to the nearest leaf node.
/// Note: A leaf is a node with no children.
/// For example: Input: root = [3,9,20,null,null,15,7] then Output: 2

func minDepth(_ root: TreeNode<Int>?) -> Int {
    guard let root = root else { return 0 }
    
    if root.left == nil {
        return 1 + minDepth(root.right)
    }
    
    if root.right == nil {
        return 1 + minDepth(root.left)
    }
    
    return 1 + min(minDepth(root.left), minDepth(root.right))
}
