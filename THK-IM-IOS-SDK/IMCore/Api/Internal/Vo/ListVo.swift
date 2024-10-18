//
//  ListVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

public class ListVo<T: Codable>: Codable {

    public var data: [T]

    public init(data: [T]) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
