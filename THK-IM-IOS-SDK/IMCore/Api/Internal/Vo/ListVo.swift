//
//  ListVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation


public class ListVo<T: Codable> : Codable {
    
    var data: Array<T>
    
    public init(data: Array<T>) {
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
