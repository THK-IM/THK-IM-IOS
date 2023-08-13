//
//  ProgressView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/11.
//

import UIKit

class CircleProgressView: UIView {

    // 当前进度
    private var progress = 0
    
    private var progressLabel: UILabel?

    func setupView() {
        self.backgroundColor = UIColor.init(hex: "333333").withAlphaComponent(0.5)
        self.layer.cornerRadius = self.frame.width / 2
        self.progressLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: self.frame.width*2/3, height: self.frame.height/2))
        self.progressLabel?.center = center
        self.progressLabel?.font = UIFont.systemFont(ofSize: 10)
        self.progressLabel?.textColor = UIColor.white
        self.progressLabel?.textAlignment = .center
        addSubview(self.progressLabel!)
    }

    // 更新进度条
    func setProgress(to newProgress: Int) {
        self.progressLabel?.text = String(newProgress)
    }

    override init(frame: CGRect){
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        
    }
}
