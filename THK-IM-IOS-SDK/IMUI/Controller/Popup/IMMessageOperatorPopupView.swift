//
//  IMMessageOperatorPopupView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

class IMMessageOperatorPopupView: UIView {

    private lazy var shadowView: UIView = {
        let shadowView = UIView()
        shadowView.backgroundColor = .clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.layer.shadowOpacity = 0.3
        shadowView.layer.shadowRadius = 4
        return shadowView
    }()

    private lazy var cornerRadiusView: UIView = {
        let cornerRadiusView = UIView()
        cornerRadiusView.backgroundColor = .white
        cornerRadiusView.layer.cornerRadius = 10
        cornerRadiusView.layer.masksToBounds = true
        return cornerRadiusView
    }()

    private var contentView: UIView

    override init(frame: CGRect) {
        self.contentView = UIView(frame: frame)
        super.init(frame: UIScreen.main.bounds)
        self.addSubview(self.contentView)
        self.initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initViews() {
        self.contentView.addSubview(self.shadowView)
        self.shadowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.shadowView.addSubview(self.cornerRadiusView)
        self.cornerRadiusView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func show(
        _ rowCount: Int, _ operators: [IMMessageOperator], _ sender: IMMsgSender, _ message: Message
    ) {
        for i in operators.indices {
            let view = IMMessageOperatorItemView(
                frame: CGRect(x: (i % rowCount) * 60, y: (i / rowCount) * 60, width: 60, height: 60)
            )
            self.cornerRadiusView.addSubview(view)
            view.setIMMessageOperator(
                operators[i], sender, message,
                { [weak self] in
                    self?.dismiss()
                })
        }
        UIApplication.shared.windows.first?.addSubview(self)
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
