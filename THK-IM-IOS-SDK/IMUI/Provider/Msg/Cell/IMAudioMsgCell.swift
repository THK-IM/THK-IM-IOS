//
//  IMAudioMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import UIKit
import CocoaLumberjack
import Kingfisher

class IMAudioMsgCell: BaseMsgCell {
    
    private lazy var view : UIView = {
        let view = UIView()
        view.addSubview(durationView)
        self.durationView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.height.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        
        view.addSubview(statusView)
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
        return view
    }()
    
    private lazy var durationView : IMMsgLabelView = {
        let view = IMMsgLabelView()
        view.sizeToFit()
        view.numberOfLines = 1
        view.font = UIFont.boldSystemFont(ofSize: 14)
        view.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        view.isUserInteractionEnabled = true
        if self.cellPosition() == IMMsgPosType.Left.rawValue {
            view.textColor = UIColor.black
        } else if self.cellPosition() == IMMsgPosType.Right.rawValue {
            view.textColor = UIColor.black
        } else {
            view.textColor = UIColor.white
        }
        return view
    }()
    
    private lazy var statusView: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
        view.layer.backgroundColor = UIColor.red.cgColor
        return view
    }()
    
    
    override func msgView() -> UIView {
        return self.view
    }
    
    override func hasBubble() -> Bool {
        return true
    }
    
    open override func setMessage(_ mode: Int, _ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(mode, position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        statusView.isHidden = true
        if (msg.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMAudioMsgData.self,
                    from: msg.data!.data(using: .utf8) ?? Data())
                if (data.duration != nil) {
                    self.durationView.text = DateUtils.secondToDuration(seconds: data.duration!)
                }
                if (!data.played) {
                    self.statusView.isHidden = false
                } else {
                    self.statusView.isHidden = true
                }
            } catch {
                DDLogError(error)
            }
            return
        }
        
        if (msg.content != nil) {
            do {
                let body = try JSONDecoder().decode(
                    IMAudioMsgBody.self,
                    from: msg.content!.data(using: .utf8) ?? Data())
                if (body.duration != nil) {
                    self.durationView.text = DateUtils.secondToDuration(seconds: body.duration!)
                    self.statusView.isHidden = false
                }
                if (body.url != nil) {
                    _ = IMCoreManager.shared.getMessageModule().getMsgProcessor(msg.type)
                        .downloadMsgContent(msg, resourceType: IMMsgResourceType.Source.rawValue)
                }
            } catch {
                DDLogError(error)
            }
        }
    }
    
    
    
}
