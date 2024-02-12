//
//  LiveCallViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack

class LiveCallViewController: BaseViewController, RoomDelegate {
    
    static func pushLiveCallViewController(_ from: UIViewController, _ room: Room) {
        let vc = LiveCallViewController()
        from.navigationController?.pushViewController(vc, animated: true)
    }
    
    static func presentLiveCallViewController(_ from: UIViewController, _ room: Room) {
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
        
        if let room = IMLiveManager.shared.getRoom() {
            room.registerObserver(self)
            self.setupView(room)
        }
    }
    
    private func setupView(_ room: Room) {
        self.showUserInfo()
        var remoteParticipantCount = 0
        room.getAllParticipants().forEach({ p in
            initParticipantView(p)
            if (p is RemoteParticipant) {
                remoteParticipantCount += 1
            }
        })
        
        if (remoteParticipantCount > 0) {
            showCallingView()
        } else {
            if (room.ownerId == IMLiveManager.shared.selfId()) {
                showRequestCallView()
            } else {
                showBeCallingView()
            }
        }
    }
    
    private func showUserInfo() {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        for m in room.members {
            if m != IMLiveManager.shared.selfId() {
                IMCoreManager.shared.userModule.queryUser(id: m)
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
            if let room = IMLiveManager.shared.getRoom() {
                if room.ownerId == IMLiveManager.shared.selfId() {
                    self.participantLocalView.startPeerConnection()
                }
            }
        } else {
            self.participantRemoteView.isHidden = false
            self.participantRemoteView.setParticipant(p: p)
            self.participantRemoteView.startPeerConnection()
            self.participantRemoteView.setFullScreen(true)
            self.participantLocalView.setFullScreen(false)
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
    
    
    func onTextMsgReceived(uId: Int64, text: String) {
        
    }
    
    func onBufferMsgReceived(data: Data) {
        
    }
    
    func exit() {
        IMLiveManager.shared.destroyRoom()
        if self.navigationController == nil {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}

extension LiveCallViewController: LiveCallProtocol {
    func currentLocalCamera() -> Int {
        guard let room = IMLiveManager.shared.getRoom() else {
            return 0
        }
        guard let localParticipant = room.getLocalParticipant() as? LocalParticipant else {
            return 0
        }
        return localParticipant.currentCamera()
    }
    
    func isCurrentCameraOpened() -> Bool {
        guard let room = IMLiveManager.shared.getRoom() else {
            return false
        }
        guard let localParticipant = room.getLocalParticipant() as? LocalParticipant else {
            return false
        }
        return !localParticipant.getVideoMuted()
    }
    
    func switchLocalCamera() {
        self.participantLocalView.switchCamera()
    }
    
    func openLocalCamera() {
        self.participantLocalView.muteVideo(muted: false)
    }
    
    func closeLocalCamera() {
        self.participantLocalView.muteVideo(muted: true)
    }
    
    func openRemoteVideo(user: User) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        let remoteParticipants = room.getRemoteParticipants()
        for p in remoteParticipants {
            if p.uId == user.id {
                p.setVideoMuted(false)
            }
        }
    }
    
    func closeRemoteVideo(user: User) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        let remoteParticipants = room.getRemoteParticipants()
        for p in remoteParticipants {
            if p.uId == user.id {
                p.setVideoMuted(true)
            }
        }
    }
    
    func openRemoteAudio(user: User) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        let remoteParticipants = room.getRemoteParticipants()
        for p in remoteParticipants {
            if p.uId == user.id {
                p.setAudioMuted(true)
            }
        }
    }
    
    func closeRemoteAudio(user: User) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        let remoteParticipants = room.getRemoteParticipants()
        for p in remoteParticipants {
            if p.uId == user.id {
                p.setAudioMuted(false)
            }
        }
    }
    
    func accept() {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        self.participantLocalView.startPeerConnection()
        room.getAllParticipants().forEach({ p in
            if (p is RemoteParticipant) {
                initParticipantView(p)
            }
        })
        self.showCallingView()
    }
    
    func hangup() {
        IMLiveManager.shared.leaveRoom()
        self.exit()
    }
    
}
