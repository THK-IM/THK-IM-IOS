//
//  IMVideoMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import RxSwift
import CocoaLumberjack
import AVFoundation

open class IMVideoMsgProcessor : IMBaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.Video.rawValue
    }
    
    open override func msgDesc(msg: Message) -> String {
        return ResourceUtils.loadString("im_video_msg", comment: "")
    }
    
    open override func reprocessingObservable(_ message: Message) -> Observable<Message>? {
        do {
            if message.data == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let storageModule = IMCoreManager.shared.storageModule
            var videoData = try JSONDecoder().decode(
                IMVideoMsgData.self,
                from: message.data!.data(using: .utf8) ?? Data()
            )
            if videoData.path == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            var entity = message
            // 1 检查文件所在目录，如果非IM目录，拷贝到IM目录下
            try self.checkDir(storageModule, &videoData, &entity)
            
            // 2 如果缩略图不存在，抽帧
            if videoData.thumbnailPath == nil {
                try self.extractVideoFrame(storageModule, &videoData, &entity)
            }
            return Observable.just(entity)
        } catch {
            DDLogError("\(error)")
            return Observable.error(error)
        }
    }
    
    private func checkDir(_ storageModule: StorageModule, _ videoData: inout IMVideoMsgData, _ entity: inout Message) throws {
        let realPath = storageModule.sandboxFilePath(videoData.path!)
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
                IMFileFormat.Video.rawValue
            )
            try storageModule.copyFile(realPath, dePath)
            videoData.path = dePath
            let d = try JSONEncoder().encode(videoData)
            entity.data = String(data: d, encoding: .utf8)!
        }
    }
    
    open func getImageCompressorOptions() -> ImageCompressor.Options {
        return ImageCompressor.Options(maxSize: 100*1024, quality: 0.6)
    }
    
    open func extractVideoFrame(_ storageModule: StorageModule, _ videoData: inout IMVideoMsgData, _ entity: inout Message) throws {
        let path = storageModule.sandboxFilePath(videoData.path!)
        // 从视频文件中解析第一帧图片
        let asset = AVURLAsset(url: NSURL.fileURL(withPath: path))
        let imageGenerator = AVAssetImageGenerator.init(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(1, preferredTimescale: 60)
        var actualTime: CMTime = CMTimeMake(value: 0, timescale: 0)
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
        let frameImage = UIImage(cgImage: cgImage)
        guard let compressData = ImageCompressor.compressImage(
            frameImage,
            getImageCompressorOptions()
        ) else {
            throw CocoaError.error(CocoaError.executableLoad)
        }
        
        let (_, fileName) = storageModule.getPathsFromFullPath(path)
        let (name, _) = storageModule.getFileExt(fileName)
        let coverThumbName = "\(Date().timeIntervalSince1970/1000)_\(name)_cover.jpeg"
        let coverThumbPath = storageModule.allocSessionFilePath(
            entity.sessionId,
            coverThumbName,
            IMFileFormat.Image.rawValue
        )
        try storageModule.saveMediaDataInto(coverThumbPath, compressData.toData())
        
        videoData.thumbnailPath = coverThumbPath
        videoData.width = Int(frameImage.size.width)
        videoData.height = Int(frameImage.size.height)
        videoData.duration = Int(asset.duration.seconds)
        
        let d = try JSONEncoder().encode(videoData)
        entity.data = String(data: d, encoding: .utf8)!
    }
    
    
    open override func uploadObservable(_ entity: Message) -> Observable<Message> {
        let storageModule = IMCoreManager.shared.storageModule
        let fileLoadModule = IMCoreManager.shared.fileLoadModule
        return self.uploadCover(fileLoadModule, storageModule, entity)
            .flatMap({ (msg) -> Observable<Message> in
                return self.uploadVideo(fileLoadModule, storageModule, msg)
            })
    }
    
    open func uploadCover(_ fileLoadModule: FileLoadModule, _ storageModule: StorageModule,
                               _ entity: Message) -> Observable<Message> {
        do {
            var videoBody = IMVideoMsgBody()
            if (entity.content != nil) {
                videoBody = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: entity.content!.data(using: .utf8) ?? Data()
                )
            }
            if (videoBody.thumbnailUrl != nil) {
                return Observable.just(entity)
            }
            if entity.data == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let videoData = try JSONDecoder().decode(
                IMVideoMsgData.self,
                from: entity.data!.data(using: .utf8) ?? Data()
            )
            guard let thumbPath = videoData.thumbnailPath else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            
            let realThumbPath = storageModule.sandboxFilePath(thumbPath)
            let (_, thumbName) = storageModule.getPathsFromFullPath(realThumbPath)
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoadListener(
                    {[weak self] progress, state, url, path, err in
                        switch(state) {
                        case
                            FileLoadState.Wait.rawValue,
                            FileLoadState.Init.rawValue,
                            FileLoadState.Ing.rawValue:
                            SwiftEventBus.post(
                                IMEvent.MsgLoadStatusUpdate.rawValue,
                                sender: IMLoadProgress(IMLoadType.Upload.rawValue, url, path, state, progress)
                            )
                        case FileLoadState.Success.rawValue:
                            do {
                                videoBody.thumbnailUrl = url
                                videoBody.name = thumbName
                                let d = try JSONEncoder().encode(videoBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                try self?.insertOrUpdateDb(entity, false, false) 
                                observer.onNext(entity)
                                observer.onCompleted()
                            } catch {
                                DDLogError("\(error)")
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
                fileLoadModule.upload(path: realThumbPath, message: entity, loadListener: loadListener)
                return Disposables.create()
            })
        } catch {
            DDLogError("\(error)")
            return Observable.error(error)
        }
    }
    
    open func uploadVideo(_ fileLoadModule: FileLoadModule, _ storageModule: StorageModule,
                               _ entity: Message) -> Observable<Message> {
        do {
            var videoBody = IMVideoMsgBody()
            if (entity.content != nil) {
                videoBody = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: entity.content!.data(using: .utf8) ?? Data()
                )
            }
            if (videoBody.url != nil) {
                return Observable.just(entity)
            }
            if entity.data == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let videoData = try JSONDecoder().decode(
                IMVideoMsgData.self,
                from: entity.data!.data(using: .utf8) ?? Data()
            )
            guard let videoPath = videoData.path else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let realVideoPath = storageModule.sandboxFilePath(videoPath)
            let (_, originName) = storageModule.getPathsFromFullPath(realVideoPath)
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
                                videoBody.url = url
                                videoBody.name = originName
                                videoBody.width = videoData.width!
                                videoBody.height = videoData.height!
                                videoBody.duration = videoData.duration!
                                let d = try JSONEncoder().encode(videoBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                observer.onNext(entity)
                                observer.onCompleted()
                            } catch {
                                DDLogError("\(error)")
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
                fileLoadModule.upload(path: realVideoPath, message: entity, loadListener: loadListener)
                return Disposables.create()
            })
        } catch {
            DDLogError("\(error)")
            return Observable.error(error)
        }
    }
    
    open override func downloadMsgContent(_ message: Message, resourceType: String) -> Bool {
        do {
            var data = IMVideoMsgData()
            if (message.data != nil) {
                data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data()
                )
            }
            var body = IMVideoMsgBody()
            if (message.content != nil) {
                body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
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
            
            if (downloadUrls.contains(downloadUrl!)) {
                return true
            } else {
                downloadUrls.append(downloadUrl!)
            }
            
            var fileName = body.name!
            if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                fileName = "cover_\(body.name!).jpeg"
            }
            
            let localPath = IMCoreManager.shared.storageModule.allocSessionFilePath(
                message.sessionId, fileName, IMFileFormat.Image.rawValue)
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
                                data.duration = body.duration
                                data.width = body.width!
                                data.height = body.height!
                                let d = try JSONEncoder().encode(data)
                                message.data = String(data: d, encoding: .utf8)!
                                try self?.insertOrUpdateDb(message, true, false)
                            }
                        } catch {
                            DDLogError("\(error)")
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
            DDLogError("\(error)")
        }
        return true;
    }
    

    
}
