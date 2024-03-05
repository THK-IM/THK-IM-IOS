//
//  IMTextMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMTextMsgView: IMMsgLabelView, IMsgBodyView {
    
    private var disposeBag = DisposeBag()
    private weak var delegate: IMMsgCellOperator?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.sizeToFit()
    }
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        self.delegate = delegate
        if isReply {
            self.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        guard var content = message.content else {
            return
        }
        if (message.atUsers != nil && message.atUsers!.length > 0) {
            content = self.replaceIdToNickname(content, message.atUsers!)
        }
        render(content)
    }
    
    private func replaceIdToNickname(_ content: String, _ atUser: String) -> String {
        let content = AtStringUtils.replaceAtUIdsToNickname(content, atUser) { [weak self] id in
            if let member = self?.delegate?.syncGetSessionMemberInfo(id) {
                return IMUIManager.shared.nicknameForSessionMember(member.0, member.1)
            }
            return ""
        }
        return content
    }
    
    
    private func render(_ data: String) {
        guard let regex = try? NSRegularExpression(pattern: AtStringUtils.atRegular) else {
            return
        }
        let range = NSRange(data.startIndex..<data.endIndex, in: data)
        let attributedStr = NSMutableAttributedString(string: data)
        regex.matches(in: data, options: [], range: range).forEach { matchResult in
            var range = matchResult.range
            range.length += 2
            range.location -= 1
            attributedStr.addAttribute(
                .foregroundColor,
                value: UIColor.init(hex: "#1390f4"),
                range: range
            )
            attributedStr.addAttribute(
                .font,
                value: UIFont.boldSystemFont(ofSize: self.font.pointSize),
                range: range
            )
        }
        self.attributedText = attributedStr
    }
    
    func contentView() -> UIView {
        return self
    }
}
