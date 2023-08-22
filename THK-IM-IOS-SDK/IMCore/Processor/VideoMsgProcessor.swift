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
    
    private let format = "video"
    
    override func messageType() -> Int {
        return MsgType.VIDEO.rawValue
    }
    
    func contentToBody(_ content: String) -> VideoMsgBody? {
        do {
            let videoBody = try JSONDecoder().decode(
                VideoMsgBody.self,
                from: content.data(using: .utf8) ?? Data()
            )
            return videoBody
        } catch {
            DDLogError(error)
        }
        return nil
    }
    
    func bodyToContent(_ body: VideoMsgBody) -> String? {
        do {
            let d = try JSONEncoder().encode(body)
            let content = String(data: d, encoding: .utf8)
            return content
        } catch {
            DDLogError(error)
        }
        return nil
    }
    
    open func getImageCompressorOptions() -> ImageCompressor.Options {
        return ImageCompressor.Options(maxWidth: 300, maxHeight: 480, maxSize: 200*1024, quality: 0.9)
    }
    
    override func uploadObservable(_ entity: Message) -> Observable<Message>? {
        guard let videoBody = self.contentToBody(entity.content) else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        if (videoBody.path == nil) {
            return Observable.error(CocoaError.error(CocoaError.fileNoSuchFile))
        }
        if (videoBody.thumbnailPath == nil) {
            // 从视频文件中解析第一帧图片
            let realPath = IMCoreManager.shared.storageModule!.sandboxFilePath(videoBody.path!)
            let asset = AVURLAsset(url: NSURL.fileURL(withPath: realPath))
            videoBody.duration = Int(asset.duration.seconds)
            let imageGenerator = AVAssetImageGenerator.init(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTimeMakeWithSeconds(1, preferredTimescale: 60)
            var actualTime: CMTime = CMTimeMake(value: 0, timescale: 0)
            do {
                let cg_image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
                let image = UIImage(cgImage: cg_image)
                guard let compressData = ImageCompressor.compressImage(
                    image,
                    getImageCompressorOptions()
                ) else {
                    return Observable.error(CocoaError.error(CocoaError.executableLoad))
                }
                guard let coverImage = UIImage(data: compressData) else {
                    return Observable.error(CocoaError.error(CocoaError.executableLoad))
                }
                videoBody.height = Int(coverImage.size.height)
                videoBody.width = Int(coverImage.size.width)
                let fileName = "\(String().random(8))_cover.jpeg"
                let localPath = IMCoreManager.shared.storageModule?
                    .allocLocalFilePath(entity.sessionId, IMCoreManager.shared.uId, fileName, "img")
                try IMCoreManager.shared.storageModule?.saveMediaDataInto(localPath!, compressData)
                videoBody.thumbnailPath = localPath
                guard let newContent = self.bodyToContent(videoBody) else {
                    return Observable.error(CocoaError.error(CocoaError.executableLoad))
                }
                entity.content = newContent
                try updateMsgContent(entity, true)
            } catch {
                return Observable.error(error)
            }
        }
        if videoBody.thumbnailUrl != nil {
            return uploadVideo(entity)
        }
        return uploadThumbnail(entity).flatMap({ (msg) -> Observable<Message> in
            return self.uploadVideo(msg)
        })
    }
    
    func uploadThumbnail(_ entity: Message) -> Observable<Message> {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        guard let fileLoadModule = IMCoreManager.shared.fileLoadModule else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        guard let videoBody = self.contentToBody(entity.content) else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        let path = storageModule.sandboxFilePath(videoBody.thumbnailPath!)
        let (_, fileName) = storageModule.getPathsFromFullPath(path)
        let serverKey = storageModule.allocServerFilePath(entity.sessionId, entity.fromUId, fileName)
        
        return Observable.create({observer -> Disposable in
            let uploadListener = FileLoaderListener({ [weak self] progress, state, url, path in
                switch(state) {
                case FileLoaderState.Failed.rawValue:
                    observer.onError(Exception.IMError("\(path) upload \(url) error"))
                    observer.onCompleted()
                    break
                case FileLoaderState.Success.rawValue:
                    // url 放入本地数据库
                    do {
                        videoBody.thumbnailUrl = url
                        let d = try JSONEncoder().encode(videoBody)
                        entity.content = String(data: d, encoding: .utf8)!
                        try self?.updateMsgContent(entity, false)
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
            _ = fileLoadModule.upload(key: serverKey, path: path, loadListener: uploadListener)
            return Disposables.create()
        })
    }
    
    func uploadVideo(_ entity: Message) -> Observable<Message> {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        guard let fileLoadModule = IMCoreManager.shared.fileLoadModule else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        guard let videoBody = self.contentToBody(entity.content) else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        var path = storageModule.sandboxFilePath(videoBody.path!)
        var (_, fileName) = storageModule.getPathsFromFullPath(path)
        let isAssigned = storageModule.isAssignedPath(path, fileName, format, entity.sessionId, entity.fromUId)
        if !isAssigned {
            do {
                let dePath = storageModule.allocLocalFilePath(entity.sessionId, IMCoreManager.shared.uId, fileName, format)
                try storageModule.copyFile(path, dePath)
                videoBody.path = dePath
                let d = try JSONEncoder().encode(videoBody)
                entity.content = String(data: d, encoding: .utf8)!
                try updateMsgContent(entity, false)
                // 重新设置path/fileName/ext
                path = storageModule.sandboxFilePath(videoBody.path!)
                (_, fileName) = storageModule.getPathsFromFullPath(path)
            } catch {
                return Observable.error(CocoaError.error(CocoaError.executableLoad))
            }
        }
        let serverKey = storageModule.allocServerFilePath(entity.sessionId, entity.fromUId, fileName)
        return Observable.create({observer -> Disposable in
            let uploadListener = FileLoaderListener({ [weak self] progress, state, url, path in
                switch(state) {
                case FileLoaderState.Failed.rawValue:
                    observer.onError(Exception.IMError("\(path) upload \(url) error"))
                    observer.onCompleted()
                    break
                case FileLoaderState.Success.rawValue:
                    // url 放入本地数据库
                    do {
                        videoBody.url = url
                        let d = try JSONEncoder().encode(videoBody)
                        entity.content = String(data: d, encoding: .utf8)!
                        try self?.updateMsgContent(entity, false)
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
            _ = fileLoadModule.upload(key: serverKey, path: path, loadListener: uploadListener)
            return Disposables.create()
        })
    }
    
    override func getSessionDesc(msg: Message) -> String {
        return "[video]"
    }
    
}
