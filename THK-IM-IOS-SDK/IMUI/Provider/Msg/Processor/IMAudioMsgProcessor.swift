//
//  IMAudioMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import Foundation
import RxSwift
import CocoaLumberjack

open class IMAudioMsgProcessor : IMBaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.Audio.rawValue
    }
    
    open override func msgDesc(msg: Message) -> String {
        return "[语音消息]"
    }
    
    open override func reprocessingObservable(_ message: Message) -> Observable<Message>? {
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
            DDLogError("\(error)")
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
    
    open override func uploadObservable(_ entity: Message) -> Observable<Message> {
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
            return Observable.create({observer -> Disposable in
                let loaderListener = FileLoadListener(
                    { progress, state, url, path, err in
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
                                audioBody.url = url
                                audioBody.name = name
                                audioBody.duration = audioData.duration!
                                let content = try JSONEncoder().encode(audioBody)
                                entity.content = String(data: content, encoding: .utf8)!
                                entity.sendStatus = MsgSendStatus.Sending.rawValue
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
                fileLoadModule.upload(path: realPath, message: entity, loadListener: loaderListener)
                return Disposables.create()
            })
        } catch {
            DDLogError("\(error)")
            return Observable.error(error)
        }
    }
    
    
    open override func downloadMsgContent(_ message: Message, resourceType: String) -> Bool {
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
            } else {
                return false
            }
            var downloadUrl: String? = nil
            if (resourceType == IMMsgResourceType.Thumbnail.rawValue) {
                downloadUrl = body.url
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
            let fileName = body.name
            let localPath = IMCoreManager.shared.storageModule.allocSessionFilePath(
                message.sessionId, fileName!, IMFileFormat.Audio.rawValue)
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
                                data.path = localPath
                                data.duration = body.duration
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
        return true
    }
    
}
