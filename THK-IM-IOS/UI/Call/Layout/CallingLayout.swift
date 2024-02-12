//
//  CallingLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class CallingLayout: UIView {
    private let disposeBag = DisposeBag()
    
    private weak var liveProtocol: LiveCallProtocol? = nil
    
    private let switchMicro: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40ffffff"), borderColor: UIColor.init(hex: "#40ffffff"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_micro_on"), for: .normal)
        contentView.setImage(UIImage.init(named: "ic_micro_off"), for: .selected)
        contentView.isSelected = true
        contentView.isUserInteractionEnabled = false
        v.addSubview(contentView)
        return v
    }()
    
    private let switchSpeaker: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40ffffff"), borderColor: UIColor.init(hex: "#40ffffff"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_speaker_on"), for: .normal)
        contentView.setImage(UIImage.init(named: "ic_speaker_off"), for: .selected)
        contentView.isSelected = true
        contentView.isUserInteractionEnabled = false
        v.addSubview(contentView)
        return v
    }()
    
    private let openOrCloseCamera: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40ffffff"), borderColor: UIColor.init(hex: "#40ffffff"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_open_camera"), for: .normal)
        contentView.setImage(UIImage.init(named: "ic_close_camera"), for: .selected)
        contentView.isSelected = true
        contentView.isUserInteractionEnabled = false
        v.addSubview(contentView)
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
        self.addSubview(self.switchMicro)
        self.switchMicro.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.left.equalToSuperview().offset((UIScreen.main.bounds.width) / 4 - 60)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        self.addSubview(self.switchSpeaker)
        self.switchSpeaker.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.left.equalToSuperview().offset(2 * (UIScreen.main.bounds.width) / 4 - 30)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        self.addSubview(self.openOrCloseCamera)
        self.openOrCloseCamera.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-200)
            make.left.equalToSuperview().offset(3 * (UIScreen.main.bounds.width) / 4)
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
        
        self.switchMicro.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == self?.switchMicro
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
//            if let liveProtocol = self?.liveProtocol {
//                liveProtocol.switchLocalCamera()
//            }
        })
        .disposed(by: disposeBag)
        
        self.switchSpeaker.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == self?.switchSpeaker
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
//            if let liveProtocol = self?.liveProtocol {
//                if liveProtocol.isCurrentCameraOpened() {
//                    liveProtocol.closeLocalCamera()
//                } else {
//                    liveProtocol.openLocalCamera()
//                }
//            }
        })
        .disposed(by: disposeBag)
        
        self.openOrCloseCamera.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == self?.openOrCloseCamera
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            if let liveProtocol = self?.liveProtocol {
                if liveProtocol.isLocalVideoMuted() {
                    liveProtocol.muteLocalVideo(mute: false)
                } else {
                    liveProtocol.muteLocalVideo(mute: true)
                }
            }
        })
        .disposed(by: disposeBag)
        
        self.hungUpView.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == self?.hungUpView
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            self?.liveProtocol?.hangup()
        })
        .disposed(by: disposeBag)
    }
    
    
    func initCall(_ callProtocol: LiveCallProtocol) {
        self.liveProtocol = callProtocol
    }
}
