//
//  UIRtcMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import UIKit
import SnapKit

class UIRtcMsgCell: UITableViewCell {
    
    private let msgView = UILabel()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(msgView)
        msgView.font = UIFont.systemFont(ofSize: 16.0)
        msgView.textColor = UIColor.white
        msgView.numberOfLines = 0
        msgView.layer.cornerRadius = 4.0
        msgView.layer.backgroundColor = UIColor.black.withAlphaComponent(0.4).cgColor
        msgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
            make.left.equalToSuperview().offset(4)
            make.width.lessThanOrEqualToSuperview().offset(-8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMessage(_ msg: String) {
        msgView.text = msg
    }
}


