//
//  IMCallMsgView.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/11/21.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class IMCallMsgView: UIView, IMsgBodyView {

    private lazy var callTypeView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var callMsgView: IMMsgLabelView = {
        let view = IMMsgLabelView()
        view.sizeToFit()
        view.numberOfLines = 1
        view.font = UIFont.boldSystemFont(ofSize: 14)
        view.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        view.isUserInteractionEnabled = true
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
        self.addSubview(callTypeView)
        self.callTypeView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        self.addSubview(callMsgView)
        self.callMsgView.snp.makeConstraints { make in
            make.left.equalTo(self.callTypeView.snp.right)
            make.height.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-10)
        }
    }
    
    func setViewPosition(_ position: IMMsgPosType) {
    }
    

    func setMessage(
        _ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?
    ) {
        guard let d = message.content?.data(using: .utf8) else { return }
        guard let callMsg = try? JSONDecoder().decode(IMCallMsg.self, from: d) else {
            return
        }
        if callMsg.roomMode == RoomMode.Audio.rawValue {
            self.callTypeView.image = UIImage(named: "ic_audio_call")
        } else {
            self.callTypeView.image = UIImage(named: "ic_video_call")
        }

        if callMsg.accepted == 2 {
            self.callMsgView.text = "通话时长: \(callMsg.duration / 1000)秒"
        } else if callMsg.accepted == 1 {
            if callMsg.roomOwnerId != IMCoreManager.shared.uId {
                self.callMsgView.text = "已挂断"
            } else {
                self.callMsgView.text = "对方已拒绝"
            }
        } else {
            if callMsg.roomOwnerId != IMCoreManager.shared.uId {
                self.callMsgView.text = "未接听"
            } else {
                self.callMsgView.text = "对方未接听"
            }
        }
    }

    func contentView() -> UIView {
        return self
    }

}
