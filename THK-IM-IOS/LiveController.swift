//
//  LiveController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import UIKit
import RxSwift

class LiveController: UIViewController {
    
    let localView = ParticipantView()
    private let disposeBag = DisposeBag()
    
    var isFullscreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(localView)
        self.localView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.localView.setFullScreen(false)
        
        self.view.rx.tapGesture()
            .when(.ended)
            .asObservable()
            .subscribe({ _ in
                self.isFullscreen = !self.isFullscreen
                self.localView.setFullScreen(self.isFullscreen)
            })
            .disposed(by: self.disposeBag)
    }
}
