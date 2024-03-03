//
//  IMTextMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

open class IMTextMsgProcessor : IMBaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.Text.rawValue
    }
    
    open override func sessionDesc(msg: Message) -> String {
        if (msg.data != nil) {
            return super.sessionDesc(msg: msg) + msg.data!
        } else if (msg.content != nil) {
            guard let regex = try? NSRegularExpression(pattern: "(?<=@)(.+?)(?=\\s)") else {
                return super.sessionDesc(msg: msg) + msg.content!
            }
            let data = NSMutableString(string: msg.content!)
            let allRange = NSRange(msg.content!.startIndex..<msg.content!.endIndex, in: msg.content!)
            regex.matches(in: msg.content!, options: [], range: allRange).forEach { matchResult in
                if let idRange = Range.init(matchResult.range, in: msg.content!) {
                    let idStr = String(msg.content![idRange])
                    if let id = Int64(idStr) {
                        let user = IMCoreManager.shared.database.userDao().findById(id)
                        if (user != nil) {
                            let dataString = String(data)
                            let dataRange = NSRange(dataString.startIndex..<dataString.endIndex, in: dataString)
                            data.replaceOccurrences(of: idStr, with: user!.nickname, options: .caseInsensitive, range: dataRange)
                        }
                    }
                }
            }
            return super.sessionDesc(msg: msg) + String(data)
        } else {
            return super.sessionDesc(msg: msg)
        }
    }
}
