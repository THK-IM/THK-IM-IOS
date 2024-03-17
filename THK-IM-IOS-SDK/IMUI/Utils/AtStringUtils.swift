//
//  AtStringUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/5.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation


public class AtStringUtils {
    
    public typealias findIdByNickname =  (_ nickname: String) -> Int64
    public typealias findNicknameById =  (_ id: Int64) -> String
    
    public static let atRegular = "(?<=@)(.+?)(?=\\s)"
    
    public static func replaceAtNickNamesToUIds(_ text: String, _ finder: findIdByNickname) -> (String, String?) {
        let replacement = NSMutableString(string: text)
        guard let regex = try? NSRegularExpression(pattern: atRegular) else {
            return (text, nil)
        }
        let allRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var atUIds = ""
        regex.matches(in: text, options: [], range: allRange).forEach { matchResult in
            if let nickRange = Range.init(matchResult.range, in: text) {
                let nickName = String(text[nickRange])
                let id = finder(nickName)
                if (!atUIds.isEmpty) {
                    atUIds += "#"
                }
                atUIds += "\(id)"
                replacement.replaceOccurrences(of:nickName, with: "\(id)", options: .caseInsensitive, range: matchResult.range)
            }
        }
        return (String(replacement), atUIds.length == 0 ? nil : atUIds)
    }

    public static func replaceAtUIdsToNickname(_ text: String, _ atUIds: Set<Int64>, _ finder: findNicknameById) -> String {
        let replacement = NSMutableString(string: text)
        guard let regex = try? NSRegularExpression(pattern: atRegular) else {
            return text
        }
        let allRange = NSRange(text.startIndex..<text.endIndex, in: text)
        regex.matches(in: text, options: [], range: allRange).forEach { matchResult in
            if let idRange = Range.init(matchResult.range, in: text) {
                if let id = Int64(text[idRange]) {
                    if atUIds.contains(id) {
                        let nickname = finder(id)
                        replacement.replaceOccurrences(
                            of:String(id),
                            with: nickname,
                            options: .caseInsensitive,
                            range: matchResult.range
                        )
                    }
                }
            }
        }
        return String(replacement)
    }
}


