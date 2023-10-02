//
//  UploadTask.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import Alamofire

class UploadTask: LoadTask {
    
    private var getParamsRequest: DataRequest?
    private var uploadRequest: DataRequest?
    private var keyUrl: String?
    
    override func notify(progress: Int, state: Int) {
        guard let fileLoadModule = self.fileModuleReference.value else {
            return
        }
        var url = self.url
        if (self.keyUrl != nil) {
            url = self.keyUrl!
        }
        fileLoadModule.notifyListeners(taskId: taskId, progress: progress, state: state, url: url, path: path)
        
    }
    
    override func start() {
        super.start()
        self.notify(progress: 0, state: FileLoadState.Init.rawValue)
        guard let fileLoadModule = self.fileModuleReference.value else {
            self.notify(progress: 0, state: FileLoadState.Failed.rawValue)
            return
        }
        var headers = HTTPHeaders()
        headers.add(name: "Token", value: fileLoadModule.token)
        guard let params = fileLoadModule.parserUploadKey(key: self.url) else {
            self.notify(progress: 0, state: FileLoadState.Failed.rawValue)
            return
        }
        let url = "\(fileLoadModule.endpoint)/object/upload_params?s_id=\(params.0)&u_id=\(params.1)&f_name=\(params.2)"
        self.getParamsRequest = AF.request(url, headers: headers).responseData(queue: DispatchQueue.global())
        { [weak self] response in
            guard let sf = self else {
                return
            }
            switch response.result {
            case .success:
                if response.data == nil {
                    sf.notify(progress: 0, state: FileLoadState.Failed.rawValue)
                }
                do {
                    let uploadParams = try JSONDecoder().decode(
                        UploadParams.self,
                        from: response.data!
                    )
                    sf.startUpload(params: uploadParams, fileName: params.2)
                } catch {
                    sf.notify(progress: 0, state: FileLoadState.Failed.rawValue)
                }
                break
            default:
                sf.notify(progress: 0, state: FileLoadState.Failed.rawValue)
                break
            }
            return
        }
    }
    
    private func startUpload(params: UploadParams, fileName: String) {
        let fileExisted = FileManager.default.isReadableFile(atPath: path)
        if (!fileExisted) {
            self.notify(progress: 0, state: FileLoadState.Failed.rawValue)
            return
        }
        guard let fileLoadModule = self.fileModuleReference.value else {
            self.notify(progress: 0, state: FileLoadState.Failed.rawValue)
            return
        }
        let method = HTTPMethod(rawValue: params.method)
        self.uploadRequest = AF.upload(
            multipartFormData: { [weak self] multipartFormData in
                guard let sf = self else {
                    return
                }
                for (k, v) in params.params {
                    multipartFormData.append(v.data(using: .utf8)!, withName: k)
                }
                let fileUrl = URL.init(fileURLWithPath: sf.path)
                multipartFormData.append(fileUrl, withName: "file")
                
            },
            to: params.url,
            method: method
        ).uploadProgress(queue: DispatchQueue.global()) { [weak self] progress in
            guard let sf = self else {
                return
            }
            let p: Int = Int(100 * progress.completedUnitCount / progress.totalUnitCount)
            sf.notify(progress: p, state: FileLoadState.Ing.rawValue)
        }.responseData(queue: DispatchQueue.global()) { [weak self] response in
            guard let sf = self else {
                return
            }
            switch response.result {
            case .success:
                sf.keyUrl = "\(fileLoadModule.endpoint)/object/\(params.id)"
                sf.notify(progress: 100, state: FileLoadState.Success.rawValue)
                break
            case .failure:
                sf.notify(progress: 0, state: FileLoadState.Failed.rawValue)
                break
            }
            return
        }
    }
    
    override func cancel() {
        super.cancel()
        if (self.getParamsRequest != nil) {
            if (!self.getParamsRequest!.isCancelled && !self.getParamsRequest!.isFinished) {
                self.getParamsRequest!.cancel()
            }
        }
        
        if (self.uploadRequest != nil) {
            if (!self.uploadRequest!.isCancelled && !self.uploadRequest!.isFinished) {
                self.uploadRequest!.cancel()
            }
        }
    }
}
