//
//  MediaParams.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/31.
//  Copyright © 2024 THK. All rights reserved.
//

public class MediaParams: Codable {
    
    let videoMaxBitrate: Int
    let audioMaxBitrate: Int
    let videoWidth: Int
    let videoHeight: Int
    let videoFps: Int

    enum CodingKeys: String, CodingKey {
        case videoMaxBitrate = "video_max_bitrate"
        case audioMaxBitrate = "audio_max_bitrate"
        case videoWidth = "video_width"
        case videoHeight = "video_height"
        case videoFps = "video_fps"
    }
    
    init(videoMaxBitrate: Int, audioMaxBitrate: Int, videoWidth: Int, videoHeight: Int, videoFps: Int) {
        self.videoMaxBitrate = videoMaxBitrate
        self.audioMaxBitrate = audioMaxBitrate
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
        self.videoFps = videoFps
    }
}

