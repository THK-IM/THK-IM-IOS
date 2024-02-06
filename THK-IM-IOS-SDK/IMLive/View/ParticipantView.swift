//
//  ParticipantView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import WebRTC
import RxSwift

class ParticipantView: UIView {
    
    var p: BaseParticipant? = nil
    private var isFullScreen = true
    
    private let disposeBag = DisposeBag()
    
    var defaultScaleX = 0.35
    var defaultScaleY = 0.3
    
    lazy var eAGLVideoView: RTCEAGLVideoView = {
        let v = RTCEAGLVideoView()
        v.contentMode = .scaleAspectFill
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.addSubview(self.eAGLVideoView)
        self.eAGLVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setParticipant(p: BaseParticipant) {
        self.p = p
        self.p?.attachViewRender(self.eAGLVideoView)
        self.p?.initPeerConnection()
    }
    
    func setFullScreen(_ fullScreen: Bool) {
        if self.isFullScreen == fullScreen {
            return
        }
        self.isFullScreen = fullScreen
        if self.isFullScreen {
            self.switchToFullScreen()
        } else {
            self.switchToDragView()
        }
    }
    
    private func switchToFullScreen() {
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            let scaleTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            let positionTransform = CGAffineTransform(translationX: 0, y: 0)
            let combinedTransform = scaleTransform.concatenating(positionTransform)
            self?.transform = combinedTransform
        })
    }
    
    private func switchToDragView() {
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            guard let sf = self else {
                return
            }
            let translationX = (UIScreen.main.bounds.width * (1 - sf.defaultScaleX))*0.5
            let translationY = (0 - UIScreen.main.bounds.height * (1 - sf.defaultScaleY))*0.5
            let scaleTransform = CGAffineTransform(scaleX: sf.defaultScaleX, y: sf.defaultScaleY)
            let positionTransform = CGAffineTransform(translationX: translationX, y: translationY)
            let combinedTransform = scaleTransform.concatenating(positionTransform)
            sf.transform = combinedTransform
        })
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isFullScreen {
            return
        }
        guard let touch = touches.first else {
            return
        }
        let current = touch.location(in: self)
        let pre = touch.previousLocation(in: self)
        var translationX = self.transform.tx + (current.x - pre.x) * defaultScaleX
        var translationY = self.transform.ty + (current.y - pre.y) * defaultScaleY
        
        translationX = min(translationX, UIScreen.main.bounds.width * (1 - defaultScaleX)*0.5)
        translationX = max(translationX, -UIScreen.main.bounds.width * (1 - defaultScaleX)*0.5)
        translationY = min(translationY, UIScreen.main.bounds.height * (1 - defaultScaleY)*0.5)
        translationY = max(translationY, -UIScreen.main.bounds.height * (1 - defaultScaleY)*0.5)
        
        self.transform.tx = translationX
        self.transform.ty = translationY
    }
    
    
}
