//
//  LeetCode109.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 25/09/26.
//

import Foundation

/// Given the head of a singly linked list where elements are sorted in ascending order, convert it to a height-balanced binary search tree.

func sortedListToBST(_ head: ListNode<Int>?) -> TreeNode<Int>? {
    var nums: [Int] = []
    var node = head
    while let n = node {
        nums.append(n.value)
        node = n.next
    }
    return buildBst(nums, 0, nums.count - 1)
}

private func buildBst(_ nums: [Int], _ left: Int, _ right: Int) -> TreeNode<Int>? {
    guard left <= right else { return nil }
    
    let mid = left + (right - left) / 2
    let node = TreeNode(nums[mid])
    
    node.left = buildBst(nums, left, mid - 1)
    node.right = buildBst(nums, mid + 1, right)
    
    return node
}
