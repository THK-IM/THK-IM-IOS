//
//  UpdateSessionVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/5.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public class UpdateSessionVo: Codable {
    
    var uId: Int64
    var sId: Int64
    var top : Int64?
    var noteName: String?
    var noteAvatar: String?
    var status: Int?
    var parentId: Int64?
    
    init(
        uId: Int64, sId: Int64, top: Int64? = nil, noteName: String? = nil, noteAvatar: String? = nil,
        status: Int? = nil, parentId: Int64? = nil
    ) {
        self.uId = uId
        self.sId = sId
        self.top = top
        self.noteName = noteName
        self.noteAvatar = noteAvatar
        self.status = status
        self.parentId = parentId
    }
    
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case sId = "s_id"
        case top = "top"
        case noteName = "note_name"
        case noteAvatar = "note_avatar"
        case status = "status"
        case parentId = "parent_id"
    }
}
