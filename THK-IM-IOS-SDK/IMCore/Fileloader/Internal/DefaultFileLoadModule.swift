//
//  DefaultFileLoadModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/29.
//  Copyright © 2023 THK. All rights reserved.
//

import CocoaLumberjack
import Foundation

public class DefaultFileLoadModule: FileLoadModule {

    private let cacheExpire: TimeInterval = 10 * 24 * 3600 * 1000  // ms
    private var downloadTaskMap = [String: (LoadTask, [FileLoadListener])]()
    private var uploadTaskMap = [String: (LoadTask, [FileLoadListener])]()
    private let lock = NSLock()
    var token: String
    var endpoint: String
    var cacheDirPath: String

    public init(_ token: String, _ endpoint: String) {
        self.token = token
        self.endpoint = endpoint
        cacheDirPath = NSTemporaryDirectory() + "/message_cache"
        var isDir: ObjCBool = false
        let exist = FileManager.default.fileExists(atPath: cacheDirPath, isDirectory: &isDir)
        if exist {
            if !isDir.boolValue {
                do {
                    try FileManager.default.removeItem(atPath: cacheDirPath)
                    try FileManager.default.createDirectory(
                        atPath: cacheDirPath, withIntermediateDirectories: true)
                } catch {
                    DDLogError("DefaultFileLoadModule init \(error)")
                }
            }
        } else {
            do {
                try FileManager.default.createDirectory(
                    atPath: cacheDirPath, withIntermediateDirectories: true)
            } catch {
                DDLogError("DefaultFileLoadModule init \(error)")
            }
        }

        guard let subFiles = FileManager.default.subpaths(atPath: cacheDirPath) else {
            return
        }

        do {
            let timeZone = NSTimeZone.system
            let interval: TimeInterval = TimeInterval(timeZone.secondsFromGMT())
            for f in subFiles {
                let attributes = try FileManager.default.attributesOfFileSystem(
                    forPath: "\(cacheDirPath)/\(f)")
                let modificationDate = attributes[FileAttributeKey.modificationDate]
                if modificationDate != nil {
                    let localModDate = (modificationDate as! NSDate).addingTimeInterval(interval)
                    if abs(localModDate.timeIntervalSince1970 - Date().timeIntervalSince1970)
                        > cacheExpire
                    {
                        try FileManager.default.removeItem(atPath: f)
                    }
                }
            }
        } catch {
            DDLogError("DefaultFileLoadModule init \(error)")
        }

    }

    private func buildDownloadParam(_ key: String, _ message: Message) -> String {
        if key.hasSuffix("http") {
            return ""
        } else {
            return "id=\(key)"
        }
    }

    private func buildUploadParam(_ path: String, _ message: Message) -> String {
        let (_, fileName) = IMCoreManager.shared.storageModule.getPathsFromFullPath(path)
        return
            "s_id=\(message.sessionId)&u_id=\(message.fromUId)&f_name=\(fileName)&client_id=\(message.id)"
    }

    public func download(key: String, message: Message, loadListener: FileLoadListener) {
        lock.lock()
        var taskTuple = downloadTaskMap[key]
        lock.unlock()
        if taskTuple == nil {
            let downloadParam = self.buildDownloadParam(key, message)
            let dTask = DownloadTask(fileModule: self, key: key, downLoadParam: downloadParam)
            downloadTaskMap[key] = (dTask, [loadListener])
            dTask.start()
        } else {
            taskTuple?.1.append(loadListener)
        }
    }

    public func upload(path: String, message: Message, loadListener: FileLoadListener) {
        lock.lock()
        var taskTuple = uploadTaskMap[path]
        lock.unlock()
        if taskTuple == nil {
            let uploadParam = self.buildUploadParam(path, message)
            let dTask = UploadTask(fileModule: self, path: path, param: uploadParam)
            dTask.start()
            lock.lock()
            uploadTaskMap[path] = (dTask, [loadListener])
            lock.unlock()
        } else {
            taskTuple?.1.append(loadListener)
        }
    }

    public func cancelDownload(url: String) {
        lock.lock()
        var taskTuple = downloadTaskMap[url]
        lock.unlock()
        if taskTuple != nil {
            taskTuple!.1.removeAll()
            taskTuple!.0.cancel()
            downloadTaskMap.removeValue(forKey: url)
        }
    }

    public func cancelDownloadListener(url: String, listener: FileLoadListener) {
        lock.lock()
        var taskTuple = downloadTaskMap[url]
        lock.unlock()
        taskTuple?.1.removeAll(where: { $0 == listener })
    }

    public func cancelUpload(path: String) {
        lock.lock()
        var taskTuple = uploadTaskMap[path]
        lock.unlock()
        if taskTuple != nil {
            taskTuple!.0.cancel()
            taskTuple!.1.removeAll()
            uploadTaskMap.removeValue(forKey: path)
        }
    }

    public func cancelUploadListener(path: String, listener: FileLoadListener) {
        lock.lock()
        var taskTuple = uploadTaskMap[path]
        lock.unlock()
        taskTuple?.1.removeAll(where: { $0 == listener })
    }

    public func notifyListeners(progress: Int, state: Int, url: String, path: String, err: Error?) {
        lock.lock()
        let downloadTaskTuple = downloadTaskMap[url]
        lock.unlock()
        if downloadTaskTuple != nil {
            for listener in downloadTaskTuple!.1 {
                if listener.notifyOnUiThread() {
                    DispatchQueue.main.async {
                        listener.notifyProgress(progress, state, url, path, err)
                    }
                } else {
                    DispatchQueue.global().async {
                        listener.notifyProgress(progress, state, url, path, err)
                    }
                }
            }
            if state == FileLoadState.Failed.rawValue || state == FileLoadState.Success.rawValue {
                cancelDownload(url: url)
            }
        }
        lock.lock()
        let uploadTaskTuple = uploadTaskMap[path]
        lock.unlock()
        if uploadTaskTuple != nil {
            for listener in uploadTaskTuple!.1 {
                if listener.notifyOnUiThread() {
                    DispatchQueue.main.async {
                        listener.notifyProgress(progress, state, url, path, err)
                    }
                } else {
                    DispatchQueue.global().async {
                        listener.notifyProgress(progress, state, url, path, err)
                    }
                }
            }
            if state == FileLoadState.Failed.rawValue || state == FileLoadState.Success.rawValue {
                cancelUpload(path: path)
            }
        }
    }

    public func reset() {
        lock.lock()
        for (k, _) in downloadTaskMap {
            var taskTuple = downloadTaskMap[k]
            taskTuple?.0.cancel()
            taskTuple?.1.removeAll()
        }
        downloadTaskMap.removeAll()

        for (k, _) in uploadTaskMap {
            var taskTuple = uploadTaskMap[k]
            taskTuple?.0.cancel()
            taskTuple?.1.removeAll()
        }
        uploadTaskMap.removeAll()
        lock.unlock()
    }
}
