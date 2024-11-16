//
//  BeRequestedCallingPopup.swift
//  THK-IM-IOS
//
//  Created by think on 2024/11/16.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift
import SwiftEntryKit
import UIKit

class BeRequestedCallingPopup: UIView {

    private let disposeBag = DisposeBag()
    private var beCallingSignal: BeingRequestedSignal? = nil

    private lazy var contentView: UIView = {
        let v = UIView()
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowOpacity = 0.3
        v.layer.shadowRadius = 4
        v.layer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        return v
    }()

    private lazy var avatarView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        return v
    }()

    private lazy var nickView: UILabel = {
        let v = UILabel()
        v.font = UIFont.boldSystemFont(ofSize: 16)
        v.textColor = .white
        v.numberOfLines = 1
        return v
    }()

    private lazy var messageView: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 13)
        v.textColor = UIColor.init(hex: "#EEEEEE")
        v.numberOfLines = 2
        return v
    }()

    private lazy var userLayout: UIView = {
        let v = UIView()
        v.addSubview(self.avatarView)
        v.addSubview(self.nickView)
        v.addSubview(self.messageView)

        self.avatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(60)
            make.left.equalToSuperview()
        }
        self.nickView.snp.makeConstraints { make in
            make.top.equalTo(self.avatarView.snp.top)
            make.left.equalTo(self.avatarView.snp.right).offset(14)
            make.right.equalToSuperview()
        }
        self.messageView.snp.makeConstraints { make in
            make.top.equalTo(self.avatarView.snp.centerY)
            make.left.equalTo(self.avatarView.snp.right).offset(14)
            make.right.equalToSuperview()
        }
        return v
    }()

    private lazy var acceptView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(named: "ic_call_accept")
        return v
    }()

    private lazy var rejectView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(named: "ic_call_hangup")
        return v
    }()

    private lazy var operLayout: UIView = {
        let v = UIView()
        v.addSubview(self.acceptView)
        v.addSubview(self.rejectView)

        self.rejectView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
            make.left.equalToSuperview()
        }

        self.acceptView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
            make.right.equalToSuperview()
            make.left.equalTo(self.rejectView.snp.right).offset(14)
        }
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.addSubview(self.contentView)
        self.contentView.frame = frame
        self.initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initViews() {
        self.contentView.addSubview(self.userLayout)
        self.contentView.addSubview(self.operLayout)
        self.operLayout.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.right.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }

        self.userLayout.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
            make.right.equalTo(self.operLayout.snp.left).offset(-14)
        }

        self.acceptView.rx.tapGesture().when(.ended)
            .subscribe { [weak self] _ in
                self?.dismiss()
            }.disposed(by: self.disposeBag)

        self.rejectView.rx.tapGesture().when(.ended)
            .subscribe { [weak self] _ in
                self?.dismiss()
            }.disposed(by: self.disposeBag)
    }

    func show(_ signal: BeingRequestedSignal) {
        self.beCallingSignal = signal
        SwiftEventBus.onMainThread(self, name: liveSignalEvent) {
            [weak self] vo in
            guard let sf = self else { return }
            guard let liveSignal = vo?.object as? LiveSignal else { return }
        }
        if signal.mode == RoomMode.Video.rawValue {
            self.messageView.text = "邀请你视频通话"
        } else if signal.mode == RoomMode.Audio.rawValue {
            self.messageView.text = "邀请你语音通话"
        }
        self.requestUser(signal.requestId)
        self.notifyNewCall()
        UIApplication.shared.windows.first?.addSubview(self)
    }

    private func onNewSignal(_ signal: LiveSignal) {
        if signal.type == LiveSignalType.BeingRequested.rawValue {
            if let beCallingSignal = signal.signalForType(
                LiveSignalType.BeingRequested.rawValue,
                BeingRequestedSignal.self)
            {
                if beCallingSignal.roomId == self.beCallingSignal?.roomId {
                    self.beCallingSignal = beCallingSignal
                }
            }
        } else if signal.type == LiveSignalType.CancelBeingRequested.rawValue {
            if let cancelSignal = signal.signalForType(
                LiveSignalType.CancelBeingRequested.rawValue,
                CancelBeingRequestedSignal.self)
            {
                if cancelSignal.roomId == self.beCallingSignal?.roomId {
                    dismiss()
                }
            }
        }
    }

    private func notifyNewCall() {
        guard let signal = self.beCallingSignal else { return }
        if signal.createTime + signal.timeoutTime
            < IMCoreManager.shared.severTime
        {
            // 对方呼叫信号超时
            dismiss()
        } else {
            AppUtils.newMessageNotify()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.notifyNewCall()
            }
        }
    }

    private func requestUser(_ id: Int64) {
        IMCoreManager.shared.userModule.queryUser(id: id)
            .compose(RxTransformer.shared.io2Main())
            .subscribe { [weak self] user in
                self?.updateUserView(user)
            }.disposed(by: self.disposeBag)
    }

    private func updateUserView(_ user: User) {
        self.nickView.text = user.nickname
        self.avatarView.renderImageByUrlWithCorner(
            url: user.avatar ?? "", radius: 10)
    }

    private func acceptCalling() {
        if let beCallingSignal = self.beCallingSignal {
            RTCRoomManager.shared.joinRoom(
                roomId: beCallingSignal.roomId, role: Role.Broadcaster.rawValue
            )
            .compose(RxTransformer.shared.io2Main())
            .subscribe { [weak self] room in
                self?.enterRoom(room)
                self?.dismiss()
            } onError: { [weak self] err in
                self?.dismiss()
            }.disposed(by: self.disposeBag)

        } else {
            dismiss()
        }
    }

    private func rejectCalling() {
        if let beCallingSignal = self.beCallingSignal {
            RTCRoomManager.shared.refuseJoinRoom(
                roomId: beCallingSignal.roomId, reason: "hangup"
            )
            .compose(RxTransformer.shared.io2Main())
            .subscribe {
            } onError: { [weak self] err in
                self?.dismiss()
            } onCompleted: { [weak self] in
                self?.dismiss()
            }.disposed(by: self.disposeBag)

        } else {
            dismiss()
        }
    }

    private func enterRoom(_ room: RTCRoom) {
        RTCRoomManager.shared.addRoom(room)
        if let window = UIApplication.shared.windows.first {
            if let vc = window.rootViewController {
                LiveCallViewController.popLiveCallViewController(
                    vc, room, .BeCalling, Set())
            }
        }
    }

    func dismiss() {
        self.removeFromSuperview()
    }

    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        super.touchesBegan(touches, with: event)
    //    }

}
