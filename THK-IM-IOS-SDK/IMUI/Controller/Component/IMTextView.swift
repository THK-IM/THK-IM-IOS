//
//  IMTextView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/21.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

protocol TextViewBackwardDelegate: AnyObject {

    func onDeleted() -> Bool
}

class IMTextView: UITextView {
    
    weak var backwardDelegate:TextViewBackwardDelegate?
    
    override func deleteBackward() {
        if (backwardDelegate == nil) {
            super.deleteBackward()
        } else {
            if (!backwardDelegate!.onDeleted()) {
                super.deleteBackward()
            }
        }
    }
    
    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    override var text: String! {
        didSet {
            textDidChange() // 调用监听文本变化的方法
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
        
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 5)
        ])
        placeholderLabel.isHidden = self.text.count > 0
    }

    @objc private func textDidChange() {
        placeholderLabel.isHidden = self.text.count > 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
