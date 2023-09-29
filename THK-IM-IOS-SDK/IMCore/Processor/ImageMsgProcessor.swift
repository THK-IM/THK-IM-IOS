//
//  ImageMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation
import RxSwift
import CocoaLumberjack
import SwiftEventBus

class ImageMsgProcessor : BaseMsgProcessor {
    
    override func messageType() -> Int {
        return MsgType.IMAGE.rawValue
    }
    
    override func getSessionDesc(msg: Message) -> String {
        return "[Image]"
    }
    
    override func reprocessingObservable(_ message: Message) -> Observable<Message>? {
        do {
            let storageModule = IMCoreManager.shared.storageModule
            var imageData = try JSONDecoder().decode(
                IMImageMsgData.self,
                from: message.data.data(using: .utf8) ?? Data()
            )
            if imageData.path == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            var entity = message
            // 1 检查文件所在目录，如果非IM目录，拷贝到IM目录下
            try self.checkDir(storageModule, &imageData, &entity)
            
            // 2 如果缩略图不存在，压缩
            if imageData.thumbnailPath == nil {
                try self.compress(storageModule, &imageData, &entity)
            }
            return Observable.just(entity)
        } catch {
            DDLogInfo(error)
            return Observable.error(error)
        }
    }
    
    private func checkDir(_ storageModule: StorageModule, _ imageData: inout IMImageMsgData, _ entity: inout Message) throws {
        let realPath = storageModule.sandboxFilePath(imageData.path!)
        let isAssignedPath = storageModule.isAssignedPath(
            realPath,
            IMFileFormat.Image.rawValue,
            entity.sessionId
        )
        let (_, name) = storageModule.getPathsFromFullPath(realPath)
        if !isAssignedPath {
            let dePath = storageModule.allocSessionFilePath(
                entity.sessionId,
                name,
                IMFileFormat.Image.rawValue
            )
            try storageModule.copyFile(realPath, dePath)
            imageData.path = dePath
            let d = try JSONEncoder().encode(imageData)
            entity.data = String(data: d, encoding: .utf8)!
        }
    }
    
    open func getImageCompressorOptions() -> ImageCompressor.Options {
        return ImageCompressor.Options(maxWidth: 160, maxHeight: 400, maxSize: 100*1024, quality: 0.9)
    }
    
    open func compress(_ storageModule: StorageModule, _ imageData: inout IMImageMsgData, _ entity: inout Message) throws {
        let path = storageModule.sandboxFilePath(imageData.path!)
        let originImage = UIImage.init(contentsOfFile: path)
        if (originImage == nil) {
            throw CocoaError.init(CocoaError.fileReadNoSuchFile)
        }
        let (_, fileName) = storageModule.getPathsFromFullPath(path)
        let (name, ext) = storageModule.getFileExt(fileName)
        let thumbName = "\(name)_thumb.\(ext)"
        let thumbPath = storageModule.allocSessionFilePath(
            entity.sessionId,
            thumbName,
            IMFileFormat.Image.rawValue
        )
        guard let compressImage = ImageCompressor.compressImage(
            originImage!,
            getImageCompressorOptions()
        ) else {
            throw CocoaError.init(.executableLoad)
        }
        try storageModule.saveMediaDataInto(thumbPath, compressImage.toData())
        imageData.thumbnailPath = thumbPath
        imageData.width = Int(originImage!.size.width)
        imageData.height = Int(originImage!.size.height)
        
        let d = try JSONEncoder().encode(imageData)
        entity.data = String(data: d, encoding: .utf8)!
    }
    
    
    override func uploadObservable(_ entity: Message) -> Observable<Message>? {
        let storageModule = IMCoreManager.shared.storageModule
        let fileLoadModule = IMCoreManager.shared.fileLoadModule
        return self.uploadThumbImage(fileLoadModule, storageModule, entity)
            .flatMap({ (msg) -> Observable<Message> in
                return self.uploadOriginImage(fileLoadModule, storageModule, msg)
            })
    }
    
