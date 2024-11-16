//
//  IMLiveRequestProcessor.swift
//  THK-IM-IOS
//
//  Created by think on 2024/11/16.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class IMLiveRequestProcessor: LiveRequestProcessor {

    private var processedRoomIds = Set<String>()

    func onBeingRequested(signal: BeingRequestedSignal) {
        if processedRoomIds.contains(signal.roomId) {
            return
        }
        processedRoomIds.insert(signal.roomId)

        let frame = CGRect(
            x: 20, y: 60, width: UIScreen.main.bounds.width - 40, height: 100)
        let beRequestedPopup = BeRequestedCallingPopup(frame: frame)
        beRequestedPopup.show(signal)
    }

    func onCancelBeingRequested(signal: CancelBeingRequestedSignal) {
        if processedRoomIds.contains(signal.roomId) {
            return
        }
    }

}
