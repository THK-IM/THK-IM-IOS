//
//  LiveMediaConstraints.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/11/20.
//  Copyright © 2024 THK. All rights reserved.
//

import WebRTC

public class LiveMediaConstraints {

    public static func build(
        enable3a: Bool,
        enableCpu: Bool,
        enableGainControl: Bool,
        enableStereo: Bool
    ) -> RTCMediaConstraints {
        var enable3aStr = ""
        if enable3a { enable3aStr = "true" } else { enable3aStr = "false" }
        var mandatoryConstraints = [String: String]()
        //回声消除
        mandatoryConstraints["googEchoCancellation2"] = enable3aStr
        //高音过滤
        mandatoryConstraints["googHighpassFilter2"] = enable3aStr
        //噪音处理
        mandatoryConstraints["googNoiseSuppression2"] = enable3aStr
        //噪音处理
        mandatoryConstraints["googAudioMirroring"] = enable3aStr
        //噪音处理
        mandatoryConstraints["googNoiseSuppression2"] = enable3aStr

        var enableCpuStr = ""
        if enableCpu { enableCpuStr = "true" } else { enableCpuStr = "false" }
        //cpu过载监控
        mandatoryConstraints["googCpuOveruseDetection"] = enableCpuStr

        var enableGainControlStr = ""
        if enableGainControl {
            enableGainControlStr = "true"
        } else {
            enableGainControlStr = "false"
        }
        mandatoryConstraints["googAutoGainControl2"] = enableGainControlStr

        var enableStereoStr = ""
        if enableStereo {
            enableStereoStr = "true"
        } else {
            enableStereoStr = "false"
        }
        mandatoryConstraints["stereo"] = enableStereoStr
        
        let constraints = RTCMediaConstraints.init(
            mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        return constraints
    }
    
    
    public static func offerOrAnswerConstraint(isReceive: Bool, enableStereo: Bool) -> RTCMediaConstraints {
        
        var mandatoryConstraints = [String: String]()
        if isReceive {
            mandatoryConstraints["OfferToReceiveAudio"] = "true"
            mandatoryConstraints["OfferToReceiveVideo"] = "true"
        } else {
            mandatoryConstraints["OfferToReceiveAudio"] = "false"
            mandatoryConstraints["OfferToReceiveVideo"] = "false"
        }
        mandatoryConstraints["googCpuOveruseDetection"] = "false"
        
        var enableStereoStr = ""
        if enableStereo {
            enableStereoStr = "true"
        } else {
            enableStereoStr = "false"
        }
        mandatoryConstraints["stereo"] = enableStereoStr
        
        let mediaConstraints = RTCMediaConstraints(
            mandatoryConstraints: mandatoryConstraints,
            optionalConstraints: nil
        )
        return mediaConstraints
   }

}
