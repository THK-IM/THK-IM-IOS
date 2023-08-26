//
//  THK-IM-IOSageMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation
import RxSwift
import CocoaLumberjack
import SwiftEventBus

class ImageMsgProcessor : BaseMsgProcessor {
    
    private let format = "img"
    
    override func messageType() -> Int {
        return MsgType.IMAGE.rawValue
    }
    
    override func uploadObservable(_ entity: Message) -> Observable<Message>? {
        guard let uploadShrinkImage = self.uploadShrinkImage(entity) else {
            return uploadOriginImage(entity)
        }
        return uploadShrinkImage.flatMap({ (msg) -> Observable<Message> in
            return self.uploadOriginImage(msg)!
        })
    }
    
    open func getImageCompressorOptions() -> ImageCompressor.Options {
        return ImageCompressor.Options(maxWidth: 160, maxHeight: 400, maxSize: 100*1024, quality: 0.9)
    }
    
    // 如需要上传缩略图，继承ImageMsgProcessor后，重写uploadShrinkImage方法即可
    open func uploadShrinkImage(_ entity: Message) -> Observable<Message>? {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        do {
            let imageBody = try JSONDecoder().decode(
                ImageMsgBody.self,
                from: entity.content.data(using: .utf8) ?? Data())
            if imageBody.shrinkUrl != nil {
                return Observable.just(entity)
            }
            if imageBody.shrinkPath == nil {
                let path = IMCoreManager.shared.storageModule?.sandboxFilePath(imageBody.path!)
                let originImage = UIImage.init(contentsOfFile: path!)
                if (originImage == nil) {
                    return Observable.error(CocoaError.init(CocoaError.fileReadNoSuchFile))
                }
                let (_, fileName) = storageModule.getPathsFromFullPath(imageBody.path!)
                let (name, ext) = storageModule.getFileExt(fileName)
                let thumbName = "\(name)_thumb.\(ext)"
                let thumbPath = storageModule.allocLocalFilePath(entity.sessionId, IMCoreManager.shared.uId, thumbName, format)
                guard let compressImage = ImageCompressor.compressImage(
                    originImage!,
                    getImageCompressorOptions()
                ) else {
                    return Observable.error(Exception.IMError("compress error"))
                }
                try storageModule.saveMediaDataInto(thumbPath, compressImage.toData())
                imageBody.shrinkPath = thumbPath
                let d = try JSONEncoder().encode(imageBody)
                entity.content = String(data: d, encoding: .utf8)!
                try updateDb(entity)
            }
            
            let (_, thumbName) = storageModule.getPathsFromFullPath(imageBody.shrinkPath!)
            let uploadKey = storageModule.allocServerFilePath(entity.sessionId, entity.fromUId, thumbName)
            
            let shrinkPath = IMCoreManager.shared.storageModule?.sandboxFilePath(imageBody.shrinkPath!)
            return Observable.create({observer -> Disposable in
                _ = IMCoreManager.shared.fileLoadModule?.upload(
                    key: uploadKey,
                    path: shrinkPath!,
                    loadListener: FileLoaderListener({ [weak self] progress, state, url, path in
                        switch(state) {
                        case FileLoaderState.Failed.rawValue:
                            observer.onError(Exception.IMError("\(path) upload \(url) error"))
                            observer.onCompleted()
                            break
                        case FileLoaderState.Success.rawValue:
                            // url 放入本地数据库
                            do {
                                imageBody.shrinkUrl = url
                                let d = try JSONEncoder().encode(imageBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                try self?.updateDb(entity)
                                observer.onNext(entity)
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            observer.onCompleted()
                            break
                        default:
                            break
                        }
                    }, {
                        return false
                    })
                )
                return Disposables.create()
            })
        } catch {
            return Observable.error(error)
        }
    }
    
    func uploadOriginImage(_ entity: Message) -> Observable<Message>? {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        do {
            let imageBody = try JSONDecoder().decode(
                ImageMsgBody.self,
                from: entity.content.data(using: .utf8) ?? Data())
            
            if imageBody.url != nil {
                return Observable.just(entity)
            }
            
            guard var fullPath = imageBody.path else {
                return Observable.error(CocoaError.error(CocoaError.fileNoSuchFile))
            }
            fullPath = (IMCoreManager.shared.storageModule?.sandboxFilePath(fullPath))!
            let (_, name) = storageModule.getPathsFromFullPath(fullPath)
            let isAssignedPath = storageModule.isAssignedPath(fullPath, name, format, entity.sessionId, entity.fromUId)
            if (!isAssignedPath) {
                let dePath = storageModule.allocLocalFilePath(entity.sessionId, IMCoreManager.shared.uId, name, format)
                try storageModule.copyFile(fullPath, dePath)
                imageBody.path = dePath
                let d = try JSONEncoder().encode(imageBody)
                entity.content = String(data: d, encoding: .utf8)!
                try self.updateDb(entity)
            }
            let path = IMCoreManager.shared.storageModule?.sandboxFilePath(imageBody.path!)
            let uploadKey = storageModule.allocServerFilePath(entity.sessionId, entity.fromUId, name)
            return Observable.create({observer -> Disposable in
                _ = IMCoreManager.shared.fileLoadModule?.upload(
                    key: uploadKey,
                    path: path!,
                    loadListener: FileLoaderListener({ [weak self] progress, state, url, path in
                        switch(state) {
                        case FileLoaderState.Failed.rawValue:
                            observer.onError(Exception.IMError("\(path) upload \(url) error"))
                            observer.onCompleted()
                            break
                        case FileLoaderState.Success.rawValue:
                            // url 放入本地数据库
                            do {
                                imageBody.url = url
                                let d = try JSONEncoder().encode(imageBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                try self?.updateDb(entity)
                                observer.onNext(entity)
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            observer.onCompleted()
                            break
                        default:
                            do {
                                let extData = try JSONEncoder().encode(ExtData(state, progress))
                                entity.extData = String(data: extData, encoding: .utf8)
                                SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: entity)
                            } catch {
                                DDLogError(error)
                            }
                            break
                        }
                    }, {
                        return false
                    })
                )
                return Disposables.create()
            })
        } catch {
            return Observable.error(error)
        }
    }
    
    override func getSessionDesc(msg: Message) -> String {
        return "[Image]"
    }
    
}
