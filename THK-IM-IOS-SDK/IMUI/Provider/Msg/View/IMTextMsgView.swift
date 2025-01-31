//
//  IMTextMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import CocoaLumberjack
import RxSwift
import UIKit

open class IMTextMsgView: IMMsgLabelView, IMsgBodyView {

    private var disposeBag = DisposeBag()
    private weak var delegate: IMMsgCellOperator?
    private let fontSize: CGFloat = 16

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.numberOfLines = 0
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setViewPosition(_ position: IMMsgPosType) {
        if position == IMMsgPosType.Reply {
            self.textColor = UIColor.darkGray
            self.font = UIFont.systemFont(ofSize: 12)
            self.textAlignment = .left
            self.numberOfLines = 3
            self.padding = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        } else if position == IMMsgPosType.Mid {
            self.padding = UIEdgeInsets.init(top: 4, left: 8, bottom: 4, right: 8)
            self.textAlignment = .left
            self.textColor = UIColor.white
            self.font = UIFont.systemFont(ofSize: fontSize - 4)
        } else {
            self.padding = UIEdgeInsets.init(top: 4, left: 8, bottom: 4, right: 8)
            self.font = UIFont.systemFont(ofSize: fontSize)
            self.textAlignment = .left
            self.textColor = UIColor.init(hex: "0A0E10")
        }
    }

    public func setMessage(
        _ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?
    ) {
        self.delegate = delegate
        guard var content = message.content else {
            return
        }
        let updated = message.operateStatus & MsgOperateStatus.Update.rawValue > 0
        if message.atUsers != nil && message.atUsers!.length > 0 {
            content = self.replaceIdToNickname(content, message.getAtUIds())
        }
        let attributedString = self.render(message, content, updated)
        self.attributedText = attributedString
    }

    public func replaceIdToNickname(_ content: String, _ atUIds: Set<Int64>) -> String {
        let content = AtStringUtils.replaceAtUIdsToNickname(content, atUIds) { [weak self] id in
            if let member = self?.delegate?.msgSender()?.syncGetSessionMemberInfo(id) {
                return IMUIManager.shared.nicknameForSessionMember(member.0, member.1)
            }
            return "\(id)"
        }
        return content
    }

    open func render(_ message: Message, _ data: String, _ updated: Bool) -> NSMutableAttributedString {
        guard let regex = try? NSRegularExpression(pattern: AtStringUtils.atRegular) else {
            return NSMutableAttributedString(string: "")
        }
        let range = NSRange(data.startIndex..<data.endIndex, in: data)
        let contentAttributedStr = NSMutableAttributedString(string: data)
        regex.matches(in: data, options: [], range: range).forEach { matchResult in
            var range = matchResult.range
            range.length += 2
            range.location -= 1
            contentAttributedStr.addAttribute(
                .foregroundColor,
                value: IMUIManager.shared.uiResourceProvider?.tintColor()
                    ?? UIColor.init(hex: "#1390f4"),
                range: range
            )
            contentAttributedStr.addAttribute(
                .font,
                value: UIFont.boldSystemFont(ofSize: self.font.pointSize),
                range: range
            )
        }

        if updated {
            let editStr = ResourceUtils.loadString("edited")
            let editAttributedStr = NSMutableAttributedString(string: editStr)
            let editRange = NSRange(editStr.startIndex..<editStr.endIndex, in: editStr)
            editAttributedStr.addAttribute(
                .foregroundColor,
                value: UIColor.init(hex: "#999999"),
                range: editRange
            )
            editAttributedStr.addAttribute(
                .font,
                value: UIFont.boldSystemFont(ofSize: self.font.pointSize),
                range: editRange
            )
            contentAttributedStr.append(editAttributedStr)
        }
        return contentAttributedStr
    }

    public func contentView() -> UIView {
        return self
    }
}
