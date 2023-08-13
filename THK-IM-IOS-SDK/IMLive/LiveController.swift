//
//  LiveController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import UIKit
import WebRTC

class LiveController: UIViewController {
    
    lazy var eAGLVideoView: RTCEAGLVideoView = {
        let v = RTCEAGLVideoView()
        return v
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.eAGLVideoView)
        self.eAGLVideoView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(400)
        }
        
        LiveManager.shared.joinRoom()
        LiveManager.shared.currentRoom().getLocalParticipant()?.attachViewRender(self.eAGLVideoView)
    }
    
    deinit {
        LiveManager.shared.leaveRoom()
    }
}
