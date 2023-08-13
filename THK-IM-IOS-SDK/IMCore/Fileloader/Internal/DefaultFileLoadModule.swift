//
//  DefaultFileLoadModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation
import AliyunOSSiOS
import CocoaLumberjack

class DefaultFileLoadModule: FileLoaderModule {
    
    private var downloadTaskMap = [String: (FileTask, Array<LoadListener>)]()
    private var uploadTaskMap = [String: (FileTask, Array<LoadListener>)]()
    private let lock = NSLock()
    
    let oSsBucket: String
    let oSsEndpoint: String
    let credentialProvider: OSSCredentialProvider
    let oSsClient: OSSClient
    
    init(_ oSsBucket: String, _ oSsEndpoint: String, _ credentialProvider: OSSCredentialProvider) {
        self.oSsBucket = oSsBucket
        self.oSsEndpoint = oSsEndpoint
        self.credentialProvider = credentialProvider
        self.oSsClient = OSSClient(endpoint: oSsEndpoint, credentialProvider: credentialProvider)
    }
    
    private func taskId(url: String, path: String, type: String) -> String {
        return "\(type)/\(url)/\(path)"
    }
    
    func download(url: String, path: String, loadListener: LoadListener) -> String {
        lock.lock()
        defer {lock.unlock()}
        let taskId = self.taskId(url: url, path: path, type: "download")
        var taskTuple = downloadTaskMap[taskId]
        if (taskTuple == nil) {
            let dTask = DownloadTask(taskId: taskId, path: path, url: url, fileModule: self)
            dTask.start()
            downloadTaskMap[taskId] = (dTask, [loadListener])
        } else {
            taskTuple?.1.append(loadListener)
        }
        return taskId
    }
    
    func upload(key: String, path: String, loadListener: LoadListener) -> String {
        lock.lock()
        defer {lock.unlock()}
        let taskId = self.taskId(url: key, path: path, type: "upload")
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
    
    func cancelDownloadListener(taskId: String, listener: LoadListener) {
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
    
    func cancelUploadListener(taskId: String, listener: LoadListener) {
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
        DDLogDebug("taskId: \(taskId), state: \(state), progress: \(progress)")
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
            if (state == LoadState.Failed.rawValue || state == LoadState.Success.rawValue) {
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
            if (state == LoadState.Failed.rawValue || state == LoadState.Success.rawValue) {
                cancelUpload(taskId: taskId)
            }
        }
    }
    
}
