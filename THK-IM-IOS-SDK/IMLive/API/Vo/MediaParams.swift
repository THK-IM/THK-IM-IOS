//
//  MediaParams.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/31.
//  Copyright © 2024 THK. All rights reserved.
//

public class MediaParams: Codable {
    
    static let R169_H90 = MediaParams(videoMaxBitrate: 90_000, audioMaxBitrate: 48_000, videoWidth: 160, videoHeight: 90, videoFps: 15)
    static let R169_H180 = MediaParams(videoMaxBitrate: 160_000, audioMaxBitrate: 48_000, videoWidth: 320, videoHeight: 180, videoFps: 15)
    static let R169_H216 = MediaParams(videoMaxBitrate: 180_000, audioMaxBitrate: 48_000, videoWidth: 384, videoHeight: 216, videoFps: 15)
    static let R169_H360 = MediaParams(videoMaxBitrate: 450_000, audioMaxBitrate: 48_000, videoWidth: 640, videoHeight: 360, videoFps: 30)
    static let R169_H540 = MediaParams(videoMaxBitrate: 800_000, audioMaxBitrate: 48_000, videoWidth: 960, videoHeight: 540, videoFps: 30)
    static let R169_H720 = MediaParams(videoMaxBitrate: 1_700_000, audioMaxBitrate: 48_000, videoWidth: 1280, videoHeight: 720, videoFps: 30)
    static let R169_H1080 = MediaParams(videoMaxBitrate: 3_000_000, audioMaxBitrate: 48_000, videoWidth: 1920, videoHeight: 1080, videoFps: 30)
    static let R169_H1440 = MediaParams(videoMaxBitrate: 5_000_000, audioMaxBitrate: 48_000, videoWidth: 2560, videoHeight: 1440, videoFps: 30)
    static let R169_H2160 = MediaParams(videoMaxBitrate: 8_000_000, audioMaxBitrate: 48_000, videoWidth: 3840, videoHeight: 2160, videoFps: 30)
    static let H43_H120 = MediaParams(videoMaxBitrate: 70_000, audioMaxBitrate: 48_000, videoWidth: 160, videoHeight: 120, videoFps: 15)
    static let H43_H180 = MediaParams(videoMaxBitrate: 125_000, audioMaxBitrate: 48_000, videoWidth: 240, videoHeight: 180, videoFps: 15)
    static let H43_H240 = MediaParams(videoMaxBitrate: 140_000, audioMaxBitrate: 48_000, videoWidth: 320, videoHeight: 240, videoFps: 15)
    static let H43_H360 = MediaParams(videoMaxBitrate: 330_000, audioMaxBitrate: 48_000, videoWidth: 480, videoHeight: 360, videoFps: 30)
    static let H43_H480 = MediaParams(videoMaxBitrate: 500_000, audioMaxBitrate: 48_000, videoWidth: 640, videoHeight: 480, videoFps: 30)
    static let H43_H540 = MediaParams(videoMaxBitrate: 600_000, audioMaxBitrate: 48_000, videoWidth: 720, videoHeight: 540, videoFps: 30)
    static let H43_H720 = MediaParams(videoMaxBitrate: 1_300_000, audioMaxBitrate: 48_000, videoWidth: 960, videoHeight: 720, videoFps: 30)
    static let H43_H1080 = MediaParams(videoMaxBitrate: 2_300_000, audioMaxBitrate: 48_000, videoWidth: 1440, videoHeight: 1080, videoFps: 30)
    static let H43_H1440 = MediaParams(videoMaxBitrate: 3_800_000, audioMaxBitrate: 48_000, videoWidth: 1920, videoHeight: 1440, videoFps: 30)
    
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
