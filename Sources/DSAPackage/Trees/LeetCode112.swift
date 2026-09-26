//
//  LeetCode112.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 26/09/26.
//

import Foundation

/// Given the root of a binary tree and an integer targetSum, return true if the tree has a root-to-leaf path such that adding up all the values along the path equals targetSum.
/// A leaf is a node with no children.
///     Example: Input: root = [5,4,8,11,null,13,4,7,2,null,null,null,1], targetSum = 22
///     Output: true
///         Explanation: The root-to-leaf path with the target sum is shown.

func hasPathSum(_ root: TreeNode<Int>?, _ targetSum: Int) -> Bool {
    guard let root = root else { return false }
    
    let remaining = targetSum - root.value
    
    if root.left == nil && root.right == nil {
        return remaining == 0
    }
    
    return hasPathSum(root.left, remaining) || hasPathSum(root.right, remaining)
}
