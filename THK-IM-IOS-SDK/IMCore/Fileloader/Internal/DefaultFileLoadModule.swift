//
//  DefaultFileLoadModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import CocoaLumberjack


class DefaultFileLoadModule: FileLoadModule {
    
    private var downloadTaskMap = [String: (LoadTask, Array<FileLoadListener>)]()
    private var uploadTaskMap = [String: (LoadTask, Array<FileLoadListener>)]()
    private let lock = NSLock()
    var token: String
    var endpoint: String
    
    init(_ token: String, _ endpoint: String) {
        self.token = token
        self.endpoint = endpoint
    }
    
    
    func getTaskId(key: String, path: String, type: String) -> String {
        return "\(type)/\(key)/\(path)"
    }
    
    func getUploadKey(_ sId: Int64, _ uId: Int64, _ fileName: String, _ msgClientId: Int64) -> String {
        return "im/session_\(sId)/\(uId)/\(msgClientId)_\(fileName)"
    }
    
    func parserUploadKey(key: String) -> (Int64, Int64, String)? {
        let paths = key.split(separator: "/")
        if (paths.count != 4) {
            return nil
        }
        let sessions = paths[1].split(separator: "_")
        if (sessions.count != 2) {
            return nil
        }
        guard let sessionId = Int64(sessions[1]) else {
            return nil
        }
        guard let uId = Int64(paths[2]) else {
            return nil
        }
        return (sessionId, uId, String(paths[3]))
    }
    
    func download(key: String, path: String, loadListener: FileLoadListener) -> String {
        lock.lock()
        defer {lock.unlock()}
        let taskId = self.getTaskId(key: key, path: path, type: "download")
        var taskTuple = downloadTaskMap[taskId]
        if (taskTuple == nil) {
            let dTask = DownloadTask(taskId: taskId, path: path, url: key, fileModule: self)
            dTask.start()
            downloadTaskMap[taskId] = (dTask, [loadListener])
        } else {
            taskTuple?.1.append(loadListener)
        }
        return taskId
    }
    
    func upload(key: String, path: String, loadListener: FileLoadListener) -> String {
        lock.lock()
        defer {lock.unlock()}
        let taskId = self.getTaskId(key: key, path: path, type: "upload")
        var taskTuple = uploadTaskMap[taskId]
        if (taskTuple == nil) {
            let dTask = UploadTask(taskId: taskId, path: path, url: key, fileModule: self)
            dTask.start()
            uploadTaskMap[taskId] = (dTask, [loadListener])
        } else {
            taskTuple?.1.append(loadListener)
        }
        return taskId
    }
    
    func cancelDownload(taskId: String) {
        lock.lock()
        defer {lock.unlock()}
        var taskTuple = downloadTaskMap[taskId]
        if taskTuple != nil {
            taskTuple!.0.cancel()
            taskTuple!.1.removeAll()
            downloadTaskMap.removeValue(forKey: taskId)
        }
    }
    
    func cancelDownloadListener(taskId: String, listener: FileLoadListener) {
        lock.lock()
        defer {lock.unlock()}
        var taskTuple = downloadTaskMap[taskId]
        taskTuple?.1.removeAll(where: { $0 == listener })
    }
    
    func cancelAllDownloadListeners(taskId: String) {
        lock.lock()
        defer {lock.unlock()}
        var taskTuple = downloadTaskMap[taskId]
        if taskTuple != nil {
            taskTuple!.1.removeAll()
            downloadTaskMap.removeValue(forKey: taskId)
        }
    }
    
    func cancelUpload(taskId: String) {
        lock.lock()
        defer {lock.unlock()}
        var taskTuple = uploadTaskMap[taskId]
        if taskTuple != nil {
            taskTuple!.0.cancel()
            taskTuple!.1.removeAll()
            uploadTaskMap.removeValue(forKey: taskId)
        }
    }
    
    func cancelUploadListener(taskId: String, listener: FileLoadListener) {
        lock.lock()
        defer {lock.unlock()}
        var taskTuple = uploadTaskMap[taskId]
        taskTuple?.1.removeAll(where: { $0 == listener })
    }
    
    func cancelAllUploadListeners(taskId: String) {
        lock.lock()
        defer {lock.unlock()}
        var taskTuple = uploadTaskMap[taskId]
        if taskTuple != nil {
            taskTuple!.1.removeAll()
            uploadTaskMap.removeValue(forKey: taskId)
        }
    }
    
    func notifyListeners(
        taskId: String,
        progress: Int,
        state: Int,
        url: String,
        path: String
    ) {
        let downloadTaskTuple = downloadTaskMap[taskId]
        if (downloadTaskTuple != nil) {
            for listener in downloadTaskTuple!.1 {
                if listener.notifyOnUiThread() {
                    DispatchQueue.main.async {
                        listener.notifyProgress(progress, state, url, path)
                    }
                } else {
                    listener.notifyProgress(progress, state, url, path)
                }
            }
            if (state == FileLoadState.Failed.rawValue || state == FileLoadState.Success.rawValue) {
                cancelDownload(taskId: taskId)
            }
        }
        
        let uploadTaskTuple = uploadTaskMap[taskId]
        if (uploadTaskTuple != nil) {
            for listener in uploadTaskTuple!.1 {
                if listener.notifyOnUiThread() {
                    DispatchQueue.main.async {
                        listener.notifyProgress(progress, state, url, path)
                    }
                } else {
                    listener.notifyProgress(progress, state, url, path)
                }
            }
            if (state == FileLoadState.Failed.rawValue || state == FileLoadState.Success.rawValue) {
                cancelUpload(taskId: taskId)
            }
        }
    }
    
}
