//
//  LeetCode102.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 25/09/26.
//

import Foundation

/// Given the root of a binary tree, return the level order traversal of its nodes' values. (i.e., from left to right, level by level).
func levelOrder(_ root: TreeNode<Int>?) -> [[Int]] {
    guard let root = root else {
        return []
    }
    
    var results: [[Int]] = []
    var queue: [TreeNode] = [root]
    
    while !queue.isEmpty {
        var subArray: [Int] = []
        let levelSize = queue.count
        for _ in 0..<levelSize {
            let node = queue.removeFirst()
            subArray.append(node.value)
            
            if node.left != nil {
                queue.append(node)
            }
            
            if node.right != nil {
                queue.append(node)
            }
        }
        results.append(subArray)
    }
    return results
}
