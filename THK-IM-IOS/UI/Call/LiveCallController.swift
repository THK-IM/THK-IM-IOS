//
//  LiveCallController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class LiveCallController: BaseViewController {
    
    static func startLiveCallViewController(_ from: UIViewController, _ mode: Mode, _ user: User, _ roomId: String?) {
        let vc = LiveCallController()
        vc.roomId = roomId
        vc.mode = mode.rawValue
        vc.user = user
        from.navigationController?.pushViewController(vc, animated: true)
    }
    
    var roomId: String?
    var user: User?
    var mode: Int = 0
    
    private let beCallLayout: BeCallingLayout = {
        let view = BeCallingLayout()
        return view
    }()
    
    private let callingLayout: CallingLayout = {
        let view = CallingLayout()
        return view
    }()
    
    private let requestCallLayout: RequestCallLayout = {
        let view = RequestCallLayout()
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
    }
    
    private func showRequestCallView() {
        
    }
    
    private func showCallingView() {
        
    }
    
    private func showBeCallingView() {
        
    }
    
}

extension LiveCallController: LiveCallProtocol {
    func currentLocalCamera() -> Int {
        return 0
    }
    
    func isCurrentCameraOpened() -> Bool {
        return false
    }
    
    func switchLocalCamera() {
    }
    
    func openLocalCamera() {
    }
    
    func closeLocalCamera() {
    }
    
    func openRemoteVideo(user: User) {
    }
    
    func closeRemoteVideo(user: User) {
    }
    
    func openRemoteAudio(user: User) {
    }
    
    func closeRemoteAudio(user: User) {
    }
    
    func accept() {
    }
    
    func hangup() {
    }
    
    
}
