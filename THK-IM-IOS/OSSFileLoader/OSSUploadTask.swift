//
//  OSSUploadTask.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation
import AliyunOSSiOS

class OSSUploadTask: OSSLoadTask {
    
    private var request: OSSPutObjectRequest?
    override func notify(progress: Int, state: Int) {
        guard let fileLoadModule = self.fileModuleReference.value else {
            return
        }
        let fullUrl = "https://\(fileLoadModule.oSsBucket).\(fileLoadModule.oSsEndpoint)/\(url)"
        fileModuleReference.value?.notifyListeners(taskId: taskId, progress: progress, state: state, url: fullUrl, path: path)
        
    }
    
    override func start() {
        super.start()
        self.notify(progress: 0, state: FileLoaderState.Init.rawValue)
        guard let fileLoadModule = self.fileModuleReference.value else {
            self.notify(progress: 0, state: FileLoaderState.Failed.rawValue)
            return
        }
        request = OSSPutObjectRequest()
        request?.bucketName = fileLoadModule.oSsBucket
        request?.objectKey = self.url
        
        let (_ , ext) = IMCoreManager.shared.storageModule.getFileExt(self.path)
        let mimeType = MimeType.shared.mimeType(pathExtension: ext)
        request?.contentType = mimeType
        request?.uploadingFileURL = URL.init(fileURLWithPath: self.path)
        request?.uploadProgress = { [weak self]
            (bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
            let p: Int = Int(100 * totalBytesSent / totalBytesExpectedToSend)
            self?.notify(progress: p, state: FileLoaderState.Ing.rawValue)
        }
        let client = fileLoadModule.oSsClient
        let putTask = client.putObject(request!)
        putTask.continue({ [weak self] (t) -> Any? in
            if (t.error == nil) {
                self?.notify(progress: 100, state: FileLoaderState.Success.rawValue)
            } else {
                self?.notify(progress: 0, state: FileLoaderState.Failed.rawValue)
            }
            return nil
        })
    }
    
    override func cancel() {
        super.cancel()
        if (self.request != nil) {
            if (!self.request!.isCancelled) {
                self.request!.cancel()
            }
        }
    }
    
}
