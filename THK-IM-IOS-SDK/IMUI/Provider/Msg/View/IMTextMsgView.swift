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

class IMTextMsgView: IMMsgLabelView, IMsgView {
    
    private var disposeBag = DisposeBag()
    
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
        if isReply {
            self.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        if (message.data != nil && message.data!.length > 0) {
            self.renderAtMsg(message.data!)
        } else if (message.atUsers != nil) {
            let atUsers = message.atUsers!.split(separator: "#")
            if (atUsers.isEmpty) {
                self.renderAtMsg(message.content!)
            } else {
                self.renderAtUserInfo(message, atUsers)
            }
        } else {
            self.text = message.content
        }
    }
    
    private func renderAtUserInfo(_ message: Message, _ atUsers: [Substring]) {
        var uIds = Set<Int64>()
        for atUser in atUsers {
            if let id = Int64(atUser) {
                uIds.insert(id)
            }
        }
        if (uIds.isEmpty) {
            self.text = message.content
        } else {
            IMCoreManager.shared.userModule.queryUsers(ids: uIds)
                .flatMap({ it -> Observable<String> in
                    guard let content = message.content else {
                        return Observable.just("")
                    }
                    var userMap = [String: User]()
                    for (k, v) in it {
                        userMap["\(k)"] = v
                    }
                    guard let regex = try? NSRegularExpression(pattern: "(?<=@)(.+?)(?=\\s)") else {
                        return Observable.just(content)
                    }
                    let data = NSMutableString(string: content)
                    let allRange = NSRange(content.startIndex..<content.endIndex, in: content)
                    regex.matches(in: content, options: [], range: allRange).forEach { matchResult in
                        if let idRange = Range.init(matchResult.range, in: content) {
                            let id = String(content[idRange])
                            if let user = userMap[id] {
                                let dataString = String(data)
                                let dataRange = NSRange(dataString.startIndex..<dataString.endIndex, in: dataString)
                                data.replaceOccurrences(of: id, with: user.nickname, options: .caseInsensitive, range: dataRange)
                            }
                        }
                    }
                    let msgData = String(data)
                    return Observable.just(msgData)
                })
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] data in
                    self?.renderAtMsg(data)
                }).disposed(by: self.disposeBag)
        }
    }
    
    
    private func renderAtMsg(_ data: String) {
        guard let regex = try? NSRegularExpression(pattern: "(?<=@)(.+?)(?=\\s)") else {
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
    
    func reset() {
        disposeBag = DisposeBag()
    }
    
    func contentView() -> UIView {
        return self
    }
}
