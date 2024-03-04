//
//  IMAudioMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

import UIKit
import CocoaLumberjack
import RxSwift

class IMAudioMsgView: UIView, IMsgBodyView {
    
    private lazy var durationView : IMMsgLabelView = {
        let view = IMMsgLabelView()
        view.sizeToFit()
        view.numberOfLines = 1
        view.font = UIFont.boldSystemFont(ofSize: 14)
        view.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var statusView: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
        view.layer.backgroundColor = UIColor.red.cgColor
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(durationView)
        self.durationView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.height.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        
        self.addSubview(statusView)
        self.statusView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalTo(sf.durationView.snp.right).offset(4)
            make.height.equalTo(8)
            make.width.equalTo(8)
            make.right.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
        }
    }
    
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        if (message.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMAudioMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if (data.duration != nil) {
                    self.durationView.text = DateUtils.secondToDuration(seconds: data.duration!)
                }
                if (!data.played) {
                    self.statusView.isHidden = false
                } else {
                    self.statusView.isHidden = true
                }
            } catch {
                DDLogError("\(error)")
            }
            return
        }
        
        if (message.content != nil) {
            do {
                let body = try JSONDecoder().decode(
                    IMAudioMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if (body.duration != nil) {
                    self.durationView.text = DateUtils.secondToDuration(seconds: body.duration!)
                    self.statusView.isHidden = false
                }
                if (body.url != nil) {
                    _ = IMCoreManager.shared.messageModule.getMsgProcessor(message.type)
                        .downloadMsgContent(message, resourceType: IMMsgResourceType.Source.rawValue)
                }
            } catch {
                DDLogError("\(error)")
            }
        }
    }
    
    func contentView() -> UIView {
        return self
    }
    
}
