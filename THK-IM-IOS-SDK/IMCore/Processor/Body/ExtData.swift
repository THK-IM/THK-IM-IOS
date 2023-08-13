//
//  ExtData.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/10.
//

import Foundation

class ExtData: Codable {
    
    var state: Int
    var progress: Int
    
    init(_ state: Int, _ progress: Int) {
        self.state = state
        self.progress = progress
    }
    
    enum CodingKeys: String, CodingKey {
        case state = "state"
        case progress = "progress"
    }
}
