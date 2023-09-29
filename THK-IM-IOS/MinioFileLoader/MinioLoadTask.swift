//
//  MinioLoadTask.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

class MinioLoadTask {
    
    let taskId: String
    let path: String
    let url: String
    let fileModuleReference: WeakReference<MinioFileLoadModule>
    
    private var running = true
    
    init(taskId : String, path: String, url: String, fileModule: MinioFileLoadModule) {
        self.taskId = taskId
        self.path = path
        self.url = url
        self.fileModuleReference = WeakReference(value: fileModule)
    }
    
    func start() {
        
    }
    
    func cancel() {
        running = false
    }
    
    func notify(progress: Int, state: Int) {
        if (running) {
            fileModuleReference.value?.notifyListeners(
                taskId: taskId, progress: progress, state: state, url: url, path: path)
        }
    }
}

