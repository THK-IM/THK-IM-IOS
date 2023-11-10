//
//  FileLoadListener.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation
import CocoaLumberjack

typealias NotifyProgressBlock = (_ progress: Int, _ state: Int, _ url: String, _ path :String, _ err: Error?) -> Void
typealias NotifyOnUiThreadBlock = () -> Bool

public class FileLoadListener : NSObject {
    
    let notifyProgress: NotifyProgressBlock
    let notifyOnUiThread: NotifyOnUiThreadBlock
    
    init(_ notifyProgressBlock: @escaping NotifyProgressBlock, _ notifyOnUiThreadBlock: @escaping  NotifyOnUiThreadBlock) {
        self.notifyProgress = notifyProgressBlock
        self.notifyOnUiThread = notifyOnUiThreadBlock
    }
}
