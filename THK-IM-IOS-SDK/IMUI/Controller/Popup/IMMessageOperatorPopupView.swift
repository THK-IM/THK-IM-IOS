//
//  IMMessageOperatorPopupView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

class IMMessageOperatorPopupView: UIView {

    private lazy var cornerRadiusView: UIView = {
        let cornerRadiusView = UIView()
        cornerRadiusView.backgroundColor =
            IMUIManager.shared.uiResourceProvider?.panelBgColor()
            ?? UIColor.init(hex: "FFFFFF")
        cornerRadiusView.layer.cornerRadius = 10
        return cornerRadiusView
    }()
    
    private lazy var shadowView: UIView = {
        let shadowView = UIView()
        shadowView.backgroundColor = .clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 2, height: 2)
        shadowView.layer.shadowOpacity = 0.3
        shadowView.layer.shadowRadius = 4
        shadowView.addSubview(self.cornerRadiusView)
        self.cornerRadiusView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return shadowView
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.addSubview(self.shadowView)
        self.shadowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return v
    }()

    init() {
        super.init(frame: UIScreen.main.bounds)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func initViews(_ contentFrame: CGRect) {
        self.contentView.frame = contentFrame
        self.addSubview(self.contentView)
    }

    func show(
        _ frame: CGRect, _ rowCount: Int, _ operators: [IMMessageOperator],
        _ sender: IMMsgSender, _ message: Message
    ) {
        self.initViews(frame)
        for i in operators.indices {
            let frame = CGRect(
                x: (i % rowCount) * 60, y: (i / rowCount) * 60, width: 60,
                height: 60)
            if operators[i].renderBySelf() {
                operators[i].addOperatorView(
                    frame, self.cornerRadiusView, message, sender)
            } else {
                let view = IMMessageOperatorItemView(
                    frame: CGRect(
                        x: (i % rowCount) * 60, y: (i / rowCount) * 60,
                        width: 60, height: 60)
                )
                self.cornerRadiusView.addSubview(view)
                view.setIMMessageOperator(
                    operators[i], sender, message,
                    { [weak self] in
                        self?.dismiss()
                    })
            }
        }
    }

    func dismiss() {
        self.removeFromSuperview()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            if !self.contentView.frame.contains(location) {
                dismiss()
            }
        }
    }

}
