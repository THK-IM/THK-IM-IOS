//
//  CallingLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift
import UIKit

class CallingLayout: UIView {
    private let disposeBag = DisposeBag()

    private weak var liveProtocol: LiveCallProtocol? = nil

    private let switchMicro: UIButton = {
        let v = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.setImage(
            UIImage.init(named: "ic_micro_on")?.scaledToSize(CGSize(width: 36, height: 36)),
            for: .normal)
        v.setImage(
            UIImage.init(named: "ic_micro_off")?.scaledToSize(CGSize(width: 36, height: 36)),
            for: .selected)
        v.isSelected = false
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#80ffffff"),
                borderColor: UIColor.init(hex: "#80ffffff"),
                width: 60, height: 60), for: .selected)
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#ffffffff"),
                borderColor: UIColor.init(hex: "#ffffffff"),
                width: 60, height: 60), for: .normal)
        return v
    }()

    private let switchSpeaker: UIButton = {
        let v = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.setImage(
            UIImage.init(named: "ic_speaker_off")?.scaledToSize(CGSize(width: 36, height: 36)),
            for: .normal)
        v.setImage(
            UIImage.init(named: "ic_speaker_on")?.scaledToSize(CGSize(width: 36, height: 36)),
            for: .selected)
        v.isSelected = false
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#80ffffff"),
                borderColor: UIColor.init(hex: "#80ffffff"),
                width: 60, height: 60), for: .normal)
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#ffffffff"),
                borderColor: UIColor.init(hex: "#ffffffff"),
                width: 60, height: 60), for: .selected)
        return v
    }()

    private let openOrCloseCamera: UIButton = {
        let v = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.setImage(
            UIImage.init(named: "ic_camera_on")?.scaledToSize(CGSize(width: 36, height: 36)),
            for: .normal)
        v.setImage(
            UIImage.init(named: "ic_camera_off")?.scaledToSize(CGSize(width: 36, height: 36)),
            for: .selected)
        v.isSelected = false
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#80ffffff"),
                borderColor: UIColor.init(hex: "#80ffffff"),
                width: 60, height: 60), for: .selected)
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#ffffffff"),
                borderColor: UIColor.init(hex: "#ffffffff"),
                width: 60, height: 60), for: .normal)
        return v
    }()

    private let hungUpView: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = UIImage.init(named: "ic_call_hangup")
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let switchCameraView: UIButton = {
        let v = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        v.setImage(
            UIImage.init(named: "ic_switch_camera")?.scaledToSize(CGSize(width: 24, height: 24)),
            for: .normal)
        v.isSelected = false
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 24, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#80ffffff"),
                borderColor: UIColor.init(hex: "#80ffffff"),
                width: 48, height: 48), for: .selected)
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 24, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#ffffffff"),
                borderColor: UIColor.init(hex: "#ffffffff"),
                width: 48, height: 48), for: .normal)
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.addSubview(self.switchMicro)
        self.switchMicro.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.left.equalToSuperview().offset((UIScreen.main.bounds.width) / 4 - 60)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        self.switchMicro.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] in
                guard let sf = self else {
                    return
                }
                guard let liveProtocol = sf.liveProtocol else {
                    return
                }
                liveProtocol.room()?.muteMicrophone(!sf.switchMicro.isSelected)
                sf.switchMicro.isSelected = liveProtocol.room()?.isMicrophoneMuted() ?? true
            }).disposed(by: self.disposeBag)

        self.addSubview(self.switchSpeaker)
        self.switchSpeaker.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.left.equalToSuperview().offset(2 * (UIScreen.main.bounds.width) / 4 - 30)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        self.switchSpeaker.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] in
                guard let sf = self else {
                    return
                }
                guard let liveProtocol = sf.liveProtocol else {
                    return
                }
                liveProtocol.room()?.setSpeakerOn(!sf.switchSpeaker.isSelected)
                sf.switchSpeaker.isSelected = liveProtocol.room()?.isSpeakerOn() ?? true
            }).disposed(by: self.disposeBag)

        self.addSubview(self.openOrCloseCamera)
        self.openOrCloseCamera.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.left.equalToSuperview().offset(3 * (UIScreen.main.bounds.width) / 4)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        self.openOrCloseCamera.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] in
                guard let sf = self else {
                    return
                }
                guard let liveProtocol = sf.liveProtocol else {
                    return
                }
                liveProtocol.room()?.muteLocalVideoStream(mute: !sf.openOrCloseCamera.isSelected)
                sf.openOrCloseCamera.isSelected =
                    liveProtocol.room()?.isLocalVideoStreamMuted() ?? true
            }).disposed(by: self.disposeBag)

        self.addSubview(self.hungUpView)
        self.hungUpView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-100)
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerX.equalToSuperview()
        }
        self.hungUpView.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == self?.hungUpView
            }
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self] _ in
            self?.liveProtocol?.hangupCalling()
        })
        .disposed(by: disposeBag)

        self.addSubview(self.switchCameraView)
        self.switchCameraView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.centerY.equalTo(sf.hungUpView)
            make.width.equalTo(48)
            make.height.equalTo(48)
            make.left.equalTo(sf.hungUpView).offset(120)
        }
        self.switchCameraView.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] in
                guard let sf = self else {
                    return
                }
                guard let liveProtocol = sf.liveProtocol else {
                    return
                }
                liveProtocol.room()?.switchLocalCamera()
            }).disposed(by: self.disposeBag)

    }

    func initCall(_ callProtocol: LiveCallProtocol) {
        self.liveProtocol = callProtocol
        self.switchMicro.isSelected = callProtocol.room()?.isMicrophoneMuted() ?? true
        self.switchSpeaker.isSelected = callProtocol.room()?.isSpeakerOn() ?? true
        self.openOrCloseCamera.isSelected = callProtocol.room()?.isLocalVideoStreamMuted() ?? true
    }
}
