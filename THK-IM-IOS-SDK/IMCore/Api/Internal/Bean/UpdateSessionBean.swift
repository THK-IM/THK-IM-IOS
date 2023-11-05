//
//  UpdateSessionBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/5.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

class UpdateSessionBean: Codable {
    
    var uId: Int64
    var sId: Int64
    var top : Int64?
    var status: Int?
    
    init(uId: Int64, sId: Int64, top: Int64? = nil, status: Int? = nil) {
        self.uId = uId
        self.sId = sId
        self.top = top
        self.status = status
    }
    
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case sId = "s_id"
        case top = "top"
        case status = "status"
    }
}
