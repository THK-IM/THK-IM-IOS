//
//  IMMessageSelectedLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/8.
//

import Foundation
import UIKit
import RxSwift
import RxGesture


class IMMsgCheckedLayout: UIView {
    
    weak var sender: IMMsgSender?
    private let disposeBag = DisposeBag()
    
    lazy private var contentView: UIStackView =  {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually
        v.alignment = .fill
        v.addArrangedSubview(deleteButton)
        v.addArrangedSubview(forwardButton)
        v.addArrangedSubview(cancelButton)
        return v
    }()
    
    lazy private var deleteButton: UIImageView = {
        let button = UIImageView()
        button.backgroundColor = UIColor.red
        let image = UIImage(named: "chat_bar_voice")
        if image != nil {
            button.image = image
            button.contentMode = .scaleAspectFit
            button.clipsToBounds = true
        }
        return button
    }()
    
    lazy private var forwardButton: UIImageView = {
        let button = UIImageView()
        button.backgroundColor = UIColor.red
        let image = UIImage(named: "chat_bar_voice")
        if image != nil {
            button.image = image
            button.contentMode = .scaleAspectFit
            button.clipsToBounds = true
        }
        return button
    }()
    
    lazy private var cancelButton: UIImageView = {
        let button = UIImageView()
        button.backgroundColor = UIColor.red
        let image = UIImage(named: "chat_bar_voice")
        if image != nil {
            button.image = image
            button.contentMode = .scaleAspectFit
            button.clipsToBounds = true
        }
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.deleteButton.rx.tapGesture()
            .subscribe(onNext: {[weak self]  event in
                guard let sf = self else {
                    return
                }
                sf.sender?.dismissMsgSelectedLayout()
            })
            .disposed(by: disposeBag)
        
        self.forwardButton.rx.tapGesture()
            .subscribe(onNext: {[weak self]  event in
                guard let sf = self else {
                    return
                }
                sf.sender?.dismissMsgSelectedLayout()
            })
            .disposed(by: disposeBag)
        self.cancelButton.rx.tapGesture()
            .subscribe(onNext: {[weak self]  event in
                guard let sf = self else {
                    return
                }
                sf.sender?.dismissMsgSelectedLayout()
            })
            .disposed(by: disposeBag)
    }
    
    func getLayoutHeight() -> CGFloat {
        return 60.0
    }
}
