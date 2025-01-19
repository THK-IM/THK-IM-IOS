//
//  IMDemoResourceProvider.swift
//  THK-IM-IOS
//
//  Created by think on 2024/11/9.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class IMDemoResourceProvider: IMUIResourceProvider {

    func supportFunction(_ session: THK_IM_IOS.Session, _ functionFlag: Int64)
        -> Bool
    {
        return session.functionFlag & functionFlag != 0
    }

    func msgBubble(message: Message, session: Session?) -> UIImage? {
        if message.type == MsgType.Revoke.rawValue {
            return Bubble().drawRectWithRoundedCorner(
                radius: 12, borderWidth: 0, backgroundColor: UIColor.white,
                borderColor: .clear,
                width: 40, height: 40, corners: [12, 12, 12, 12]
            )
        }

        if message.fromUId == IMCoreManager.shared.uId {
            return Bubble().drawRectWithRoundedCorner(
                radius: 12, borderWidth: 0, backgroundColor: UIColor.white,
                borderColor: .clear,
                width: 40, height: 40, corners: [12, 0, 12, 12]
            )
        } else if message.fromUId == 0 {
            return Bubble().drawRectWithRoundedCorner(
                radius: 12, borderWidth: 0, backgroundColor: UIColor.white,
                borderColor: .clear,
                width: 40, height: 40, corners: [12, 12, 12, 12]
            )
        } else {
            return Bubble().drawRectWithRoundedCorner(
                radius: 12, borderWidth: 0, backgroundColor: UIColor.white,
                borderColor: .clear,
                width: 40, height: 40, corners: [0, 12, 12, 12]
            )
        }
    }

    func tintColor() -> UIColor? {
        return UIColor.init(hex: "00FF00")
    }

    func inputBgColor() -> UIColor? {
        return UIColor.init(hex: "F4F4F4")
    }

    func layoutBgColor() -> UIColor? {
        return .white
    }

    private var emojis = [
        "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "🫠", "😉", "😊", "😇",
        "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝", "🤑",
        "🤗", "🤭", "🫢", "🫣", "🤫", "🤔", "🫡", "😌", "😔", "😪", "🤤", "😴", "😭", "😱",
        "😖", "😣", "😞", "😓", "😩", "😫", "🥱", "😤", "😡", "🤡", "🤖", "😺", "😸", "😹",
        "😻", "😼", "😽", "🙀", "😿", "😾", "💔", "🩷", "💢", "💥", "💫", "💦", "💋", "💤",
        "✅️", "❎️", "👋", "🤚", "🖐️", "✋️", "🖖", "🫱", "🫲", "🫳", "🫴", "🫷", "🫸", "👌",
        "🤌", "🤏", "✌️", "🤞", "🫰", "🤟", "🤘", "🤙", "👈️", "👉️", "👆️", "🖕", "👇️", "☝️",
        "🫵", "👍️", "👎️", "✊️", "👊", "🤛", "🤜", "👏", "🙌", "🫶", "👐", "🤲", "🤝", "🙏",
        "👄", "🫦", "🐵", "🐒", "🦍", "🦧", "🐶", "🐕️", "🦮", "🐕‍🦺", "🐩", "🐺", "🦊", "🦝",
        "🐱", "🐈️", "🐈‍⬛", "🦁", "🐯", "🐅", "🐆", "🐴", "🫎", "🫏", "🐎", "🦄", "🦓", "🦌",
        "🦬", "🐮", "🐂", "🐃", "🐄", "🐷", "🐖", "🐗", "🐽", "🐏", "🐑", "🐐", "🐪", "🐫",
        "🦙", "🦒", "🐘", "🦣", "🦏", "🦛", "🐭", "🐁", "🐀", "🐹", "🐰", "🐇", "🐿️", "🦫",
        "🦔", "🦇", "🐻", "🐻‍❄️", "🐨", "🐼", "🦥", "🦦", "🦨", "🦘", "🦡", "🐾", "🦃", "🐔",
        "🐓", "🐣", "🐤", "🐥", "🐦️", "🐧", "🕊️", "🦅", "🦆", "🦢", "🦉", "🦤", "🪶", "🦩",
        "🦚", "🦜", "🍆", "🌶️",
    ]

    func unicodeEmojis() -> [String]? {
        return emojis
    }

    func avatar(user: User) -> UIImage? {
        return nil
    }

}
