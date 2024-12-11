//
//  LiveAudioDeviceModule.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/12/11.
//  Copyright © 2024 THK. All rights reserved.
//
import WebRTC


class LiveAudioDeviceModule: RTCAudioDeviceModule {
    
    override func startRecording() -> Bool {
        return true
    }
    
}
