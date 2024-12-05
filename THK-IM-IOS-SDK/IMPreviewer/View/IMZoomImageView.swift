//
//  IMZoomImageView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/25.
//

import AVFoundation
import UIKit

public class IMZoomImageView: UIScrollView, UIScrollViewDelegate {

    open weak var previewDelegate: PreviewDelegate? = nil
    lazy var zoomView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        zoomView.frame = self.bounds
        self.addSubview(zoomView)
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 3.0
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.delegate = self
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setImagePath(_ path: String) {
        if path.starts(with: "http") {
            zoomView.renderImageByUrlWithCorner(url: path, radius: 0, placeHolderImage: zoomView.image)
        } else {
            zoomView.renderImageByPath(path: path, placeHolderImage: zoomView.image)
        }
    }
    
    public func updateZoomHeight(_ height: CGFloat) {
        self.zoomView.frame = CGRectMake(
            0, (self.bounds.size.height - height) / 2,
            self.bounds.width, height
        )
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        SwiftEventBus.post("zoom", sender: self.zoomScale)
        if self.zoomScale == 1.0 {
            self.isScrollEnabled = false
        } else {
            self.isScrollEnabled = true
        }
        var rect = zoomView.frame
        rect.origin.x = 0
        rect.origin.y = 0

        if rect.size.width < self.frame.size.width {
            rect.origin.x = CGFloat((self.frame.size.width - rect.size.width) / 2.0)
        }
        if rect.size.height < self.frame.size.height {
            rect.origin.y = CGFloat((self.frame.size.height - rect.size.height) / 2.0)
        }
        zoomView.frame = rect
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.zoomView
    }

    public func addVideoLayer(_ playLayer: AVPlayerLayer) {
        playLayer.videoGravity = .resizeAspect
        playLayer.frame = self.zoomView.frame
        self.zoomView.layer.addSublayer(playLayer)
    }

    @objc func imageTapped() {
        print("imageTapped")
        if self.zoomScale == 1.0 {
            self.previewDelegate?.close()
        } else {
            self.zoomScale = 1.0
        }
    }
    
    func clearImage() {
        self.zoomView.image = nil
    }
}
