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
        enableGainControl: Bool
    ) -> RTCMediaConstraints {
        var enable3aStr = ""
        if enable3a { enable3aStr = "true" } else { enable3aStr = "false" }
        var mandatoryConstraints = [String: String]()
        //回声消除
        mandatoryConstraints["googEchoCancellation"] = enable3aStr
        //高音过滤
        mandatoryConstraints["googHighpassFilter"] = enable3aStr
        //噪音处理
        mandatoryConstraints["googNoiseSuppression"] = enable3aStr

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
        mandatoryConstraints["googCpuOveruseDetection"] = enableGainControlStr

        let constraints = RTCMediaConstraints.init(
            mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        return constraints
    }

}
