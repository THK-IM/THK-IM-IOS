//
//  RemoteParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import WebRTC

class RemoteParticipant: BaseParticipant {
    
    private let audioEnable: Bool
    private let videoEnable: Bool
    private let subStreamKey: String
    private var streamKey: String? = nil
    
    init(uId: String, roomId: String, role: Role, subStreamKey: String, audioEnable: Bool, videoEnable: Bool) {
        self.subStreamKey = subStreamKey
        self.audioEnable = audioEnable
        self.videoEnable = videoEnable
        super.init(uId: uId, roomId: roomId, role: role)
    }
    
    override func initPeerConnection() {
        super.initPeerConnection()
        guard let p = self.peerConnection else {
            return
        }
        if self.audioEnable && role == Role.Broadcaster {
            let audioTransceiver = RTCRtpTransceiverInit()
            audioTransceiver.direction = .recvOnly
            p.addTransceiver(of: .audio, init: audioTransceiver)
        }
        if self.videoEnable && role == Role.Broadcaster {
            let videoTransceiver = RTCRtpTransceiverInit()
            videoTransceiver.direction = .recvOnly
            p.addTransceiver(of: .video, init: videoTransceiver)
        }
        
        self.startPeerConnection()
    }
    
    override func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
        super.onLocalSdpSetSuccess(sdp)
        let offer = sdp.sdp
        guard let offerBase64 = offer.data(using: .utf8)?.base64EncodedString() else {
            return
        }
        
        self.liveApi.rx
            .request(.requestPlay(
                PlayReqBean(uid: self.uId, roomId: self.roomId, offerSdp: offerBase64, streamKey: self.subStreamKey))
            )
            .asObservable()
            .compose(DefaultRxTransformer.io2Main())
            .compose(DefaultRxTransformer.response2Bean(PlayResBean.self))
            .subscribe(onNext: { [weak self] bean in
                let data = Data(base64Encoded: bean.answerSdp) ?? Data()
                let answer = String(data: data, encoding: .utf8) ?? ""
                self?.streamKey = bean.streamKey
                let remoteSdp = RTCSessionDescription(type: .answer, sdp: answer)
                self?.setRemoteSessionDescription(remoteSdp)
            }, onError: { err in
                
            }).disposed(by: self.disposeBag)
            
    }
    
    override func pushStreamKey() -> String? {
        return subStreamKey
    }
    
    override func playStreamKey() -> String? {
        return streamKey
    }
}
