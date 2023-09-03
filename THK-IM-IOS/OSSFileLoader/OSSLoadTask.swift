//
//  OSSLoadTask.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation
import CocoaLumberjack

class OSSLoadTask{
    
    let taskId: String
    let path: String
    let url: String
    let fileModuleReference: WeakReference<OSSFileLoadModule>
    
    init(taskId : String, path: String, url: String, fileModule: OSSFileLoadModule) {
        self.taskId = taskId
        self.path = path
        self.url = url
        self.fileModuleReference = WeakReference(value: fileModule)
    }
    
    func start() {
        
    }
    
    func cancel() {
        
    }
    
    func notify(progress: Int, state: Int) {
        fileModuleReference.value?.notifyListeners(
            taskId: taskId, progress: progress, state: state, url: url, path: path)
    }
}
