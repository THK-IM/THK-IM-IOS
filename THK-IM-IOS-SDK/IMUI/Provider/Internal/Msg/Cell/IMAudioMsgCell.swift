//
//  IMAudioMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import UIKit
import CocoaLumberjack
import Kingfisher
import SwiftEventBus

class IMAudioMsgCell: BaseMsgCell {
    
    private let textView = IMMsgLabelView()
    private var audioMsgBody: AudioMsgBody?
    
    private var taskId: String?
    private var downloadListener: FileLoaderListener?
    
    override func msgView() -> UIView {
        self.textView.sizeToFit()
        self.textView.numberOfLines = 0
        self.textView.font = UIFont.boldSystemFont(ofSize: 14)
        self.textView.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        self.textView.isUserInteractionEnabled = true
        if self.cellPosition() == CellPosition.Left.rawValue {
            self.textView.textColor = UIColor.black
        } else if self.cellPosition() == CellPosition.Right.rawValue {
            self.textView.textColor = UIColor.black
        } else {
            self.textView.textColor = UIColor.white
        }
        return self.textView
    }
    
    override func hasBubble() -> Bool {
        return true
    }
    
    override func setMessage(_ msgs: Array<Message>, _ position: Int) {
        super.setMessage(msgs, position)
        do {
            self.audioMsgBody = try JSONDecoder().decode(
                AudioMsgBody.self,
                from: self.message!.content.data(using: .utf8) ?? Data()
            )
            let duration = self.audioMsgBody?.duration ?? 0
            self.initAudioUi(duration: duration)
            self.textView.rx.tapGesture(
                configuration: { gestureRecognizer, delegate in
                    delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                    return otherGestureRecognizer is UILongPressGestureRecognizer
                }
            })
            .when(.ended)
            .subscribe(onNext: { [weak self]  event in
                self?.downloadAndPlay()
            }).disposed(by: disposeBag)
        } catch {
            DDLogError("setMessage msg:\(self.message!), error \(error)")
        }
    }
    
    private func initAudioUi(duration: Int) {
        self.textView.text = "时长: \(duration/1000 + 1)''"
//        var width = (duration/1000 + 1) * 200 / 60
//        width = max(width, 80)
//        width = min(width, 200)
//        self.textView.snp.updateConstraints { make in
//            make.bottom.left.right.top.equalToSuperview()
//        }
    }
    
    private func downloadAndPlay() {
        if self.audioMsgBody?.path != nil {
            playAudio((self.audioMsgBody?.path)!)
        } else if self.audioMsgBody?.url != nil {
            downloadAudio(self.audioMsgBody!)
        } else {
            // TODO 消息错误提示
        }
    }
    
    private func downloadAudio(_ audioMsgBody: AudioMsgBody) {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return
        }
        guard let fileModule = IMCoreManager.shared.fileLoadModule else {
            return
        }
        guard let msg = self.message else {
            return
        }
        let fileName = storageModule.getFileExtFromUrl(audioMsgBody.url!)
        let path = storageModule.allocLocalFilePath(msg.sessionId, msg.fromUId, fileName, "audio")
        self.unregister()
        let downloadListener = FileLoaderListener(
            {
                [weak self] progress, state, url, path in
                switch state {
                case FileLoaderState.Success.rawValue:
                    do {
                        audioMsgBody.path = path
                        let d = try JSONEncoder().encode(audioMsgBody)
                        guard let msg = self?.message else {
                            return
                        }
                        guard let content = String(data: d, encoding: .utf8) else {
                            return
                        }
                        msg.content = content
                        try IMCoreManager.shared.database.messageDao.updateMessages(msg)
                    } catch {
                        DDLogError(error)
                    }
                    self?.playAudio(path)
                    break
                default:
                    break
                }
            },
            {
                return false
            }
        )
        self.taskId = fileModule.download(url: audioMsgBody.url!, path: path, loadListener: downloadListener)
        self.downloadListener = downloadListener
    }
    
    private func playAudio(_ path: String) {
        // 每次debug运行时 document目录位置会改变，适配一下
        guard let realPath = IMCoreManager.shared.storageModule?.sandboxFilePath(path) else {
            return
        }
        let success = OggOpusAudioPlayer.shared.startPlaying(realPath) {
            [weak self] db, duration ,path, stopped in
            guard let sf = self else {
                return
            }
            DispatchQueue.main.async { [weak sf] in
                sf?.initAudioUi(duration: duration+1)
            }
        }
        if !success {
            // TODO 播放失败提示
        }
    }
    
    override func disappear() {
        super.disappear()
        self.unregister()
    }
    
    private func unregister() {
        guard let fileModule = IMCoreManager.shared.fileLoadModule else {
            return
        }
        guard let downloadListener = self.downloadListener else {
            return
        }
        guard let taskId = self.taskId else {
            return
        }
        fileModule.cancelUploadListener(taskId: taskId, listener: downloadListener)
        self.taskId = nil
        self.downloadListener = nil
    }
    
    
    
}
