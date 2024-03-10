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
    private let path: String
    private let param: String
    private weak var fileModule: DefaultFileLoadModule?
    private var running = true
    
    init(fileModule: DefaultFileLoadModule, path: String, param: String) {
        self.fileModule = fileModule
        self.path = path
        self.param = param
    }
    
    func start() {
        self.notify(progress: 0, state: FileLoadState.Init.rawValue)
        guard let fileLoadModule = self.fileModule else {
            self.notify(progress: 0, state: FileLoadState.Failed.rawValue)
            return
        }
        var headers = HTTPHeaders()
        headers.add(name: APITokenInterceptor.tokenKey, value: fileLoadModule.token)
        headers.add(name: APITokenInterceptor.deviceKey, value: AppUtils.getDeviceName())
        headers.add(name: APITokenInterceptor.timezoneKey, value: AppUtils.getTimezone())
        headers.add(name: APITokenInterceptor.versionKey, value: AppUtils.getVersion())
        headers.add(name: APITokenInterceptor.platformKey, value: "IOS")
        let url = "\(fileLoadModule.endpoint)/session/object/upload_params?\(self.param)"
        self.getParamsRequest = AF.request(url, headers: headers).responseData(queue: DispatchQueue.global())
        { [weak self] response in
            guard let sf = self else {
                return
            }
            switch response.result {
            case .success:
                if response.data == nil {
                    sf.notify(progress: 0, state: FileLoadState.Failed.rawValue, err: CocoaError.init(CocoaError.coderValueNotFound))
                }
                do {
                    let uploadParams = try JSONDecoder().decode(
                        UploadParams.self,
                        from: response.data!
                    )
                    sf.startUpload(params: uploadParams)
                } catch {
                    sf.notify(progress: 0, state: FileLoadState.Failed.rawValue, err: CocoaError.init(CocoaError.formatting))
                }
                break
            case let .failure(err):
                sf.notify(progress: 0, state: FileLoadState.Failed.rawValue, err: err)
                break
            }
            return
        }
    }
    
    private func startUpload(params: UploadParams) {
        if (!self.running) {
            self.notify(progress: 0, state: FileLoadState.Failed.rawValue, err: nil)
            return
        }
        let fileExisted = FileManager.default.isReadableFile(atPath: path)
        if (!fileExisted) {
            self.notify(progress: 0, state: FileLoadState.Failed.rawValue, err: CocoaError(.fileNoSuchFile))
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
                sf.keyUrl = "\(params.id)"
                sf.notify(progress: 100, state: FileLoadState.Success.rawValue)
                break
            case let .failure (err):
                sf.notify(progress: 0, state: FileLoadState.Failed.rawValue, err: err)
                break
            }
            return
        }
    }
    
    func cancel() {
        running = false
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
    
    
    
    func notify(progress: Int, state: Int, err: Error? = nil) {
        guard let fileLoadModule = self.fileModule else {
            return
        }
        var url = ""
        if (self.keyUrl != nil) {
            url = self.keyUrl!
        }
        fileLoadModule.notifyListeners(progress: progress, state: state, url: url, path: path, err: err)
        
    }
}
