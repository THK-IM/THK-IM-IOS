//
//  RequestCallLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift
import UIKit

class RequestCallLayout: UIView {
    private let disposeBag = DisposeBag()

    private weak var liveProtocol: LiveCallProtocol? = nil

    private let switchCameraView: UIButton = {
        let v = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.setImage(
            UIImage.init(named: "ic_switch_camera")?.scaledToSize(CGSize(width: 36, height: 36)),
            for: .normal)
        v.isSelected = false
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#80ffffff"),
                borderColor: UIColor.init(hex: "#80ffffff"),
                width: 60, height: 60), for: .normal)
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
                width: 60, height: 60), for: .normal)
        v.setBackgroundImage(
            Bubble().drawRectWithRoundedCorner(
                radius: 30, borderWidth: 0,
                backgroundColor: UIColor.init(hex: "#ffffffff"),
                borderColor: UIColor.init(hex: "#ffffffff"),
                width: 60, height: 60), for: .selected)
        return v
    }()

    private let hungUpView: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = UIImage.init(named: "ic_call_hangup")
        v.contentMode = .scaleAspectFit
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
        let left = (UIScreen.main.bounds.width - 160) / 2 - 60
        self.addSubview(self.switchCameraView)
        self.switchCameraView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.left.equalToSuperview().offset(left)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        self.addSubview(self.openOrCloseCamera)
        self.openOrCloseCamera.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.right.equalToSuperview().offset(-(left))
            make.width.equalTo(60)
            make.height.equalTo(60)
        }

        self.addSubview(self.hungUpView)
        self.hungUpView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-100)
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerX.equalToSuperview()
        }

        self.switchCameraView.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] _ in
                if let liveProtocol = self?.liveProtocol {
                    liveProtocol.switchLocalCamera()
                }
            })
            .disposed(by: disposeBag)

        self.openOrCloseCamera.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let sf = self else {
                    return
                }
                guard let liveProtocol = sf.liveProtocol else {
                    return
                }
                liveProtocol.muteLocalVideo(mute: !sf.openOrCloseCamera.isSelected)
                sf.openOrCloseCamera.isSelected = liveProtocol.isLocalVideoMuted()
            })
            .disposed(by: disposeBag)

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
            self?.liveProtocol?.hangup()
        })
        .disposed(by: disposeBag)
    }

    func initCall(_ callProtocol: LiveCallProtocol) {
        self.liveProtocol = callProtocol
        self.openOrCloseCamera.isSelected = callProtocol.isLocalVideoMuted()
    }

}
