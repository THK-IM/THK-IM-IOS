//
//  CallingLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class CallingLayout: UIView {
    
    private weak var liveProtocol: LiveCallProtocol? = nil
    
    private let switchMicro: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40000000"), borderColor: UIColor.init(hex: "#40000000"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_micro_on"), for: .normal)
        contentView.setImage(UIImage.init(named: "ic_micro_off"), for: .selected)
        contentView.isSelected = true
        v.addSubview(contentView)
        return v
    }()
    
    private let switchSpeaker: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40000000"), borderColor: UIColor.init(hex: "#40000000"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_speak_on"), for: .normal)
        contentView.setImage(UIImage.init(named: "ic_speak_off"), for: .selected)
        contentView.isSelected = true
        v.addSubview(contentView)
        return v
    }()
    
    private let openOrCloseCamera: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40000000"), borderColor: UIColor.init(hex: "#40000000"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_open_camera"), for: .normal)
        contentView.setImage(UIImage.init(named: "ic_close_camera"), for: .selected)
        contentView.isSelected = true
        v.addSubview(contentView)
        return v
    }()
    
    private let hungUpView: UIImageView = {
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.image = Bubble().drawRectWithRoundedCorner(
            radius: 30, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "#40000000"), borderColor: UIColor.init(hex: "#40000000"),
            width: 60, height: 60)
        v.contentMode = .scaleAspectFit
        let contentView = UIButton(frame: CGRect(x: 12, y: 12, width: 36, height: 36))
        contentView.setImage(UIImage.init(named: "ic_call_hangup"), for: .normal)
        v.addSubview(contentView)
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI() {
        self.addSubview(self.switchMicro)
        self.switchMicro.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset((UIScreen.main.bounds.width) / 3 - 30)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        self.addSubview(self.switchSpeaker)
        self.switchSpeaker.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(2 * (UIScreen.main.bounds.width) / 3 - 30)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        self.addSubview(self.openOrCloseCamera)
        self.openOrCloseCamera.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(UIScreen.main.bounds.width - 30)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        self.addSubview(self.hungUpView)
        self.hungUpView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(100)
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerX.equalToSuperview()
        }
    }
    
    
    func initCall(_ callProtocol: LiveCallProtocol) {
        self.liveProtocol = callProtocol
    }
}
