//
//  LeetCode108.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 25/09/26.
//

import Foundation

/// Given an integer array nums where the elements are sorted in ascending order, convert it to a height-balanced binary search tree.
func sortedArrayToBst(nums: [Int]) -> TreeNode<Int>? {
    return build(nums, 0, nums.count - 1)
}

func build(_ nums: [Int], _ left: Int, _ right: Int) -> TreeNode<Int>? {
    guard left <= right else { return nil }
    
    let mid = left + (right - left) / 2
    let node = TreeNode(nums[mid])
    
    node.left = build(nums, left, mid - 1)
    node.right = build(nums, mid + 1, right)
    
    return node
}
