//
//  UploadParams.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public class UploadParams: Codable {
    let id: Int64
    let url: String
    let method: String
    let params: [String: String]

    init(id: Int64, url: String, method: String, params: [String: String]) {
        self.id = id
        self.url = url
        self.method = method
        self.params = params
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case url = "url"
        case method = "method"
        case params = "params"
    }
}
