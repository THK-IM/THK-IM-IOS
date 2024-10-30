//
//  IMLiveCacheQueue.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public struct IMLiveCacheQueue<T> {
    
    fileprivate var array = [T?]()
    fileprivate var head = 0
    private let locker = NSLock()

    public var isEmpty : Bool {
        locker.lock()
        defer {locker.unlock()}
        return count == 0
    }
    
    public var count: Int {
        locker.lock()
        defer {locker.unlock()}
        return array.count - head
    }

    public mutating func enqueue(_ element: T) {
        locker.lock()
        defer {locker.unlock()}
        array.append(element)
    }

    public mutating func dequeue() -> T? {
        locker.lock()
        defer {locker.unlock()}
        guard head < array.count, let element = array[head] else { return nil }

        array[head] = nil
        head += 1

        let percentage = Double(head)/Double(array.count)
        if array.count > 50 && percentage > 0.25 {
            array.removeFirst(head)
            head = 0
        }

        return element
    }
    
    public mutating func clear() {
        locker.lock()
        defer {locker.unlock()}
        head = 0
        array.removeAll()
    }

    public var front: T? {
        locker.lock()
        defer {locker.unlock()}
        if isEmpty {
            return nil
        } else {
            return array[head]
        }
    }
    
}