    open func uploadThumbImage(_ fileLoadModule: FileLoadModule, _ storageModule: StorageModule,
                               _ entity: Message) -> Observable<Message> {
        do {
            var imageBody = IMImageMsgBody()
            if (entity.content != nil) {
                imageBody = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: entity.content!.data(using: .utf8) ?? Data()
                )
            }
            if (imageBody.thumbnailUrl != nil) {
                return Observable.just(entity)
            }
            
            let imageData = try JSONDecoder().decode(
                IMImageMsgData.self,
                from: entity.data.data(using: .utf8) ?? Data()
            )
            guard var thumbPath = imageData.thumbnailPath else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            thumbPath = storageModule.sandboxFilePath(thumbPath)
            let (_, thumbName) = storageModule.getPathsFromFullPath(thumbPath)
            let uploadKey = IMCoreManager.shared.fileLoadModule.getUploadKey(
                entity.sessionId, entity.fromUId, thumbName, entity.id
            )
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoaderListener(
                    {[weak self] progress, state, url, path in
                        SwiftEventBus.post(
                            IMEvent.MsgLoadProgressUpdate.rawValue,
                            sender: IMUploadProgress(uploadKey, state, progress)
                        )
                        switch(state) {
                        case
                            FileLoaderState.Wait.rawValue,
                            FileLoaderState.Init.rawValue,
                            FileLoaderState.Ing.rawValue:
                            break
                        case FileLoaderState.Success.rawValue:
                            do {
                                imageBody.thumbnailUrl = url
                                imageBody.width = imageData.width!
                                imageBody.height = imageData.height!
                                let d = try JSONEncoder().encode(imageBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                try self?.insertOrUpdateDb(entity, false)
                                observer.onNext(entity)
                                observer.onCompleted()
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            break
                        default:
                            observer.onError(CocoaError.init(.executableLoad))
                            break
                        }
                    },
                    {
                        return false
                    })
                _ = fileLoadModule.upload(
                    key: uploadKey,
                    path: thumbPath,
                    loadListener: loadListener
                )
                return Disposables.create()
            })
        } catch {
            DDLogError(error)
            return Observable.error(error)
        }
    }
    
    open func uploadOriginImage(_ fileLoadModule: FileLoadModule, _ storageModule: StorageModule,
                               _ entity: Message) -> Observable<Message> {
        do {
            var imageBody = IMImageMsgBody()
            if (entity.content != nil) {
                imageBody = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: entity.content!.data(using: .utf8) ?? Data()
                )
            }
            if (imageBody.url != nil) {
                return Observable.just(entity)
            }
            
            let imageData = try JSONDecoder().decode(
                IMImageMsgData.self,
                from: entity.data.data(using: .utf8) ?? Data()
            )
            guard var originPath = imageData.path else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            originPath = storageModule.sandboxFilePath(originPath)
            let (_, originName) = storageModule.getPathsFromFullPath(originPath)
            let uploadKey = IMCoreManager.shared.fileLoadModule.getUploadKey(
                entity.sessionId, entity.fromUId, originName, entity.id
            )
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoaderListener(
                    {progress, state, url, path in
                        SwiftEventBus.post(
                            IMEvent.MsgLoadProgressUpdate.rawValue,
                            sender: IMUploadProgress(uploadKey, state, progress)
                        )
                        switch(state) {
                        case
                            FileLoaderState.Wait.rawValue,
                            FileLoaderState.Init.rawValue,
                            FileLoaderState.Ing.rawValue:
                            break
                        case
                            FileLoaderState.Success.rawValue:
                            do {
                                imageBody.url = url
                                imageBody.width = imageData.width!
                                imageBody.height = imageData.height!
                                let d = try JSONEncoder().encode(imageBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                observer.onNext(entity)
                                observer.onCompleted()
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            break
                        default:
                            observer.onError(CocoaError.init(.executableLoad))
                            break
                        }
                    },
                    {
                        return false
                    }
                )
                _ = fileLoadModule.upload(
                    key: uploadKey,
                    path: originPath,
                    loadListener: loadListener
                )
                return Disposables.create()
            })
        } catch {
            DDLogError(error)
            return Observable.error(error)
        }
    }
    
}
