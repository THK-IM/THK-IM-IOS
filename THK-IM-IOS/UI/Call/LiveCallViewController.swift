//
//  LiveCallViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import CocoaLumberjack
import UIKit

class LiveCallViewController: BaseViewController {

    static func pushLiveCallViewController(
        _ from: UIViewController, _ room: RTCRoom
    ) {
        let vc = LiveCallViewController()
        from.navigationController?.pushViewController(vc, animated: true)
    }

    static func presentLiveCallViewController(
        _ from: UIViewController, _ room: RTCRoom
    ) {
        let vc = LiveCallViewController()
        vc.modalPresentationStyle = .overFullScreen
        from.present(vc, animated: true)
    }

    private var callStats = LiveCallStatus.Init

    private let callingInfoLayout: CallingInfoLayout = {
        let view = CallingInfoLayout()
        return view
    }()

    private let beCallLayout: BeCallingLayout = {
        let view = BeCallingLayout()
        view.isHidden = true
        return view
    }()

    private let callingLayout: CallingLayout = {
        let view = CallingLayout()
        view.isHidden = true
        return view
    }()

    private let requestCallLayout: RequestCallLayout = {
        let view = RequestCallLayout()
        view.isHidden = true
        return view
    }()

    private let participantLocalView: ParticipantView = {
        let view = ParticipantView()
        return view
    }()

    private let participantRemoteView: ParticipantView = {
        let view = ParticipantView()
        return view
    }()

    override func hasTitlebar() -> Bool {
        return false
    }

