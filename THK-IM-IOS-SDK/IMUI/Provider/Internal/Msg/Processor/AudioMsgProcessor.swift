//
//  AudioMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import Foundation
import RxSwift
import CocoaLumberjack
import SwiftEventBus

class AudioMsgProcessor : BaseMsgProcessor {
    
    override func messageType() -> Int {
        return MsgType.Audio.rawValue
    }
    
    override func getSessionDesc(msg: Message) -> String {
        return "[Audio]"
    }
    
    override func reprocessingObservable(_ message: Message) -> Observable<Message>? {
        do {
            if (message.data == nil) {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let storageModule = IMCoreManager.shared.storageModule
            var audioData = try JSONDecoder().decode(
                IMAudioMsgData.self,
                from: message.data!.data(using: .utf8) ?? Data()
            )
            if audioData.path == nil || audioData.duration == nil  {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            var entity = message
            // 1 检查文件所在目录，如果非IM目录，拷贝到IM目录下
            try self.checkDir(storageModule, &audioData, &entity)
    
            return Observable.just(entity)
        } catch {
            DDLogInfo(error)
            return Observable.error(error)
        }
    }
    
    private func checkDir(_ storageModule: StorageModule, _ audioData: inout IMAudioMsgData, _ entity: inout Message) throws {
        let realPath = storageModule.sandboxFilePath(audioData.path!)
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
                IMFileFormat.Audio.rawValue
            )
            try storageModule.copyFile(realPath, dePath)
            audioData.path = dePath
            let d = try JSONEncoder().encode(audioData)
            entity.data = String(data: d, encoding: .utf8)!
        }
    }
    
    override func uploadObservable(_ entity: Message) -> Observable<Message> {
        return self.uploadAudio(entity)
    }
    
    func uploadAudio(_ entity: Message) -> Observable<Message> {
        do {
            var audioBody = IMAudioMsgBody()
            if (entity.content != nil) {
                audioBody = try JSONDecoder().decode(
                    IMAudioMsgBody.self,
                    from: entity.content!.data(using: .utf8) ?? Data()
                )
            }
            if (audioBody.url != nil) {
                return Observable.just(entity)
            }
            
            let fileLoadModule = IMCoreManager.shared.fileLoadModule
            let storageModule = IMCoreManager.shared.storageModule
            if (entity.data == nil) {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let audioData = try JSONDecoder().decode(
                IMAudioMsgData.self,
                from: entity.data!.data(using: .utf8) ?? Data()
            )
            if audioData.path == nil || audioData.duration == nil  {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let realPath = storageModule.sandboxFilePath(audioData.path!)
            let (_, name) = storageModule.getPathsFromFullPath(realPath)
            
            let uploadKey = fileLoadModule.getUploadKey(
                entity.sessionId,
                entity.fromUId,
                name,
                entity.id
            )
            
            return Observable.create({observer -> Disposable in
                let loaderListener = FileLoadListener(
                    { progress, state, url, path in
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
                                audioBody.url = url
                                audioBody.name = name
                                audioBody.duration = audioData.duration!
                                let content = try JSONEncoder().encode(audioBody)
                                entity.content = String(data: content, encoding: .utf8)!
                                entity.sendStatus = MsgSendStatus.Sending.rawValue
                                observer.onNext(entity)
                                observer.onCompleted()
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            break
                        default:
                            observer.onError(CocoaError.init(.coderInvalidValue))
                            break
                        }
                    },
                    {
                        return false
                    }
                )
                _ = fileLoadModule.upload(
                    key: uploadKey,
                    path: realPath,
                    loadListener: loaderListener
                )
                return Disposables.create()
            })
        } catch {
            DDLogError(error)
            return Observable.error(error)
        }
    }
    
    
    override func downloadMsgContent(_ message: Message, resourceType: String) -> Bool {
        do {
            var data = IMAudioMsgData()
            if (message.data != nil) {
                data = try JSONDecoder().decode(
                    IMAudioMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data()
                )
            }
            var body = IMAudioMsgBody()
            if (message.content != nil) {
                body = try JSONDecoder().decode(
                    IMAudioMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data()
                )
            }
            var downloadUrl: String? = nil
            let fileName = body.name
            if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                downloadUrl = body.url
            } else {
                downloadUrl = body.url
            }
            if downloadUrl == nil || fileName == nil {
                return false
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
                                data.path = path
                                data.duration = body.duration
                                let d = try JSONEncoder().encode(data)
                                message.data = String(data: d, encoding: .utf8)!
                                try self.insertOrUpdateDb(message, true, false)
                            } catch {
                                DDLogError(error)
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
                _ = IMCoreManager.shared.fileLoadModule.download(
                    key: downloadUrl!,
                    path: localPath,
                    loadListener: loadListener
                )
            }
        } catch {
            DDLogError(error)
        }
        return true
    }
    
}
