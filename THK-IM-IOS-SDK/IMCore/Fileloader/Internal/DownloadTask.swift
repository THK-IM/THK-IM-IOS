//
//  DownloadTask.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import Alamofire
import CocoaLumberjack

class DownloadTask: LoadTask {
    
    private var request: DownloadRequest?
    private let key: String
    private let downLoadParam: String
    private let tmpFilePath: String
    private let filePath: String
    private let fileModuleReference: WeakReference<DefaultFileLoadModule>
    
    init(fileModule: DefaultFileLoadModule, key: String, downLoadParam: String) {
        self.fileModuleReference = WeakReference(value: fileModule)
        self.key = key
        self.downLoadParam = downLoadParam
        let hashUrl = key.sha1Hash
        self.tmpFilePath = fileModule.cacheDirPath + "/\(hashUrl).tmp"
        self.filePath = fileModule.cacheDirPath + "/\(hashUrl)"
    }
    
    func start() {
        if (FileManager.default.fileExists(atPath: self.filePath)) {
            notify(progress: 100, state: FileLoadState.Success.rawValue)
            return
        }
        if (FileManager.default.fileExists(atPath: self.tmpFilePath)) {
            do {
                try FileManager.default.removeItem(atPath: self.tmpFilePath)
            } catch {
                notify(progress: 0, state: FileLoadState.Failed.rawValue, err: error)
                return
            }
        }
        guard let fileLoadModule = self.fileModuleReference.value else {
            notify(progress: 0, state: FileLoadState.Failed.rawValue, err: CocoaError.init(.executableNotLoadable))
            return
        }
        let tempFileURL = NSURL(fileURLWithPath: tmpFilePath) as URL
        let fileUrl = NSURL(fileURLWithPath: self.filePath) as URL
        self.notify(progress: 0, state: FileLoadState.Init.rawValue)
        let redirector = Redirector(behavior: .modify({ [weak self] task, request, response  -> URLRequest? in
            guard let location = response.headers["Location"] else {
                return nil
            }
            guard let fileLoadModule = self?.fileModuleReference.value else {
                return nil
            }
            do {
                var newRequest = try request.asURLRequest()
                newRequest.url = URL.init(string: location)
                if location.hasPrefix(fileLoadModule.endpoint) {
                    if request.headers[APITokenInterceptor.tokenKey] == nil || request.headers[APITokenInterceptor.tokenKey] == "" {
                        newRequest.addValue(fileLoadModule.token, forHTTPHeaderField: APITokenInterceptor.tokenKey)
                    }
                } else {
                    newRequest.setValue(nil, forHTTPHeaderField: APITokenInterceptor.tokenKey)
                }
                return newRequest
            } catch {
                return nil
            }
        }))
        var headers = HTTPHeaders()
        var realUrl = self.key
        if (!self.key.hasSuffix("http")) {
            realUrl = "\(fileLoadModule.endpoint)/session/object/download_url?\(downLoadParam)"            
            headers.add(name: "Token", value: fileLoadModule.token)
        }
        self.request = AF.download(
            realUrl, headers: headers,
            to: { _, response in
                return (tempFileURL, [.removePreviousFile, .createIntermediateDirectories])
            }).redirect(using: redirector)
        .downloadProgress(queue: DispatchQueue.global()) { [weak self] progress in
                guard let sf = self else {
                    return
                }
                let p: Int = Int(100 * progress.completedUnitCount / progress.totalUnitCount)
                sf.notify(progress: p, state: FileLoadState.Ing.rawValue)
            }
        .validate(statusCode: 200..<300)
            .response(queue: DispatchQueue.global()) { [weak self] response in
                guard let sf = self else {
                    return
                }
                switch response.result {
                case .success:
                    if FileManager.default.fileExists(atPath: sf.tmpFilePath) {
                        do {
                            try FileManager.default.moveItem(at: tempFileURL, to: fileUrl)
                            sf.notify(progress: 100, state: FileLoadState.Success.rawValue)
                        } catch {
                            sf.notify(progress: 100, state: FileLoadState.Failed.rawValue, err: error)
                        }
                    } else {
                        sf.notify(progress: 100, state: FileLoadState.Failed.rawValue, err: CocoaError.init(CocoaError.fileNoSuchFile))
                    }
                    break
                case let .failure(err):
                    sf.notify(progress: 0, state: FileLoadState.Failed.rawValue, err: err)
                    break
                }
            }
    }
    
    func cancel() {
        if (self.request != nil) {
            if (!self.request!.isCancelled && !self.request!.isFinished) {
                self.request!.cancel()
            }
        }
    }
    
    func notify(progress: Int, state: Int, err: Error? = nil) {
        guard let fileLoadModule = self.fileModuleReference.value else {
            return
        }
        if (state == FileLoadState.Success.rawValue) {
            fileLoadModule.notifyListeners(progress: progress, state: state, url: self.key, path: self.filePath, err: err)
        } else {
            fileLoadModule.notifyListeners(progress: progress, state: state, url: self.key, path: "", err: err)
        }
    }
    
}

