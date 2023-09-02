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
            var entity = message
            let storageModule = IMCoreManager.shared.storageModule
            var videoData = try JSONDecoder().decode(
                IMVideoData.self,
                from: entity.data.data(using: .utf8) ?? Data()
            )
            if videoData.path == nil {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
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
    
    private func checkDir(_ storageModule: StorageModule, _ videoData: inout IMVideoData, _ entity: inout Message) throws {
        let isAssignedPath = storageModule.isAssignedPath(
            videoData.path!,
            IMFileFormat.Image.rawValue,
            entity.sessionId,
            entity.fromUId
        )
        let (_, name) = storageModule.getPathsFromFullPath(videoData.path!)
        if !isAssignedPath {
            let dePath = storageModule.allocSessionFilePath(
                entity.sessionId,
                IMCoreManager.shared.uId,
                name,
                IMFileFormat.Video.rawValue
            )
            try storageModule.copyFile(videoData.path!, dePath)
            videoData.path = dePath
            let d = try JSONEncoder().encode(videoData)
            entity.data = String(data: d, encoding: .utf8)!
        }
    }
    
    open func getImageCompressorOptions() -> ImageCompressor.Options {
        return ImageCompressor.Options(maxWidth: 160, maxHeight: 400, maxSize: 100*1024, quality: 0.9)
    }
    
    open func extractVideoFrame(_ storageModule: StorageModule, _ videoData: inout IMVideoData, _ entity: inout Message) throws {
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
        let (name, ext) = storageModule.getFileExt(fileName)
        let coverThumbName = "\(name)_thumb.\(ext)"
        let coverThumbPath = storageModule.allocSessionFilePath(
            entity.sessionId,
            entity.fromUId,
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
    
    
    override func uploadObservable(_ entity: Message) -> Observable<Message> {
        let storageModule = IMCoreManager.shared.storageModule
        let fileLoadModule = IMCoreManager.shared.fileLoadModule
        return self.uploadCover(fileLoadModule, storageModule, entity)
            .flatMap({ (msg) -> Observable<Message> in
                return self.uploadVideo(fileLoadModule, storageModule, msg)
            })
    }
    
    open func uploadCover(_ fileLoadModule: FileLoaderModule, _ storageModule: StorageModule,
                               _ entity: Message) -> Observable<Message> {
        do {
            let videoBody = try JSONDecoder().decode(
                IMVideoMsgBody.self,
                from: entity.content.data(using: .utf8) ?? Data()
            )
            if videoBody.url != nil {
                return Observable.just(entity)
            }
            let videoData = try JSONDecoder().decode(
                IMVideoData.self,
                from: entity.data.data(using: .utf8) ?? Data()
            )
            guard var thumbPath = videoData.thumbnailPath else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            thumbPath = storageModule.sandboxFilePath(thumbPath)
            let (_, thumbName) = storageModule.getPathsFromFullPath(thumbPath)
            let uploadKey = storageModule.allocSessionFilePath(
                entity.sessionId, entity.fromUId, thumbName, IMFileFormat.Image.rawValue)
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoaderListener(
                    {[weak self] progress, state, url, path in
                        switch(state) {
                        case
                            FileLoaderState.Wait.rawValue,
                            FileLoaderState.Init.rawValue,
                            FileLoaderState.Ing.rawValue:
                            let progress = IMUploadProgress(uploadKey, state, progress)
                            SwiftEventBus.post(IMEvent.MsgUploadProgressUpdate.rawValue, sender: progress)
                        case FileLoaderState.Success.rawValue:
                            do {
                                videoBody.thumbnailUrl = url
                                let d = try JSONEncoder().encode(videoBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                try self?.insertOrUpdateDb(entity, false) // 插入数据库不更新ui,防止数据丢失
                                observer.onNext(entity)
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            observer.onCompleted()
                            break
                        default:
                            observer.onError(CocoaError.init(.executableLoad))
                            observer.onCompleted()
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
    
    open func uploadVideo(_ fileLoadModule: FileLoaderModule, _ storageModule: StorageModule,
                               _ entity: Message) -> Observable<Message> {
        do {
            let videoBody = try JSONDecoder().decode(
                IMVideoMsgBody.self,
                from: entity.content.data(using: .utf8) ?? Data()
            )
            if videoBody.url != nil {
                return Observable.just(entity)
            }
            let videoData = try JSONDecoder().decode(
                IMVideoData.self,
                from: entity.data.data(using: .utf8) ?? Data()
            )
            guard var videoPath = videoData.path else {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            videoPath = storageModule.sandboxFilePath(videoPath)
            let (_, originName) = storageModule.getPathsFromFullPath(videoPath)
            let uploadKey = storageModule.allocSessionFilePath(
                entity.sessionId, entity.fromUId, originName, IMFileFormat.Video.rawValue)
            return Observable.create({ observer -> Disposable in
                let loadListener = FileLoaderListener(
                    {progress, state, url, path in
                        switch(state) {
                        case
                            FileLoaderState.Wait.rawValue,
                            FileLoaderState.Init.rawValue,
                            FileLoaderState.Ing.rawValue:
                            let progress = IMUploadProgress(uploadKey, state, progress)
                            SwiftEventBus.post(IMEvent.MsgUploadProgressUpdate.rawValue, sender: progress)
                        case
                            FileLoaderState.Success.rawValue:
                            do {
                                videoBody.url = url
                                videoBody.width = videoData.width
                                videoBody.height = videoData.height
                                videoBody.duration = videoData.duration
                                let d = try JSONEncoder().encode(videoBody)
                                entity.content = String(data: d, encoding: .utf8)!
                                observer.onNext(entity)
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            observer.onCompleted()
                            break
                        default:
                            observer.onError(CocoaError.init(.executableLoad))
                            observer.onCompleted()
                            break
                        }
                    },
                    {
                        return false
                    }
                )
                _ = fileLoadModule.upload(
                    key: uploadKey,
                    path: videoPath,
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
