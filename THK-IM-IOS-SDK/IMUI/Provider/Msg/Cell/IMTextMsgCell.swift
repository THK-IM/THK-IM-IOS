//
//  IMTextMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMTextMsgCell: BaseMsgCell {
    
    private let testSize:CGFloat = 16
    
    private lazy var textView: IMMsgLabelView = {
        let view = IMMsgLabelView()
        view.sizeToFit()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: testSize)
        view.padding = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
        
        if self.cellPosition() == IMMsgPosType.Left.rawValue {
            view.textColor = UIColor.black
            view.textAlignment = .left
        } else if self.cellPosition() == IMMsgPosType.Right.rawValue {
            view.textColor = UIColor.black
            view.textAlignment = .left
        } else {
            view.textColor = UIColor.white
            view.textAlignment = .center
        }
        return view
    }()
    
    
    
    override func msgView() -> UIView {
        return self.textView
    }
    
    override func hasBubble() -> Bool {
        return true
    }
    
    open override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        if (self.message!.data != nil && self.message!.data!.length > 0) {
            self.renderAtMsg(self.message!.data!)
        } else if (self.message!.atUsers != nil) {
            let atUsers = self.message!.atUsers!.split(separator: "#")
            if (atUsers.isEmpty) {
                self.renderAtMsg(self.message!.content!)
            } else {
                self.renderAtUserInfo(atUsers)
            }
        } else {
            self.textView.text = self.message!.content
        }
    }
    
    private func renderAtUserInfo(_ atUsers: [Substring]) {
        var uIds = Set<Int64>()
        for atUser in atUsers {
            if let id = Int64(atUser) {
                uIds.insert(id)
            }
        }
        if (uIds.isEmpty) {
            self.textView.text = self.message!.content
        } else {
            IMCoreManager.shared.userModule.queryUsers(ids: uIds)
                .flatMap({ [weak self] it -> Observable<String> in
                    guard let content = self?.message?.content else {
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
                value: UIFont.boldSystemFont(ofSize: testSize),
                range: range
            )
        }
        self.textView.attributedText = attributedStr
    }
    
}
