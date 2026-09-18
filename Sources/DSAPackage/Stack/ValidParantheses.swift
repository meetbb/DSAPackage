//
//  File.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 18/09/26.
//

import Foundation

// This is a LeetCode: 20 Valid Parantheses problem which uses a Matching Stack as Optimal Solution.

func isValid(_ s: String) -> Bool {
    var stack: [Character] = []
    let pairs: [Character: Character] = [")": "(", "}": "{", "]": "["]
    
    for char in s {
        // First of all we will check if the char matches any one value of pairs
        if pairs.values.contains(char) {
            stack.append(char)
        } else if let match = pairs[char] {
            // Find the match. If Stack is empty or last popped does not match with the match variable.
            // return false – It is invalid parantheses
            if stack.isEmpty || stack.removeLast() != match {
                return false
            }
        }
    }
    
    return stack.isEmpty
}
