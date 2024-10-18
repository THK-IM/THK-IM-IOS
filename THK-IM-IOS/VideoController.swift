//
//  VideoController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/15.
//

import UIKit

class VideoController: UIViewController {

    private let playerView = IMCacheVideoPlayerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.playerView)
        self.playerView.frame = self.view.frame

        // TODO add your video duration and url
        playerView.initDuration(10)
        playerView.initDataSource(URL(string: ""))
    }

}
