//
//  GCDTool.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/20.
//

import Foundation

public typealias GCDTask = (_ cancel: Bool) -> Void

public class GCDTool: NSObject {

    @discardableResult static public func gcdDelay(_ time: TimeInterval, task: @escaping () -> Void)
        -> GCDTask?
    {

        func dispatch_later(block: @escaping () -> Void) {
            let t = DispatchTime.now() + time
            DispatchQueue.global().asyncAfter(deadline: t, execute: block)
        }

        var closure: (() -> Void)? = task
        var result: GCDTask?

        let delayedClosure: GCDTask = {
            cancel in
            if let closure = closure {
                if !cancel {
                    DispatchQueue.main.async(execute: closure)
                }
            }
            closure = nil
            result = nil
        }

        result = delayedClosure

        dispatch_later {
            if let result = result {
                result(false)
            }
        }

        return result
    }

    public static func gcdCancel(_ task: GCDTask?) {
        task?(true)
    }
}
