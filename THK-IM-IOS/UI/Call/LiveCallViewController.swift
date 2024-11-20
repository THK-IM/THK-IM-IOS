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
        _ from: UIViewController, _ roomId: String, _ callType: CallType,
        _ members: Set<Int64>
    ) {
        let vc = LiveCallViewController()
        vc.roomId = roomId
        vc.callType = callType.rawValue
        for m in members {
            vc.members.insert(m)
        }
        from.navigationController?.pushViewController(vc, animated: true)
    }

    static func popLiveCallViewController(
        _ from: UIViewController, _ roomId: String, _ callType: CallType,
        _ members: Set<Int64>
    ) {
        let vc = LiveCallViewController()
        vc.roomId = roomId
        vc.callType = callType.rawValue
        for m in members {
            vc.members.insert(m)
        }
        vc.modalPresentationStyle = .overFullScreen
        from.present(vc, animated: true)
    }

    var callType = CallType.RequestCalling.rawValue

    var roomId = ""
    var members = Set<Int64>()
    var acceptMembers = Set<Int64>()
    var rejectMembers = Set<Int64>()
    var hangupMembers = Set<Int64>()

    private var callStats = LiveCallStatus.Init

    private let callingInfoLayout: CallingInfoLayout = {
        let view = CallingInfoLayout()
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
        self.setupView()
        self.initSignalEvent()
    }

    private func initSignalEvent() {
        RTCRoomManager.shared.getRoomById(self.roomId)?.rtcCallback = self
        SwiftEventBus.onMainThread(self, name: LiveSignal.Event) {
            [weak self] vo in
            guard let signal = vo?.object as? LiveSignal else { return }
            guard let sf = self else { return }
            if let acceptSignal = signal.signalForType(
                LiveSignalType.AcceptRequest.rawValue, AcceptRequestSignal.self)
            {
                sf.onRemoteAcceptedCallingBySignal(
                    roomId: acceptSignal.roomId, uId: acceptSignal.uId)
            } else if let rejectSignal = signal.signalForType(
                LiveSignalType.RejectRequest.rawValue, RejectRequestSignal.self)
            {
                sf.onRemoteRejectedCallingBySignal(
                    roomId: rejectSignal.roomId, uId: rejectSignal.uId,
                    msg: rejectSignal.msg)
            } else if let hangupSignal = signal.signalForType(
                LiveSignalType.Hangup.rawValue, HangupSignal.self)
            {
                sf.onRemoteHangupCallingBySignal(
                    roomId: hangupSignal.roomId, uId: hangupSignal.uId,
                    msg: hangupSignal.msg)
            } else if let kickofMemberSignal = signal.signalForType(
                LiveSignalType.KickMember.rawValue, KickMemberSignal.self)
            {
                sf.onMemberKickedOffBySignal(
                    roomId: kickofMemberSignal.roomId,
                    uIds: kickofMemberSignal.kickIds,
                    msg: kickofMemberSignal.msg)
            } else if let endCallSignal = signal.signalForType(
                LiveSignalType.EndCall.rawValue, EndCallSignal.self)
            {
                sf.onCallEndedBySignal(roomId: endCallSignal.roomId)
            }
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

    private func setupView() {
        self.showUserInfo()
        RTCRoomManager.shared.getRoomById(self.roomId)?.getAllParticipants().forEach({ p in
            initParticipantView(p)
        })

        if self.callType == CallType.RequestCalling.rawValue {
            self.showRequestCallView()
        } else {
            self.showCallingView()
        }
    }

    private func showUserInfo() {
        if let remoteParticipants = RTCRoomManager.shared.getRoomById(self.roomId)?.getRemoteParticipants() {
            for m in remoteParticipants {
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
    }

    private func showRequestCallView() {
        self.requestCallLayout.isHidden = false
        self.callingLayout.isHidden = true

        self.requestCallLayout.initCall(self)
        self.startRequestCalling()
    }

    private func showCallingView() {
        self.requestCallLayout.isHidden = true
        self.callingLayout.isHidden = false
        self.callingLayout.initCall(self)
    }

    private func initParticipantView(_ p: BaseParticipant) {
        if p is LocalParticipant {
            self.participantLocalView.setParticipant(p: p)
            self.participantLocalView.startPeerConnection()
        } else {
            self.participantRemoteView.isHidden = false
            self.participantRemoteView.setParticipant(p: p)
            self.participantRemoteView.startPeerConnection()
            self.participantRemoteView.setFullScreen(true)
            self.participantLocalView.setFullScreen(false)
            self.view.bringSubviewToFront(self.participantLocalView)
        }
    }

    func needCallMembers() -> Set<Int64> {
        var needCallMembers = Set<Int64>()
        for m in self.members {
            if !self.acceptMembers.contains(m)
                && !self.rejectMembers.contains(m)
                && m != RTCRoomManager.shared.myUId
            {
                needCallMembers.insert(m)
            }
        }
        return needCallMembers
    }

    func exitRoom() {
        RTCRoomManager.shared.leaveRoom(id: self.roomId, delRoom: true)
            .compose(RxTransformer.shared.io2Main())
            .subscribe {
            } onCompleted: { [weak self] in
                self?.exit()
            }.disposed(by: self.disposeBag)

    }

    func exit() {
        RTCRoomManager.shared.destroyRoom(id: self.roomId)
        if self.navigationController == nil {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

}

extension LiveCallViewController: RTCRoomCallBack {

    func onError(_ function: String, _ err: any Error) {
    }

    func onParticipantJoin(_ p: BaseParticipant) {
        self.initParticipantView(p)
        self.showCallingView()
    }

    func onParticipantLeave(_ p: BaseParticipant) {
    }

    func onParticipantVoice(_ uId: Int64, _ volume: Double) {
        print("onParticipantVoice uId: \(uId), isMyself: \(uId==RTCRoomManager.shared.myUId) volume: \(volume))")
    }

    func onTextMsgReceived(_ type: Int, _ text: String) {

    }

    func onDataMsgReceived(_ data: Data) {

    }

    func onConnectStatus(_ uId: Int64, _ status: Int) {
    }

}

extension LiveCallViewController: LiveCallProtocol {

    func room() -> RTCRoom? {
        return RTCRoomManager.shared.getRoomById(self.roomId)
    }

    func startRequestCalling() {
        let members = self.needCallMembers()
        if members.count > 0 {
            RTCRoomManager.shared.callRoomMembers(
                self.roomId, "", Int64(LiveSignal.TimeoutSecond + 2),
                members
            )
            .compose(RxTransformer.shared.io2Main())
            .subscribe { _ in

            }.disposed(by: self.disposeBag)

            DispatchQueue.main.asyncAfter(
                deadline: .now()
                    + DispatchTimeInterval.seconds(LiveSignal.TimeoutSecond),
                execute: { [weak self] in
                    self?.startRequestCalling()
                })
        } else {
            if rejectMembers.count > 0 {
                self.exitRoom()
            }
        }
    }

    func cancelRequestCalling() {
        RTCRoomManager.shared.cancelCallRoomMembers(
            self.roomId, "", self.members
        )
        .compose(RxTransformer.shared.io2Main())
        .subscribe { [weak self] _ in
            self?.exit()
        }.disposed(by: self.disposeBag)
    }

    func hangupCalling() {
        RTCRoomManager.shared.leaveRoom(id: self.roomId, delRoom: true)
            .compose(RxTransformer.shared.io2Main())
            .subscribe { [weak self] _ in
                self?.exit()
            }.disposed(by: self.disposeBag)
    }

    func onRemoteAcceptedCallingBySignal(roomId: String, uId: Int64) {
        if roomId != self.roomId { return }
        self.acceptMembers.insert(uId)
        self.rejectMembers.remove(uId)
    }

    func onRemoteRejectedCallingBySignal(
        roomId: String, uId: Int64, msg: String
    ) {
        if roomId != self.roomId { return }
        self.rejectMembers.insert(uId)
        self.acceptMembers.remove(uId)
        if self.acceptMembers.count == 0 && self.needCallMembers().count == 0 {
            self.exit()
        }
    }

    func onRemoteHangupCallingBySignal(roomId: String, uId: Int64, msg: String)
    {
        if roomId != self.roomId { return }
        self.hangupMembers.insert(uId)
        self.exit()
    }

    func onMemberKickedOffBySignal(
        roomId: String, uIds: Set<Int64>, msg: String
    ) {
        if roomId != self.roomId { return }
        if uIds.contains(RTCRoomManager.shared.myUId) {
            self.exit()
        }
    }

    func onCallEndedBySignal(roomId: String) {
        if roomId != self.roomId { return }
        self.exit()
    }

}
