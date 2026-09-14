//
//  BasicOperations.swift
//  DSAPackage
//
//  Created by Meet Brahmbhatt on 14/09/26.
//

import Foundation

struct Stack<T> {
    private var elements: [T] = []
    
    mutating func push(_ value: T) {
        elements.append(value)
    }
    
    @discardableResult
    mutating func pop() -> T? {
        elements.popLast()
    }
    
    func peek() -> T? {
        elements.last
    }
    
    var isEmpty: Bool {
        elements.isEmpty
    }
    
    var count: Int {
        elements.count
    }
}
