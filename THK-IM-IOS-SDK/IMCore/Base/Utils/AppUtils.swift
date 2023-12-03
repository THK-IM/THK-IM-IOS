//
//  NotifyUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/18.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import AVFoundation
import CocoaLumberjack

public class AppUtils {
    
    public static func newMessageNotify() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            let isSilentMode = audioSession.secondaryAudioShouldBeSilencedHint
            if isSilentMode {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            } else {
                let systemSoundID: SystemSoundID = 1007
                AudioServicesPlaySystemSound(systemSoundID)
            }
        }
        catch {
            DDLogError("\(error)")
        }
    }
    
}
