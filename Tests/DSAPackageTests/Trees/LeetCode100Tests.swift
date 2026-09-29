//
//  LeetCode100Tests.swift
//  DSAPackageTests
//

import XCTest
@testable import DSAPackage

final class LeetCode100Tests: XCTestCase {

    func testBothTreesNil() {
        XCTAssertTrue(LeetCode100.isSameTree(nil, nil))
    }

    func testOneTreeNilOtherNot() {
        let p = TreeNode(1)
        XCTAssertFalse(LeetCode100.isSameTree(p, nil))
        XCTAssertFalse(LeetCode100.isSameTree(nil, p))
    }

    func testIdenticalSingleNodeTrees() {
        let p = TreeNode(1)
        let q = TreeNode(1)
        XCTAssertTrue(LeetCode100.isSameTree(p, q))
    }

    func testDifferentValuesSameStructure() {
        let p = TreeNode(1)
        let q = TreeNode(2)
        XCTAssertFalse(LeetCode100.isSameTree(p, q))
    }

    func testIdenticalTrees() {
        // Both:   1
        //        / \
        //       2   3
        let p = TreeNode(1, left: TreeNode(2), right: TreeNode(3))
        let q = TreeNode(1, left: TreeNode(2), right: TreeNode(3))
        XCTAssertTrue(LeetCode100.isSameTree(p, q))
    }

    func testDifferentStructureSameValues() {
        //   p: 1        q: 1
        //     /              \
        //    2                2
        let p = TreeNode(1, left: TreeNode(2))
        let q = TreeNode(1, right: TreeNode(2))
        XCTAssertFalse(LeetCode100.isSameTree(p, q))
    }

    func testDifferentValueDeepInTree() {
        // p:      1           q:      1
        //        / \                 / \
        //       2   3               2   4
        let p = TreeNode(1, left: TreeNode(2), right: TreeNode(3))
        let q = TreeNode(1, left: TreeNode(2), right: TreeNode(4))
        XCTAssertFalse(LeetCode100.isSameTree(p, q))
    }
}
