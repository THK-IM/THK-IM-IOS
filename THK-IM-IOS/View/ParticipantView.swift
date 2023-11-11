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
    
    private let disposeBag = DisposeBag()
    
    lazy var eAGLVideoView: RTCEAGLVideoView = {
        let v = RTCEAGLVideoView()
        v.contentMode = .scaleAspectFill
        return v
    }()
    
    lazy var muteAudioView: UIButton = {
        let button = UIButton(type:.custom)
        let on = UIImage(named: "live_audio_record_on")
        let off = UIImage(named: "live_audio_record_off")
        button.setImage(on, for: .normal)
        button.setImage(off, for: .selected)
        button.imageView?.contentMode = .scaleAspectFill
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    lazy var muteVideoView: UIButton = {
        let button = UIButton(type:.custom)
        let on = UIImage(named: "live_video_record_on")
        let off = UIImage(named: "live_video_record_off")
        button.setImage(on, for: .normal)
        button.setImage(off, for: .selected)
        button.imageView?.contentMode = .scaleAspectFill
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    var p: BaseParticipant? = nil
    
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
        self.addSubview(self.muteVideoView)
        self.muteVideoView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-4)
            make.right.equalToSuperview().offset(-4)
            make.width.equalTo(16)
            make.height.equalTo(16)
        }
        
        self.addSubview(self.muteAudioView)
        self.muteAudioView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-4)
            make.right.equalTo(sf.muteVideoView.snp.left).offset(-4)
            make.width.equalTo(16)
            make.height.equalTo(16)
        }
        
        self.muteAudioView.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let sf = self else {
                    return
                }
                guard let p = sf.p else {
                    return
                }
                let muted = p.getAudioMuted()
                p.setAudioMuted(!muted)
                sf.muteAudioView.isSelected = !muted
            })
            .disposed(by: self.disposeBag)
        
        self.muteVideoView.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let sf = self else {
                    return
                }
                guard let p = sf.p else {
                    return
                }
                let muted = p.getVideoMuted()
                p.setVideoMuted(!muted)
                sf.muteVideoView.isSelected = !muted
            })
            .disposed(by: self.disposeBag)
    }
    
    func setParticipant(p: BaseParticipant) {
        self.p = p
        self.p?.attachViewRender(self.eAGLVideoView)
        self.p?.initPeerConnection()
    }
    
    
}
