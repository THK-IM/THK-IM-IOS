//
//  IMImageMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation
import RxSwift
import CocoaLumberjack

open class IMImageMsgProcessor : IMBaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.IMAGE.rawValue
    }
    
    open override func getSessionDesc(msg: Message) -> String {
        return "[Image]"
    }
    
    open override func reprocessingObservable(_ message: Message) -> Observable<Message>? {
        do {
            if message.data == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let storageModule = IMCoreManager.shared.storageModule
            var imageData = try JSONDecoder().decode(
                IMImageMsgData.self,
                from: message.data!.data(using: .utf8) ?? Data()
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
        return ImageCompressor.Options(maxSize: 100*1024, quality: 0.9)
    }
    
    open func compress(_ storageModule: StorageModule, _ imageData: inout IMImageMsgData, _ entity: inout Message) throws {
        let path = storageModule.sandboxFilePath(imageData.path!)
        let originImage = UIImage.init(contentsOfFile: path)
        imageData.width = Int(originImage!.size.width)
        imageData.height = Int(originImage!.size.height)
        let (_, fileName) = storageModule.getPathsFromFullPath(path)
        let (name, ext) = storageModule.getFileExt(fileName)
        let thumbName = "\(name)_thumb.\(ext)"
        let thumbPath = storageModule.allocSessionFilePath(
            entity.sessionId,
            thumbName,
            IMFileFormat.Image.rawValue
        )
        try ImageCompressor.compressImageFile(path, thumbPath, getImageCompressorOptions())
        imageData.thumbnailPath = thumbPath
        let d = try JSONEncoder().encode(imageData)
        entity.data = String(data: d, encoding: .utf8)!
    }
    
    
    open override func uploadObservable(_ entity: Message) -> Observable<Message>? {
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
            
            if entity.data == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            
            let imageData = try JSONDecoder().decode(
                IMImageMsgData.self,
                from: entity.data!.data(using: .utf8) ?? Data()
            )
            guard var thumbPath = imageData.thumbnailPath else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            thumbPath = storageModule.sandboxFilePath(thumbPath)
            let (_, thumbName) = storageModule.getPathsFromFullPath(thumbPath)
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoadListener(
                    {[weak self] progress, state, url, path, err in
                        SwiftEventBus.post(
                            IMEvent.MsgLoadStatusUpdate.rawValue,
                            sender: IMLoadProgress(IMLoadType.Upload.rawValue, url, path, state, progress)
                        )
                        switch(state) {
                        case
                            FileLoadState.Wait.rawValue,
                            FileLoadState.Init.rawValue,
                            FileLoadState.Ing.rawValue:
                            break
                        case FileLoadState.Success.rawValue:
                            do {
                                imageBody.thumbnailUrl = url
                                imageBody.width = imageData.width
                                imageBody.height = imageData.height
                                imageBody.name = thumbName
                                let d = try JSONEncoder().encode(imageBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                try self?.insertOrUpdateDb(entity, false, false) 
                                observer.onNext(entity)
                                observer.onCompleted()
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            break
                        case
                            FileLoadState.Failed.rawValue:
                            if (err != nil) {
                                observer.onError(err!)
                            } else {
                                observer.onError(CocoaError.init(.executableLoad))
                            }
                            break
                        default:
                            break
                        }
                    },
                    {
                        return false
                    })
                fileLoadModule.upload(path: thumbPath, message: entity, loadListener: loadListener)
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
            
            if entity.data == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            
            let imageData = try JSONDecoder().decode(
                IMImageMsgData.self,
                from: entity.data!.data(using: .utf8) ?? Data()
            )
            guard var originPath = imageData.path else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            originPath = storageModule.sandboxFilePath(originPath)
            let (_, originName) = storageModule.getPathsFromFullPath(originPath)
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoadListener(
                    {progress, state, url, path, err in
                        SwiftEventBus.post(
                            IMEvent.MsgLoadStatusUpdate.rawValue,
                            sender: IMLoadProgress(IMLoadType.Upload.rawValue, url, path, state, progress)
                        )
                        switch(state) {
                        case
                            FileLoadState.Wait.rawValue,
                            FileLoadState.Init.rawValue,
                            FileLoadState.Ing.rawValue:
                            break
                        case
                            FileLoadState.Success.rawValue:
                            do {
                                imageBody.url = url
                                imageBody.width = imageData.width
                                imageBody.height = imageData.height
                                imageBody.name = originName
                                let d = try JSONEncoder().encode(imageBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                observer.onNext(entity)
                                observer.onCompleted()
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            break
                        case
                            FileLoadState.Failed.rawValue:
                            if (err != nil) {
                                observer.onError(err!)
                            } else {
                                observer.onError(CocoaError.init(.executableLoad))
                            }
                            break
                        default:
                            break
                        }
                    },
                    {
                        return false
                    }
                )
                fileLoadModule.upload(path: originPath, message: entity, loadListener: loadListener)
                return Disposables.create()
            })
        } catch {
            DDLogError(error)
            return Observable.error(error)
        }
    }
    
    open override func downloadMsgContent(_ message: Message, resourceType: String) -> Bool {
        do {
            var data = IMImageMsgData()
            if (message.data != nil) {
                data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data()
                )
            }
            var body = IMImageMsgBody()
            if (message.content != nil) {
                body = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data()
                )
            } else {
                return false
            }
            
            var downloadUrl: String? = nil
            if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                downloadUrl = body.thumbnailUrl
            } else {
                downloadUrl = body.url
            }
            
            if downloadUrl == nil || body.name == nil {
                return false
            } 
            
            var fileName = body.name
            if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                fileName = "thumb_\(body.name!)"
            } else {
                downloadUrl = body.url
            }
            
            if (downloadUrls.contains(downloadUrl!)) {
                return true
            } else {
                downloadUrls.append(downloadUrl!)
            }
            
            let localPath = IMCoreManager.shared.storageModule.allocSessionFilePath(
                message.sessionId, fileName!, IMFileFormat.Image.rawValue)
            let loadListener = FileLoadListener(
                {[weak self] progress, state, url, path, err in
                    SwiftEventBus.post(
                        IMEvent.MsgLoadStatusUpdate.rawValue,
                        sender: IMLoadProgress(IMLoadType.Download.rawValue, url, path, state, progress)
                    )
                    switch(state) {
                    case
                        FileLoadState.Wait.rawValue,
                        FileLoadState.Init.rawValue,
                        FileLoadState.Ing.rawValue:
                        break
                    case
                        FileLoadState.Success.rawValue:
                        do {
                            if (!FileManager.default.fileExists(atPath: localPath)) {
                                try IMCoreManager.shared.storageModule.copyFile(path, localPath)
                                if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                                    data.thumbnailPath = localPath
                                } else {
                                    data.path = localPath
                                }
                                data.width = body.width!
                                data.height = body.height!
                                let d = try JSONEncoder().encode(data)
                                message.data = String(data: d, encoding: .utf8)!
                                try self?.insertOrUpdateDb(message, true, false)
                            }
                            
                        } catch {
                            DDLogError(error)
                        }
                        self?.downloadUrls.removeAll(where: { it in
                            return it == downloadUrl!
                        })
                        break
                    case FileLoadState.Failed.rawValue:
                        self?.downloadUrls.removeAll(where: { it in
                            return it == downloadUrl!
                        })
                        break
                    default:
                        break
                    }
                },
                {
                    return false
                }
            )
            IMCoreManager.shared.fileLoadModule.download(key: downloadUrl!, message: message, loadListener: loadListener)
        } catch {
            DDLogError(error)
        }
        
        return true
    }
    
}



