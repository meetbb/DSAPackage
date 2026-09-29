//
//  DefaultTemplates.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 28/09/26.
//

import Foundation

enum DefaultTemplates {

    // MARK: Recursive inorder
    static func inorder(_ root: TreeNode<Int>?, _ result: inout [Int]) {
        guard let root else { return }
        inorder(root.left, &result)
        result.append(root.value)
        inorder(root.right, &result)
    }

    // MARK: Recursive preorder
    static func preorder(_ root: TreeNode<Int>?, _ result: inout [Int]) {
        guard let root else { return }
        result.append(root.value)
        preorder(root.left, &result)
        preorder(root.right, &result)
    }

    // MARK: Recursive postorder
    static func postorder(_ root: TreeNode<Int>?, _ result: inout [Int]) {
        guard let root else { return }
        postorder(root.left, &result)
        postorder(root.right, &result)
        result.append(root.value)
    }

    // MARK: Iterative inorder
    static func inorderIterative(_ root: TreeNode<Int>?) -> [Int] {
        var result = [Int]()
        var stack = [TreeNode<Int>]()
        var curr = root
        while curr != nil || !stack.isEmpty {
            while let node = curr {
                stack.append(node)
                curr = node.left
            }
            let node = stack.removeLast()
            result.append(node.value)
            curr = node.right
        }
        return result
    }

    // MARK: Iterative preorder
    static func preorderIterative(_ root: TreeNode<Int>?) -> [Int] {
        guard let root else { return [] }
        var result = [Int]()
        var stack = [root]

        while let node = stack.popLast() {
            result.append(node.value)
            if let r = node.right { stack.append(r) }
            if let l = node.left { stack.append(l) }
        }
        return result
    }

    // MARK: Iterative postorder
    static func postOrderIterative(_ root: TreeNode<Int>?) -> [Int] {
        guard let root else { return [] }
        var result = [Int]()
        var stack = [root]

        while let node = stack.popLast() {
            result.append(node.value)
            if let l = node.left {
                stack.append(l)
            }

            if let r = node.right {
                stack.append(r)
            }
        }
        return result.reversed()
    }


    // MARK: Level Order (BFS)
    static func levelOrder(_ root: TreeNode<Int>?) -> [[Int]] {
        guard let root else { return [] }
        var result = [[Int]]()
        var queue = [root]
        var head = 0

        while head < queue.count {
            let levelSize = queue.count - head
            var level = [Int]()
            for _ in 0..<levelSize {
                let node = queue[head]
                head += 1
                level.append(node.value)
                if let l = node.left {
                    queue.append(l)
                }

                if let r = node.right {
                    queue.append(r)
                }
            }
            result.append(level)
        }
        return result
    }

    // MARK: DFS Pattern A: bottom up (children return a value)
    /// Use when the answer for a node depends on the answers from its subtrees: height, diameter, balanced, max path sum, subtree checks
    static func maxDepthOfTree(_ root: TreeNode<Int>?) -> Int {
        guard let root else { return 0 }
        return 1 + max(maxDepthOfTree(root.left), maxDepthOfTree(root.right))
    }

    static func diameterOfBinaryTree(_ root: TreeNode<Int>?) -> Int {
        var best = 0
        func height(_ node: TreeNode<Int>?) -> Int {
            guard let node else { return 0 }
            let l = height(node.left)
            let r = height(node.right)
            best = max(best, l + r)
            return 1 + max(l, r)
        }
        _ = height(root)
        return best
    }

    // MARK: DFS pattern B: top-down approach
    static func isValidBST(_ root: TreeNode<Int>?) -> Bool {
        func validate(_ node: TreeNode<Int>?, _ low: Int?, _ high: Int?) -> Bool {
            guard let node else { return true }
            if let low, node.value <= low {
                return false
            }
            if let high, node.value >= high { return false }
            return validate(node.left, low, node.value) && validate(node.right, node.value, high)
        }
        return validate(root, nil, nil)
    }

    // MARK: Root-to-leaf path sum
    static func hasPathSum(_ root: TreeNode<Int>?, _ target: Int) -> Bool {
        guard let root else { return false }
        if root.left == nil && root.right == nil {
            return root.value == target
        }
        let remaining = target - root.value
        return hasPathSum(root.left, remaining) || hasPathSum(root.right, remaining)
    }
    
    // MARK: Collect all root-to-leaf paths (backtracking on a tree)
    static func allPaths(_ root: TreeNode<Int>?) -> [[Int]] {
        var result = [[Int]]()
        var path = [Int]()
        func dfs(_ node: TreeNode<Int>?) {
            guard let node else { return }
            path.append(node.value)
            if node.left == nil && node.right == nil {
                result.append(path)
            } else {
                dfs(node.left)
                dfs(node.right)
            }
            path.removeLast()
        }
        dfs(root)
        return result
    }
    
    // MARK: Lowest Common Ancestor
    static func lowestCommonAncestor(_ root: TreeNode<Int>?, _ p: TreeNode<Int>?, _ q: TreeNode<Int>?) -> TreeNode<Int>? {
        guard let root else { return nil }
        if root === p || root === q {
            return root
        }
        let left = lowestCommonAncestor(root.left, p, q)
        let right = lowestCommonAncestor(root.right, p, q)
        if left != nil && right != nil {
            return root
        }
        return left ?? right
    }
    
    // MARK: Use the ordering, O(h), no recursion needed
    static func lowestCommonAncestorBST(_ root: TreeNode<Int>?, _ p: TreeNode<Int>, _ q: TreeNode<Int>) -> TreeNode<Int>? {
        var node = root
        while let curr = node {
            if p.value < curr.value && q.value < curr.value {
                node = curr.left
            } else if p.value > curr.value && q.value > curr.value {
                node = curr.right
            } else {
                return curr
            }
        }
        return nil
    }
}
