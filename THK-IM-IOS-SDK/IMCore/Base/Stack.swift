//
//  Stack.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/16.
//  Copyright © 2024 THK. All rights reserved.
//
import Foundation

public class Stack<Element> {
    private var storage: [Element] = []
    
    public init() {}

    // 入栈
    public func push(_ element: Element) {
        storage.append(element)
    }

    // 出栈
    @discardableResult
    public func pop() -> Element? {
        return storage.popLast()
    }
    
    // 查看栈顶元素
    public func peek() -> Element? {
        return storage.last
    }
    
    // 检查栈是否为空
    public var isEmpty: Bool {
        return storage.isEmpty
    }
    
    // 获取栈的大小
    public var count: Int {
        return storage.count
    }
}
