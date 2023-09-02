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
        
    }
    
    private func initAudioUi(duration: Int) {
    }
    
    private func downloadAndPlay() {
        
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
