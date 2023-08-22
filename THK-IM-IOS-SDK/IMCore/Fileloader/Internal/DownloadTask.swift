//
//  DownloadTask.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation
import Alamofire
import CocoaLumberjack

class DownloadTask : FileTask {
    
    private var request: DownloadRequest?
    private var resumeData: Data?
    
    override func start() {
        let tempFilePath = self.path + ".tmp"
        let tempFileURL = NSURL(fileURLWithPath: tempFilePath) as URL
        let fileUrl = NSURL(fileURLWithPath: self.path) as URL
        self.notify(progress: 0, state: FileLoaderState.Init.rawValue)
        if self.resumeData != nil {
            self.request = AF.download(resumingWith: self.resumeData!, to: { _, response in
                return (tempFileURL, [.removePreviousFile, .createIntermediateDirectories])
            }).downloadProgress(queue: DispatchQueue.global()) { [weak self] progress in
                    guard let sf = self else {
                        return
                    }
                    let p: Int = Int(100 * progress.completedUnitCount / progress.totalUnitCount)
                    sf.notify(progress: p, state: FileLoaderState.Ing.rawValue)
                }
                .response { [weak self] response in
                    guard let sf = self else {
                        return
                    }
                    switch response.result {
                    case .success:
                        if !FileManager.default.fileExists(atPath: sf.path) {
                            do {
                                try FileManager.default.moveItem(at: tempFileURL, to: fileUrl)
                                sf.notify(progress: 100, state: FileLoaderState.Success.rawValue)
                            } catch {
                                sf.notify(progress: 100, state: FileLoaderState.Failed.rawValue)
                                DDLogError(error)
                            }
                        } else {
                            sf.notify(progress: 100, state: FileLoaderState.Failed.rawValue)
                        }
                        break
                    case .failure(_):
                        sf.resumeData = response.resumeData
                        sf.notify(progress: 0, state: FileLoaderState.Failed.rawValue)
                        break
                    }
                }
        } else {
            self.request = AF.download(url, to: { _, response in
                return (tempFileURL, [.removePreviousFile, .createIntermediateDirectories])
            }).downloadProgress(queue: DispatchQueue.global()) { [weak self] progress in
                    guard let sf = self else {
                        return
                    }
                    let p: Int = Int(100 * progress.completedUnitCount / progress.totalUnitCount)
                    sf.notify(progress: p, state: FileLoaderState.Ing.rawValue)
                }
                .response { [weak self] response in
                    guard let sf = self else {
                        return
                    }
                    switch response.result {
                    case .success:
                        if !FileManager.default.fileExists(atPath: sf.path) {
                            do {
                                try FileManager.default.moveItem(at: tempFileURL, to: fileUrl)
                                sf.notify(progress: 100, state: FileLoaderState.Success.rawValue)
                            } catch {
                                sf.notify(progress: 100, state: FileLoaderState.Failed.rawValue)
                                DDLogError(error)
                            }
                        } else {
                            sf.notify(progress: 100, state: FileLoaderState.Failed.rawValue)
                        }
                        break
                    case .failure(_):
                        sf.resumeData = response.resumeData
                        sf.notify(progress: 0, state: FileLoaderState.Failed.rawValue)
                        break
                    }
                }
        }
        
    }
    
    override func cancel() {
        if (self.request != nil) {
            if (!self.request!.isCancelled) {
                self.request!.cancel()
            }
        }
    }
    
}
