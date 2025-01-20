//
//  SpeakView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import AVFoundation
import CocoaLumberjack
import UIKit

class IMSpeakView: UILabel {

    weak var sender: IMMsgSender?

    private var hasTouchOutside = false
    private var recordingDb: Double = 0.0
    private let imageVolume1 = ResourceUtils.loadImage(named: "ic_volume_1")
    private let imageVolume2 = ResourceUtils.loadImage(named: "ic_volume_2")
    private let imageVolume3 = ResourceUtils.loadImage(named: "ic_volume_3")
    private let imageVolume4 = ResourceUtils.loadImage(named: "ic_volume_4")
    private let imageVolume5 = ResourceUtils.loadImage(named: "ic_volume_5")

    private lazy var rootView: UIView = {
        var root = self.superview
        while root?.superview != nil {
            root = root?.superview
        }
        return root!
    }()

    private lazy var recordingDBView: UIImageView = {
        let db = UIImageView()
        return db
    }()

    private lazy var recordingTipsView: UILabel = {
        let tips = UILabel()
        tips.font = UIFont.systemFont(ofSize: 16.0)
        tips.textColor = UIColor.init(hex: "333333")
        tips.textAlignment = .center
        return tips
    }()

    private lazy var recordingPopup: UIView = {
        let popup = UIView()
        popup.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        popup.layer.cornerRadius = 20
        popup.layer.masksToBounds = true
        popup.addSubview(self.recordingDBView)
        self.recordingDBView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.centerX.equalToSuperview()
            make.size.equalTo(60)
        }

        popup.addSubview(self.recordingTipsView)
        self.recordingTipsView.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        return popup
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.font = UIFont.boldSystemFont(ofSize: 16.0)
        self.textAlignment = .center
        self.textColor = UIColor.init(hex: "333333")
        self.text = ResourceUtils.loadString("press_for_record_voice")
        self.backgroundColor = IMUIManager.shared.uiResourceProvider?.inputBgColor()
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.checkLocation(touches, with: event)
        let permission = AVAudioSession.sharedInstance().recordPermission
        if permission == .granted {
            self.startRecord()
        } else if permission == .undetermined {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
            }
        } else {
            self.sender?.showSenderMessage(
                text: ResourceUtils.loadString("please_open_record_permission"),
                success: false
            )
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }
        }

    }

    private func startRecord() {
        let started = self.startRecordAudio()
        if started {
            self.startUI()
            self.showTipsPopup()
            self.layoutRecording()
        } else {
            self.sender?.showSenderMessage(
                text: ResourceUtils.loadString("record_failed"), success: false
            )
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
            make.size.equalTo(160)
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
            if sf.hasTouchOutside {
                sf.recordingTipsView.text = ResourceUtils.loadString(
                    "release_to_cancel")
            } else {
                sf.recordingTipsView.text = ResourceUtils.loadString(
                    "release_to_send_voice")
            }
            if sf.recordingDb <= 45 {
                sf.recordingDBView.image = sf.imageVolume1
            } else if sf.recordingDb <= 50 {
                sf.recordingDBView.image = sf.imageVolume2
            } else if sf.recordingDb <= 60 {
                sf.recordingDBView.image = sf.imageVolume3
            } else if sf.recordingDb <= 70 {
                sf.recordingDBView.image = sf.imageVolume4
            } else {
                sf.recordingDBView.image = sf.imageVolume5
            }
        }
    }

    private func startUI() {
        self.text = ResourceUtils.loadString("release_to_cancel")
        self.backgroundColor = IMUIManager.shared.uiResourceProvider?.panelBgColor()
    }

    private func resetUI() {
        self.text = ResourceUtils.loadString("press_for_record_voice")
        self.backgroundColor = IMUIManager.shared.uiResourceProvider?.inputBgColor()
        self.dismissTipsPopup()
    }

    func startRecordAudio() -> Bool {
        guard let session = self.sender?.getSession() else {
            return false
        }
        guard let cp = IMUIManager.shared.contentProvider else {
            return false
        }
        if cp.isRecordingAudio() {
            return false
        }
        let fileName = "audio_\(String().random(8)).oga"
        let filePath = IMCoreManager.shared.storageModule
            .allocSessionFilePath(session.id, fileName, "audio")
        return cp.startRecordAudio(path: filePath, duration: 60) {
            [weak self] db, duration, path, stopped in
            print("IMSpeakView recording: \(db), \(duration), \(stopped)")
            guard let sf = self else {
                OggOpusAudioRecorder.shared.stopRecording()
                return
            }
            if stopped {
                if !sf.hasTouchOutside {
                    // 发送
                    if duration < 2000 {
                        sf.sender?.showSenderMessage(
                            text: ResourceUtils.loadString(
                                "record_duration_too_short"), success: false
                        )
                        IMCoreManager.shared.storageModule.removeFile(path)
                    } else {
                        let d = duration / 1000
                        sf.sendAudioMsg(duration: d, path: path)
                    }
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
        DispatchQueue.main.async { [weak self] in
            let audioData = IMAudioMsgData(path: path, duration: duration)
            self?.sender?.sendMessage(MsgType.Audio.rawValue, nil, audioData, nil)
        }
    }

    func endRecordAudio() {
        if OggOpusAudioRecorder.shared.isRecording() {
            OggOpusAudioRecorder.shared.stopRecording()
        }
    }
}