    override func swipeBack() -> Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.view.addSubview(self.participantRemoteView)
        self.participantRemoteView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.view.addSubview(self.participantLocalView)
        self.participantLocalView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.view.addSubview(self.callingInfoLayout)
        self.callingInfoLayout.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(400)
        }
        self.view.addSubview(self.requestCallLayout)
        self.requestCallLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.callingInfoLayout.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.view.addSubview(self.callingLayout)
        self.callingLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.callingInfoLayout.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.view.addSubview(self.beCallLayout)
        self.beCallLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.callingInfoLayout.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        self.participantLocalView.rx.tapGesture(configuration: {
            gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom {
                gestureRecognizer, touches in
                return true
            }
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
                let res = otherGestureRecognizer is UILongPressGestureRecognizer
                return res
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self] _ in
            self?.fullLocalParticipantView()
        })
        .disposed(by: disposeBag)

        self.participantRemoteView.rx.tapGesture(configuration: {
            gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom {
                gestureRecognizer, touches in
                return true
            }
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self] _ in
            self?.fullRemoveParticipantView()
        })
        .disposed(by: disposeBag)

        if let room = RTCRoomManager.shared.currentRoom() {
            room.delegate = self
            self.setupView(room)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func fullLocalParticipantView() {
        if !self.participantLocalView.isFullScreen() {
            self.participantLocalView.setFullScreen(true)
            self.participantRemoteView.setFullScreen(false)
            self.view.bringSubviewToFront(self.callingInfoLayout)
            self.view.bringSubviewToFront(self.callingLayout)
            self.view.bringSubviewToFront(self.participantRemoteView)
        }
    }

    private func fullRemoveParticipantView() {
        if !self.participantRemoteView.isFullScreen() {
            self.participantRemoteView.setFullScreen(true)
            self.participantLocalView.setFullScreen(false)
            self.view.bringSubviewToFront(self.callingInfoLayout)
            self.view.bringSubviewToFront(self.callingLayout)
            self.view.bringSubviewToFront(self.participantLocalView)
        }
    }

    private func setupView(_ room: RTCRoom) {
        self.showUserInfo()
        var remoteParticipantCount = 0
        room.getAllParticipants().forEach({ p in
            initParticipantView(p)
            if p is RemoteParticipant {
                remoteParticipantCount += 1
            }
        })

        if remoteParticipantCount > 0 {
            showCallingView()
        } else {
            if room.ownerId == RTCRoomManager.shared.currentRoom()?.ownerId {
                showRequestCallView()
            } else {
                showBeCallingView()
            }
        }
    }

    private func showUserInfo() {
        guard let room = RTCRoomManager.shared.currentRoom() else {
            return
        }
        for m in room.getAllParticipants() {
            if m.uId != RTCRoomManager.shared.myUId {
                IMCoreManager.shared.userModule.queryUser(id: m.uId)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { [weak self] user in
                        self?.callingInfoLayout.setUserInfo(user: user)
                        self?.callingInfoLayout.isHidden = false
                    }).disposed(by: self.disposeBag)
            }
        }
    }

    private func showRequestCallView() {
        self.requestCallLayout.isHidden = false
        self.callingLayout.isHidden = true
        self.beCallLayout.isHidden = true

        self.requestCallLayout.initCall(self)
    }

    private func showCallingView() {
        self.requestCallLayout.isHidden = true
        self.callingLayout.isHidden = false
        self.beCallLayout.isHidden = true

        self.callingLayout.initCall(self)
    }

    private func showBeCallingView() {
        self.requestCallLayout.isHidden = true
        self.callingLayout.isHidden = true
        self.beCallLayout.isHidden = false

        self.beCallLayout.initCall(self)
    }

    private func initParticipantView(_ p: BaseParticipant) {
        if p is LocalParticipant {
            self.participantLocalView.setParticipant(p: p)
            if let room = RTCRoomManager.shared.currentRoom() {
                if room.ownerId == RTCRoomManager.shared.myUId {
                    self.participantLocalView.startPeerConnection()
                }
            }
        } else {
            self.participantRemoteView.isHidden = false
            self.participantRemoteView.setParticipant(p: p)
            self.participantRemoteView.startPeerConnection()
            self.participantRemoteView.setFullScreen(true)
            self.participantLocalView.setFullScreen(false)
            self.view.bringSubviewToFront(self.participantLocalView)
        }
    }

    func join(_ p: BaseParticipant) {
        DDLogInfo("BaseParticipant join \(p.uId)")
        self.initParticipantView(p)
        self.showCallingView()
    }

    func leave(_ p: BaseParticipant) {
        if p is LocalParticipant {
            showToast("通话已中断")
        } else {
            showToast("对方已挂断")
        }
        self.exit()
    }

    func onMemberHangup(uId: Int64) {
        showToast("对方已挂断")
        exit()
    }

    func onCallEnd() {
        showToast("对方已挂断")
        exit()
    }

    func exit() {
        RTCRoomManager.shared.destroyRoom()
        if self.navigationController == nil {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

}

extension LiveCallViewController: RTCRoomProtocol {

    func onError(_ function: String, _ err: any Error) {
    }

    func onParticipantJoin(_ p: BaseParticipant) {
        self.join(p)
    }

    func onParticipantLeave(_ p: BaseParticipant) {
        self.leave(p)
    }

    func onParticipantVoice(_ uId: Int64, _ volume: Double) {

    }

    func onTextMsgReceived(_ type: Int, _ text: String) {

    }

    func onDataMsgReceived(_ data: Data) {

    }

    func onConnectStatus(_ uId: Int64, _ status: Int) {
    }

}

extension LiveCallViewController: LiveCallProtocol {

    func isSpeakerMuted() -> Bool {
        return IMLiveRTCEngine.shared.isSpeakerMuted()
    }

    func muteSpeaker(mute: Bool) {
        return IMLiveRTCEngine.shared.muteSpeaker(mute)
    }

    func muteLocalVideo(mute: Bool) {
        self.participantLocalView.muteVideo(mute)
    }

    func isLocalVideoMuted() -> Bool {
        return self.participantLocalView.isVideoMute()
    }

    func muteLocalAudio(mute: Bool) {
        self.participantLocalView.muteAudio(mute)
    }

    func isLocalAudioMuted() -> Bool {
        return self.participantLocalView.isAudioMute()
    }

    func muteRemoteAudio(uId: Int64, mute: Bool) {
        self.participantRemoteView.muteAudio(mute)
    }

    func isRemoteAudioMuted(uId: Int64) -> Bool {
        return self.participantRemoteView.isAudioMute()
    }

    func muteRemoteVideo(uId: Int64, mute: Bool) {
        self.participantRemoteView.muteVideo(mute)
    }

    func isRemoteVideoMuted(uId: Int64) -> Bool {
        self.participantRemoteView.isVideoMute()
    }

    func currentLocalCamera() -> Int {
        return self.participantLocalView.currentCamera()
    }

    func switchLocalCamera() {
        self.participantLocalView.switchCamera()
    }
    
    func cancelCalling() {
        guard let room = RTCRoomManager.shared.currentRoom() else {
            return
        }
        RTCRoomManager.shared.leveaRoom()
        self.exit()
    }

    func acceptCalling() {
        guard let room = RTCRoomManager.shared.currentRoom() else {
            return
        }
        self.participantLocalView.startPeerConnection()
        room.getAllParticipants().forEach({ p in
            if p is RemoteParticipant {
                initParticipantView(p)
            }
        })
        self.showCallingView()
    }

    func rejectCalling() {
        guard let room = RTCRoomManager.shared.currentRoom() else {
            return
        }
        RTCRoomManager.shared.refuseJoinRoom(roomId: room.id, reason: "")
        self.exit()
    }

    func hangupCalling() {
        guard let room = RTCRoomManager.shared.currentRoom() else {
            return
        }
        RTCRoomManager.shared.leveaRoom()
        self.exit()
    }

}
