//
//  VideoMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import RxSwift
import CocoaLumberjack
import SwiftEventBus
import AVFoundation

class VideoMsgProcessor : BaseMsgProcessor {
    
    override func messageType() -> Int {
        return MsgType.VIDEO.rawValue
    }
    
    override func getSessionDesc(msg: Message) -> String {
        return "[video]"
    }
    
    override func reprocessingObservable(_ message: Message) -> Observable<Message>? {
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
            DDLogInfo(error)
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
        videoData.duration = Int(asset.duration.seconds) + 1
        
        let d = try JSONEncoder().encode(videoData)
        entity.data = String(data: d, encoding: .utf8)!
    }
    
    
    override func uploadObservable(_ entity: Message) -> Observable<Message> {
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
            let uploadKey = IMCoreManager.shared.fileLoadModule.getUploadKey(
                entity.sessionId, entity.fromUId, thumbName, entity.id
            )
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoadListener(
                    {[weak self] progress, state, url, path in
                        switch(state) {
                        case
                            FileLoadState.Wait.rawValue,
                            FileLoadState.Init.rawValue,
                            FileLoadState.Ing.rawValue:
                            SwiftEventBus.post(
                                IMEvent.MsgLoadStatusUpdate.rawValue,
                                sender: IMLoadProgress(IMLoadType.Upload.rawValue, uploadKey, state, progress)
                            )
                        case FileLoadState.Success.rawValue:
                            do {
                                videoBody.thumbnailUrl = url
                                videoBody.name = thumbName
                                let d = try JSONEncoder().encode(videoBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                try self?.insertOrUpdateDb(entity, false) // 插入数据库不更新ui,防止数据丢失
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
                    path: realThumbPath,
                    loadListener: loadListener
                )
                return Disposables.create()
            })
        } catch {
            DDLogError(error)
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
            let uploadKey = IMCoreManager.shared.fileLoadModule.getUploadKey(
                entity.sessionId, entity.fromUId, originName, entity.id
            )
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoadListener(
                    {progress, state, url, path in
                        SwiftEventBus.post(
                            IMEvent.MsgLoadStatusUpdate.rawValue,
                            sender: IMLoadProgress(IMLoadType.Upload.rawValue, uploadKey, state, progress)
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
                    path: realVideoPath,
                    loadListener: loadListener
                )
                return Disposables.create()
            })
        } catch {
            DDLogError(error)
            return Observable.error(error)
        }
    }
    
    override func downloadMsgContent(_ message: Message, resourceType: String) {
        Observable<Message>.create({observer -> Disposable in
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
                }

                var downloadUrl: String? = nil
                let fileName = body.name
                if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                    downloadUrl = body.thumbnailUrl
                } else {
                    downloadUrl = body.url
                }
                if downloadUrl == nil || fileName == nil {
                    observer.onError(CocoaError(.fileNoSuchFile))
                } else {
                    let localPath = IMCoreManager.shared.storageModule.allocSessionFilePath(
                        message.sessionId, fileName!, IMFileFormat.Image.rawValue)
                    let loadListener = FileLoadListener(
                        {progress, state, url, path in
                            SwiftEventBus.post(
                                IMEvent.MsgLoadStatusUpdate.rawValue,
                                sender: IMLoadProgress(IMLoadType.Download.rawValue, url, state, progress)
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
                                    if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                                        data.thumbnailPath = path
                                    } else {
                                        data.path = path
                                    }
                                    data.duration = body.duration
                                    data.width = body.width!
                                    data.height = body.height!
                                    let d = try JSONEncoder().encode(data)
                                    message.data = String(data: d, encoding: .utf8)!
                                    observer.onNext(message)
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
                    _ = IMCoreManager.shared.fileLoadModule.download(
                        key: downloadUrl!,
                        path: localPath,
                        loadListener: loadListener
                    )
                }
            } catch {
                DDLogError(error)
                observer.onError(error)
            }
            
            return Disposables.create()
        })
        .compose(RxTransformer.shared.io2Io())
        .subscribe(onNext: { msg in
            do {
                try self.insertOrUpdateDb(msg, true, false)
            } catch let error {
                DDLogError(error)
            }
        }, onError: { error in
            DDLogError(error)
        })
        .disposed(by: disposeBag)
    }
    

    
}
