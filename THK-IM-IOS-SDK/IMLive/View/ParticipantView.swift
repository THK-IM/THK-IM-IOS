//
//  ParticipantView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import RxSwift
import WebRTC

open class ParticipantView: UIView {

    var participant: BaseParticipant? = nil
    private var fullScreen = true

    private let disposeBag = DisposeBag()

    var defaultScaleX = 0.35
    var defaultScaleY = 0.3

    lazy var rtcVideoView: RTCMTLVideoView = {
        let v = RTCMTLVideoView()
        v.contentMode = .scaleToFill
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(self.rtcVideoView)
        self.rtcVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.rtcVideoView.videoContentMode = .scaleAspectFill
    }

    public func setMirror(_ enable: Bool) {
        if enable {
            self.rtcVideoView.transform = CGAffineTransformMakeScale(-1.0, 1.0)
        } else {
            self.rtcVideoView.transform = CGAffineTransformMakeScale(1.0, 1.0)
        }
    }

    public func setParticipant(p: BaseParticipant) {
        self.participant = p
        self.participant?.attachViewRender(self.rtcVideoView)
        self.participant?.initPeerConnection()
    }

    public func startPeerConnection() {
        self.participant?.startPeerConnection()
    }

    public func isFullScreen() -> Bool {
        return self.fullScreen
    }

    public func setFullScreen(_ fullScreen: Bool) {
        if self.fullScreen == fullScreen {
            return
        }
        self.fullScreen = fullScreen
        if self.fullScreen {
            self.switchToFullScreen()
        } else {
            self.switchToDragView()
        }
    }

    open func switchToFullScreen() {
        UIView.animate(
            withDuration: 0.4,
            animations: { [weak self] in
                let scaleTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                let positionTransform = CGAffineTransform(translationX: 0, y: 0)
                let combinedTransform = scaleTransform.concatenating(positionTransform)
                self?.transform = combinedTransform
            })
    }

    open func switchToDragView() {
        UIView.animate(
            withDuration: 0.4,
            animations: { [weak self] in
                guard let sf = self else {
                    return
                }
                let translationX = (UIScreen.main.bounds.width * (1 - sf.defaultScaleX)) * 0.5
                let translationY = (0 - UIScreen.main.bounds.height * (1 - sf.defaultScaleY)) * 0.5
                let scaleTransform = CGAffineTransform(
                    scaleX: sf.defaultScaleX, y: sf.defaultScaleY)
                let positionTransform = CGAffineTransform(
                    translationX: translationX, y: translationY)
                let combinedTransform = scaleTransform.concatenating(positionTransform)
                sf.transform = combinedTransform
            })
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if fullScreen {
            return
        }
        guard let touch = touches.first else {
            return
        }
        let current = touch.location(in: self)
        let pre = touch.previousLocation(in: self)
        var translationX = self.transform.tx + (current.x - pre.x) * defaultScaleX
        var translationY = self.transform.ty + (current.y - pre.y) * defaultScaleY

        translationX = min(translationX, UIScreen.main.bounds.width * (1 - defaultScaleX) * 0.5)
        translationX = max(translationX, -UIScreen.main.bounds.width * (1 - defaultScaleX) * 0.5)
        translationY = min(translationY, UIScreen.main.bounds.height * (1 - defaultScaleY) * 0.5)
        translationY = max(translationY, -UIScreen.main.bounds.height * (1 - defaultScaleY) * 0.5)

        self.transform.tx = translationX
        self.transform.ty = translationY
    }

    public func currentCamera() -> Int {
        if self.participant != nil && self.participant! is LocalParticipant {
            return (participant! as! LocalParticipant).currentCamera()
        }
        return 0
    }

    public func switchCamera() {
        if participant == nil {
            return
        }
        (participant! as? LocalParticipant)?.switchCamera()
    }

    public func isAudioMute() -> Bool {
        if participant == nil {
            return false
        }
        return participant!.getAudioMuted()
    }

    public func muteAudio(_ mute: Bool) {
        participant?.setAudioMuted(mute)
    }

    public func isVideoMute() -> Bool {
        if participant == nil {
            return false
        }
        return participant!.getVideoMuted()
    }

    public func muteVideo(_ mute: Bool) {
        participant?.setVideoMuted(mute)
    }

}
