//
//  FileLoadState.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation

/// 加载（上传/下载）状态
public enum FileLoadState: Int {
    case Wait = 0
    case
        Init = 1
    case
        Ing = 2
    case
        Success = 3
    case
        Failed = 4
}
