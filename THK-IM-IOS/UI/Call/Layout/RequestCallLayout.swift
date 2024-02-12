//
//  RequestCallLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class RequestCallLayout: UIView {
    private let disposeBag = DisposeBag()
    
    private weak var liveProtocol: LiveCallProtocol? = nil
    
    private let switchCameraView: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40ffffff"), borderColor: UIColor.init(hex: "#40ffffff"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_switch_camera"), for: .normal)
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
        let left = (UIScreen.main.bounds.width-160) / 2 - 60
        self.addSubview(self.switchCameraView)
        self.switchCameraView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-300)
            make.left.equalToSuperview().offset(left)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        self.addSubview(self.openOrCloseCamera)
        self.openOrCloseCamera.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-300)
            make.right.equalToSuperview().offset(-(left))
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        self.addSubview(self.hungUpView)
        self.hungUpView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-180)
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerX.equalToSuperview()
        }
        
        self.switchCameraView.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == self?.switchCameraView
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            if let liveProtocol = self?.liveProtocol {
                liveProtocol.switchLocalCamera()
            }
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
                if liveProtocol.isCurrentCameraOpened() {
                    liveProtocol.closeLocalCamera()
                } else {
                    liveProtocol.openLocalCamera()
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
