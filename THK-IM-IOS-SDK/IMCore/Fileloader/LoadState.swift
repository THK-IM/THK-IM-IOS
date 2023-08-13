//
//  LoadState.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation

enum LoadState : Int {
    case Wait = 0,
         Init = 1,
         Ing = 2,
         Success = 3,
         Failed = 4
}
