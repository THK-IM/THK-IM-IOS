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
    
    override func entity2MsgBean(msg entity: Message) -> MessageBean {
        let bean =  super.entity2MsgBean(msg: entity)
        do {
            let audioBody = try JSONDecoder().decode(
                AudioMsgBody.self,
                from: entity.content.data(using: .utf8) ?? Data()
            )
            audioBody.path = nil
            let d = try JSONEncoder().encode(audioBody)
            let content = String(data: d, encoding: .utf8)
            if (content != nil) {
                bean.body = content!
            }
        } catch {
            DDLogError(error)
        }
        return bean
    }
    
    override func uploadObservable(_ entity: Message) -> Observable<Message>? {
        return self.uploadAudio(entity)
    }
    
    open func uploadAudio(_ entity: Message) -> Observable<Message>? {
        guard let storageModule = IMManager.shared.storageModule else {
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
            fullPath = (IMManager.shared.storageModule?.sandboxFilePath(fullPath))!
            let (_, name) = storageModule.getPathsFromFullPath(fullPath)
            let isAssignedPath = storageModule.isAssignedPath(fullPath, name, format, entity.sid, entity.fUId)
            if (!isAssignedPath) {
                let dePath = storageModule.allocLocalFilePath(entity.sid, IMManager.shared.uId, name, format)
                try storageModule.copyFile(fullPath, dePath)
                audioBody.path = dePath
                let d = try JSONEncoder().encode(audioBody)
                entity.content = String(data: d, encoding: .utf8)!
                try updateMsgContent(entity, false)
            }
            let path = IMManager.shared.storageModule?.sandboxFilePath(audioBody.path!)
            let uploadKey = storageModule.allocServerFilePath(entity.sid, entity.fUId, name)
            return Observable.create({observer -> Disposable in
                _ = IMManager.shared.fileLoadModule?.upload(
                    key: uploadKey,
                    path: path!,
                    loadListener: LoadListener({ [weak self] progress, state, url, path in
                        switch(state) {
                        case LoadState.Failed.rawValue:
                            observer.onError(Exception.IMError("\(path) upload \(url) error"))
                            observer.onCompleted()
                            break
                        case LoadState.Success.rawValue:
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
