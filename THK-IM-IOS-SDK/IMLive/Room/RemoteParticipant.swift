//
//  RemoteParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import WebRTC
import CocoaLumberjack

open class RemoteParticipant: BaseParticipant {

    private let audioEnable: Bool
    private let videoEnable: Bool
    private let subStreamKey: String
    private var streamKey: String? = nil

    init(
        uId: Int64, roomId: String, role: Int, subStreamKey: String,
        audioEnable: Bool, videoEnable: Bool
    ) {
        self.subStreamKey = subStreamKey
        self.audioEnable = audioEnable
        self.videoEnable = videoEnable
        super.init(uId: uId, roomId: roomId, role: role)
    }

    open override func initPeerConnection() {
        super.initPeerConnection()
        guard let p = self.peerConnection else {
            return
        }
        if self.audioEnable && role == Role.Broadcaster.rawValue {
            let audioTransceiver = RTCRtpTransceiverInit()
            audioTransceiver.direction = .recvOnly
            p.addTransceiver(of: .audio, init: audioTransceiver)
        }
        if self.videoEnable && role == Role.Broadcaster.rawValue  {
            let videoTransceiver = RTCRtpTransceiverInit()
            videoTransceiver.direction = .recvOnly
            p.addTransceiver(of: .video, init: videoTransceiver)
        }
    }

    open override func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
        super.onLocalSdpSetSuccess(sdp)
        let offer = sdp.sdp
        guard let offerBase64 = offer.data(using: .utf8)?.base64EncodedString() else {
            return
        }

        let req = PlayStreamReqVo(
            uId: RTCRoomManager.shared.myUId,
            roomId: self.roomId,
            offerSdp: offerBase64,
            streamKey: self.subStreamKey
        )
        RTCRoomManager.shared.liveApi.playStream(req)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(
                onNext: { [weak self] bean in
                    let data = Data(base64Encoded: bean.answerSdp) ?? Data()
                    let answer = String(data: data, encoding: .utf8) ?? ""
                    self?.streamKey = bean.streamKey
                    let remoteSdp = RTCSessionDescription.init(type: .answer, sdp: answer)
                    self?.setRemoteSessionDescription(remoteSdp)
                },
                onError: { [weak self] err in
                    self?.onError("playStream", err)
                }
            ).disposed(by: self.disposeBag)

    }

    open override func pushStreamKey() -> String? {
        return subStreamKey
    }

    open override func playStreamKey() -> String? {
        return streamKey
    }
}
