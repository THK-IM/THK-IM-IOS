//
//  IMZoomImageView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/25.
//

import UIKit
import AVFoundation
import SwiftEventBus

class IMZoomImageView: UIScrollView, UIScrollViewDelegate {
    
    lazy var _zoomImageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createZoomScrollView()
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 3.0
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createZoomScrollView() {
        _zoomImageView.frame = self.frame
        self.addSubview(_zoomImageView)
    }
    
    func setImagePath(_ path: String) {
        _zoomImageView.ca_setImagePath(path: path)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        SwiftEventBus.post("zoom", sender: self.zoomScale)
        if (self.zoomScale == 1.0) {
            self.isScrollEnabled = false
        } else {
            self.isScrollEnabled = true
        }
        var rect = _zoomImageView.frame
        rect.origin.x = 0
        rect.origin.y = 0
        
        if (rect.size.width < self.frame.size.width) {
            rect.origin.x = CGFloat((self.frame.size.width - rect.size.width) / 2.0)
        }
        if (rect.size.height < self.frame.size.height) {
            rect.origin.y = CGFloat((self.frame.size.height - rect.size.height) / 2.0)
        }
        _zoomImageView.frame = rect
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self._zoomImageView
    }
    
    func addVideoLayer(_ playLayer: AVPlayerLayer) {
        playLayer.videoGravity = .resizeAspect
        playLayer.frame = self._zoomImageView.frame
        self._zoomImageView.layer.addSublayer(playLayer)
    }
    
}