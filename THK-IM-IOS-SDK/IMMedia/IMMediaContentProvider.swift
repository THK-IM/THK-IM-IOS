//
//  IMMediaContentProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/3.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import Photos
import AVFoundation
import ZLPhotoBrowser
import CocoaLumberjack

public class IMMediaContentProvider: IMContentProvider {
    
    init(token: String) {
        IMAVCacheManager.shared.setToken(token: token)
    }
    
    public func openCamera(controller: UIViewController, formats: [IMFileFormat], imContentResult: @escaping IMContentResult) {
        ZLPhotoConfiguration.default()
            .cameraConfiguration
            .maxRecordDuration(300)
            .allowRecordVideo(true)
            .allowSwitchCamera(true)
            .showFlashSwitch(true)

        let camera = ZLCustomCamera()
        camera.takeDoneBlock = { [weak self] image, videoUrl in
            guard let sf = self else {
                return
            }
            sf.sendResult(image, url: videoUrl, imContentResult)
        }
        controller.showDetailViewController(camera, sender: nil)
    }
    
    public func pick(controller: UIViewController, formats: [IMFileFormat], imContentResult: @escaping IMContentResult) {
        let ps = ZLPhotoPreviewSheet()
        ps.selectImageBlock = { [weak self] results, isOriginal in
            guard let sf = self else {
                return
            }
            do {
                for r in results {
                    try sf.onMediaResult(r, isOriginal, imContentResult)
                }
            } catch {
                DDLogError(error)
            }
        }
        ps.showPhotoLibrary(sender: controller)
    }
    
    public func startRecordAudio(path: String, duration: Int, audioCallback: @escaping AudioCallback) -> Bool {
       return OggOpusAudioRecorder.shared.startRecording(path, duration, audioCallback)
    }
    
    public func stopRecordAudio() {
        OggOpusAudioRecorder.shared.stopRecording()
    }
    
    public func isRecordingAudio() -> Bool {
        return OggOpusAudioRecorder.shared.isRecording()
    }
    
    public func startPlayAudio(path: String, audioCallback: @escaping AudioCallback) -> Bool {
        return OggOpusAudioPlayer.shared.startPlaying(path, audioCallback)
    }
    
    public func stopPlayAudio() {
        OggOpusAudioPlayer.shared.stopPlaying()
    }
    
    public func isPlayingAudio() -> Bool {
        return OggOpusAudioPlayer.shared.isPlaying()
    }
    
    private func onMediaResult(_ r: ZLResultModel, _ isOriginal: Bool, _ imContentResult: @escaping IMContentResult) throws {
        switch r.asset.mediaType {
        case PHAssetMediaType.image:
            self.sendResult(r.image, url: nil, imContentResult)
            break
        case PHAssetMediaType.video:
            PHCachingImageManager.default()
                .requestAVAsset(forVideo: r.asset, options: nil)
            { [weak self] asset, audioMix, info in
                guard let urlAsset = asset as? AVURLAsset else {
                    return
                }
                guard let sf = self else {
                    return
                }
                sf.sendResult(r.image, url: urlAsset.url, imContentResult)
            }
            break
        default:
            break
        }
    }
    
    
    private func sendResult(_ image: UIImage?, url: URL?, _ imContentResult: @escaping IMContentResult) {
        if (url != nil) {
            let file = IMFile(image: image, url: url, mimeType: "video/**")
            imContentResult([file], false)
        } else if (image != nil) {
            let file = IMFile(image: image, url: nil, mimeType: "image/**")
            imContentResult([file], false)
        }
    }
    
    
}
