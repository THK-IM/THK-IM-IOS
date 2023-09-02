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
            guard let storageModule = IMCoreManager.shared.storageModule else {
                return Observable.error(CocoaError.init(.executableLoad))
            }
            var audioData = try JSONDecoder().decode(
                IMAudioData.self,
                from: message.data.data(using: .utf8) ?? Data()
            )
            if audioData.path == nil || audioData.duration == nil  {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            var entity = message
            // 1 检查文件所在目录，如果非IM目录，拷贝到IM目录下
            try self.checkDir(storageModule, &audioData, &entity)
            
            return Observable.just(message)
        } catch {
            DDLogInfo(error)
            return Observable.error(error)
        }
    }
    
    private func checkDir(_ storageModule: StorageModule, _ imageData: inout IMAudioData, _ entity: inout Message) throws {
        let isAssignedPath = storageModule.isAssignedPath(
            imageData.path!,
            IMFileFormat.Image.rawValue,
            entity.sessionId,
            entity.fromUId
        )
        let (_, name) = storageModule.getPathsFromFullPath(imageData.path!)
        if !isAssignedPath {
            let dePath = storageModule.allocSessionFilePath(
                entity.sessionId,
                IMCoreManager.shared.uId,
                name,
                IMFileFormat.Audio.rawValue
            )
            try storageModule.copyFile(imageData.path!, dePath)
            imageData.path = dePath
            let d = try JSONEncoder().encode(imageData)
            entity.data = String(data: d, encoding: .utf8)!
        }
    }
    
    override func uploadObservable(_ entity: Message) -> Observable<Message> {
        return self.uploadAudio(entity)
    }
    
    func uploadAudio(_ entity: Message) -> Observable<Message> {
        do {
            let audioBody = try JSONDecoder().decode(
                IMAudioMsgBody.self,
                from: entity.content.data(using: .utf8) ?? Data()
            )
            if audioBody.url == nil {
                return Observable.just(entity)
            }
            guard let fileLoadModule = IMCoreManager.shared.fileLoadModule else {
                return Observable.error(CocoaError.init(.executableLoad))
            }
            guard let storageModule = IMCoreManager.shared.storageModule else {
                return Observable.error(CocoaError.init(.executableLoad))
            }
            let audioData = try JSONDecoder().decode(
                IMAudioData.self,
                from: entity.data.data(using: .utf8) ?? Data()
            )
            if audioData.path == nil || audioData.duration == nil  {
                return Observable.error(CocoaError.init(.fileNoSuchFile))
            }
            let (_, name) = storageModule.getPathsFromFullPath(audioData.path!)
            
            let uploadKey = fileLoadModule.getUploadKey(
                entity.sessionId,
                entity.fromUId,
                name,
                entity.id
            )
            
            return Observable.create({observer -> Disposable in
                let loaderListener = FileLoaderListener(
                    { progress, state, url, path in
                        switch(state) {
                        case
                            FileLoaderState.Wait.rawValue,
                            FileLoaderState.Init.rawValue,
                            FileLoaderState.Ing.rawValue:
                            let progress = IMUploadProgress(uploadKey, state, progress)
                            SwiftEventBus.post(IMEvent.MsgUploadProgressUpdate.rawValue, sender: progress)
                            break
                        case
                            FileLoaderState.Success.rawValue:
                            do {
                                audioBody.url = url
                                audioBody.duration = audioData.duration
                                let content = try JSONEncoder().encode(audioBody)
                                entity.content = String(data: content, encoding: .utf8)!
                                entity.sendStatus = MsgSendStatus.Sending.rawValue
                                observer.onNext(entity)
                            } catch {
                                DDLogError(error)
                                observer.onError(error)
                            }
                            break
                        default:
                            observer.onError(CocoaError.init(.coderInvalidValue))
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
                    path: audioData.path!,
                    loadListener: loaderListener
                )
                return Disposables.create()
            })
        } catch {
            DDLogError(error)
            return Observable.error(error)
        }
    }
    
}
