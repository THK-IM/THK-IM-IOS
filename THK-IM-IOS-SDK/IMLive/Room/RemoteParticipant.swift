//
//  RemoteParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/1.
//

import Foundation
import WebRTC

class RemoteParticipant: BaseParticipant {
    
    private let streamKey: String
    
    init(uId: String, channelId: String, streamKey: String) {
        self.streamKey = streamKey
        super.init(uId: uId, channelId: channelId)
    }
    
    override func initPeerConnection() {
        super.initPeerConnection()
        guard let p = self.getRTCPeerConnection() else {
            return
        }
        let transceiver = RTCRtpTransceiverInit()
        transceiver.direction = .recvOnly
        p.addTransceiver(of: .audio, init: transceiver)
        p.addTransceiver(of: .video, init: transceiver)
        
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
                PlayReqBean(uid: self.uId, roomId: self.channelId, offerSdp: offerBase64, streamKey: self.streamKey))
            )
            .asObservable()
            .compose(DefaultRxTransformer.io2Main())
            .compose(DefaultRxTransformer.response2Bean(PlayResBean.self))
            .subscribe(onNext: { [weak self] bean in
                let data = Data(base64Encoded: bean.answerSdp) ?? Data()
                let answer = String(data: data, encoding: .utf8) ?? ""
                let remoteSdp = RTCSessionDescription(type: .answer, sdp: answer)
                self?.setRemoteSessionDescription(remoteSdp)
            }, onError: { err in
                
            }).disposed(by: self.disposeBag)
            
    }
}
