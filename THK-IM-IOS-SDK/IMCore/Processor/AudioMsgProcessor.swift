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
    
    private let format = "audio"
    
    override func messageType() -> Int {
        return MsgType.Audio.rawValue
    }
    
    override func uploadObservable(_ entity: Message) -> Observable<Message>? {
        return self.uploadAudio(entity)
    }
    
    open func uploadAudio(_ entity: Message) -> Observable<Message>? {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return Observable.error(CocoaError.error(CocoaError.executableLoad))
        }
        do {
            let audioBody = try JSONDecoder().decode(
                AudioMsgBody.self,
                from: entity.content.data(using: .utf8) ?? Data())
            if audioBody.url != nil {
                return Observable.just(entity)
            }
            guard var fullPath = audioBody.path else {
                return Observable.error(CocoaError.error(CocoaError.fileNoSuchFile))
            }
            fullPath = (IMCoreManager.shared.storageModule?.sandboxFilePath(fullPath))!
            let (_, name) = storageModule.getPathsFromFullPath(fullPath)
            let isAssignedPath = storageModule.isAssignedPath(fullPath, name, format, entity.sessionId, entity.fromUId)
            if (!isAssignedPath) {
                let dePath = storageModule.allocLocalFilePath(entity.sessionId, IMCoreManager.shared.uId, name, format)
                try storageModule.copyFile(fullPath, dePath)
                audioBody.path = dePath
                let d = try JSONEncoder().encode(audioBody)
                entity.content = String(data: d, encoding: .utf8)!
                try updateMsgContent(entity, false)
            }
            let path = IMCoreManager.shared.storageModule?.sandboxFilePath(audioBody.path!)
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
                                audioBody.url = url
                                let d = try JSONEncoder().encode(audioBody)
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
                )
                return Disposables.create()
            })
        } catch {
            return Observable.error(error)
        }
    }
    
    
    override func getSessionDesc(msg: Message) -> String {
        return "[Audio]"
    }
    
}
