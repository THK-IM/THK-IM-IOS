//
//  IMContentProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/3.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public protocol IMProvider: AnyObject  {
    
    func openCamera(
        controller: UIViewController,
        formats: [IMFileFormat],
        imContentResult: @escaping IMContentResult
    )

    func pick(
        controller: UIViewController,
        formats: [IMFileFormat],
        imContentResult: @escaping IMContentResult)

    func startRecordAudio(path: String, duration: Int, audioCallback: @escaping AudioCallback) -> Bool

    func stopRecordAudio()

    func isRecordingAudio() -> Bool

    func startPlayAudio(path: String, audioCallback: @escaping AudioCallback) -> Bool

    func stopPlayAudio()
    
    func currentPlayingPath() -> String?

    func isPlayingAudio() -> Bool
}
