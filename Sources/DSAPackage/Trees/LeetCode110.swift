//
//  LeetCode110.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 26/09/26.
//

import Foundation

/// Given a binary tree, determine if it is height-balanced.
///     Example Input: root = [3,9,20,null,null,15,7]
///     Output: true
///     1,2, 3

func isBalanced(_ root: TreeNode<Int>?) -> Bool {
    return checkHeight(root) != -1
}

func checkHeight(_ node: TreeNode<Int>?) -> Int {
    guard let node = node else { return 0 }
    
    let leftHeight = checkHeight(node.left)
    if leftHeight == -1 { return -1 }
    
    let rightHeight = checkHeight(node.right)
    if rightHeight == -1 { return -1 }
    
    if abs(leftHeight - rightHeight) > 1 {
        return -1
    }
    
    return 1 + max(leftHeight, rightHeight)
}
