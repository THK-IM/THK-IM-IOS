//
//  IMVideoController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/15.
//

import UIKit

class IMVideoController: UIViewController {
    
    private let playerView = IMCacheVideoPlayerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.playerView)
        self.playerView.frame = self.view.frame
        
        // TODO add your video url
        playerView.initDataSource(URL(string: "http://192.168.1.5:10000/object/1713235103997497344"))
        playerView.prepare()
        playerView.play()
    }
    
}
