//
//  Provider.swift
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

public class Provider: IMProvider {
    
    public init(token: String) {
        ZLPhotoConfiguration.default()
            .cameraConfiguration
            .maxRecordDuration(300)
            .allowRecordVideo(true)
            .allowSwitchCamera(true)
            .showFlashSwitch(true)
        
        ZLPhotoConfiguration.default()
            .allowSelectGif(true)
            .allowEditImage(true)
            .allowEditVideo(true)
            .allowSelectOriginal(true)
    }
    
    public func openCamera(controller: UIViewController, formats: [IMFileFormat], imContentResult: @escaping IMContentResult) {
        let camera = ZLCustomCamera()
        camera.takeDoneBlock = { [weak self] image, videoUrl in
            guard let sf = self else {
                return
            }
            if (videoUrl != nil) {
                do {
                    let data = try Data(contentsOf: videoUrl!)
                    let ext = videoUrl!.pathExtension
                    let name = videoUrl!.lastPathComponent
                    sf.sendResult(data, name, "video/\(ext)", imContentResult)
                } catch {
                    DDLogError("\(error)")
                }
            } else if image != nil {
                if image!.pngData() != nil {
                    self?.sendResult(image!.pngData()!, "", "image/png", imContentResult)
                } else {
                    self?.sendResult(image!.jpegData(compressionQuality: 1.0)!, "", "image/jpeg", imContentResult)
                }
            }
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
                DDLogError("\(error)")
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
            PHCachingImageManager.default().requestImageDataAndOrientation(for: r.asset, options: nil)
            { [weak self] data,_,_,_ in
                if (data != nil) {
                    if (r.image.images != nil) {
                        self?.sendResult(data!, r.asset.zl.filename ?? "", "image/gif", imContentResult)
                    } else if r.image.pngData() != nil {
                        self?.sendResult(data!, r.asset.zl.filename ?? "","image/png", imContentResult)
                    } else {
                        self?.sendResult(data!, r.asset.zl.filename ?? "","image/jpeg", imContentResult)
                    }
                }
            }
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
                do {
                    let data = try Data(contentsOf: urlAsset.url)
                    let ext = urlAsset.url.pathExtension
                    let name = urlAsset.url.lastPathComponent
                    sf.sendResult(data, name, "video/\(ext)", imContentResult)
                } catch {
                    DDLogError("\(error)")
                }
            }
            break
        default:
            break
        }
    }
    
    
    private func sendResult(_ data: Data, _ name: String, _ mimeType: String, _ imContentResult: @escaping IMContentResult) {
        let file = IMFile(data: data, name: name, mimeType: mimeType)
        imContentResult([file], false)
    }
    
    
}
