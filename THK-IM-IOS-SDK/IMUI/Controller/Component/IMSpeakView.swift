//
//  SpeakView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import UIKit
import CocoaLumberjack

class IMSpeakView: UILabel {
    
    weak var sender: IMMsgSender?
    
    private var hasTouchOutside = false
    private var recordingDb: Double = 0.0
    
    private lazy var rootView: UIView = {
        var root = self.superview
        while root?.superview != nil {
            root = root?.superview
        }
        return root!
    }()
    
    private lazy var recordingDB: UILabel = {
        let db = UILabel()
        db.font = UIFont.systemFont(ofSize: 16.0)
        db.textColor = UIColor.white
        db.textAlignment = .center
        return db
    }()
    
    private lazy var recordingTips: UILabel = {
        let tips = UILabel()
        tips.font = UIFont.systemFont(ofSize: 16.0)
        tips.textColor = UIColor.white
        tips.textAlignment = .center
        return tips
    }()
    
    private lazy var recordingPopup: UIView = {
        let popup = UIView()
        popup.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        popup.addSubview(self.recordingDB)
        self.recordingDB.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        popup.addSubview(self.recordingTips)
        self.recordingTips.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.recordingDB)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        return popup
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.font = UIFont.boldSystemFont(ofSize: 16.0)
        self.textAlignment = .center
        self.textColor = UIColor.black
        self.text = "按住 说话"
        self.backgroundColor = UIColor.white
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.checkLocation(touches, with: event)
        let started = self.startRecordAudio()
        if started {
            self.startUI()
            showTipsPopup()
            layoutRecording()
        } else {
            // TODO toast失败
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.checkLocation(touches, with: event)
        self.layoutRecording()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.checkLocation(touches, with: event)
        self.resetUI()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.checkLocation(touches, with: event)
        self.resetUI()
    }
    
    private func checkLocation(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        self.hasTouchOutside = !CGRectContainsPoint(self.bounds, location)
    }
    
    private func showTipsPopup() {
        // Customize config using the default as a base.
        self.rootView.insertSubview(self.recordingPopup, at: 2)
        self.recordingPopup.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(200)
        }
    }
    
    private func dismissTipsPopup() {
        self.recordingPopup.removeFromSuperview()
        self.endRecordAudio()
    }
    
    private func layoutRecording() {
        DispatchQueue.main.async { [weak self] in
            guard let sf = self else {
                return
            }
            if (sf.hasTouchOutside) {
                sf.recordingTips.text = "松手取消"
            } else {
                sf.recordingTips.text = "松手发送"
            }
            sf.recordingDB.text = "分贝: \(sf.recordingDb)"
        }
    }
    
    private func startUI() {
        self.text = "松开 结束"
        self.backgroundColor = UIColor.gray
    }
    
    private func resetUI() {
        self.text = "按住 说话"
        self.backgroundColor = UIColor.white
        self.dismissTipsPopup()
    }
    
    func startRecordAudio() -> Bool {
        guard let session = self.sender?.getSession() else {
            return false
        }
        if OggOpusAudioRecorder.shared.isRecording() {
            return false
        }
        let fileName = "audio_\(String().random(8)).oga"
        let filePath = IMCoreManager.shared.storageModule
            .allocSessionFilePath(session.id, fileName, "audio")
        return OggOpusAudioRecorder.shared.startRecording(filePath) {
            [weak self] db, duration, path, stopped in
            print("IMSpeakView recording: \(db), \(duration), \(stopped)")
            guard let sf = self else {
                OggOpusAudioRecorder.shared.stopRecording()
                return
            }
            if stopped {
                if (!sf.hasTouchOutside) {
                    // 发送
                    sf.sendAudioMsg(duration: duration / 1000 + 1, path: path)
                } else {
                    // 取消，删除文件
                    IMCoreManager.shared.storageModule.removeFile(path)
                }
            } else {
                // 录制中
                DispatchQueue.main.async { [weak sf] in
                    sf?.recordingDb = db
                    sf?.layoutRecording()
                }
            }
        }
    }
    
    func sendAudioMsg(duration: Int, path: String) {
        let audioData = IMAudioMsgData(path: path, duration: duration, played: true)
        self.sender?.sendMessage(MsgType.Audio.rawValue, audioData)
    
    }
    
    func endRecordAudio() {
        if OggOpusAudioRecorder.shared.isRecording() {
            OggOpusAudioRecorder.shared.stopRecording()
        }
    }
}


