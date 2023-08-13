//
//  PreviewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/25.
//

import Foundation
import UIKit
import SwiftEventBus

class MediaPreviewController: UIViewController,
                              UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout,
                              UICollectionViewDelegate,
                              UIViewControllerTransitioningDelegate {
    static func preview(
        from: UIViewController, onMediaDownloaded: MediaDownloadDelegate,
        source: [Media], defaultId: String,
        enterFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    ) {
        from.definesPresentationContext = true
        let mediaPreviewController = MediaPreviewController()
        mediaPreviewController.sourceArray = source
        mediaPreviewController.enterFrame = enterFrame
        mediaPreviewController.defaultId = defaultId
        mediaPreviewController.onMediaDownloaded = onMediaDownloaded
        mediaPreviewController.modalPresentationStyle = .overFullScreen
        mediaPreviewController.transitioningDelegate = mediaPreviewController
        from.present(mediaPreviewController, animated: true)
    }
    
    var defaultId: String = ""
    var currentId: String = ""
    var enterFrame: CGRect?
    var sourceArray = [Media]()
    weak var onMediaDownloaded: MediaDownloadDelegate?
    private var startPoint: CGPoint?
    private var _offsetX = 0.0
    private var _offsetY = 0.0
    private var _isRequestingMore = false
    
    private lazy var _collectView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            PreviewImageCellView.self,
            forCellWithReuseIdentifier: NSStringFromClass(PreviewImageCellView.self))
        collectionView.register(
            PreviewVideoCellView.self,
            forCellWithReuseIdentifier: NSStringFromClass(PreviewVideoCellView.self))
        collectionView.alpha = 1
        return collectionView
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.addSubview(self._collectView)
        self._collectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        var position = 0
        if self.sourceArray.count > 0 {
            for i in 0 ..< self.sourceArray.count {
                if self.sourceArray[i].id == self.defaultId {
                    position = i
                }
            }
            self._collectView.selectItem(at: IndexPath(row: position, section: 0), animated: false, scrollPosition: .bottom)
        }
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(recognizerAction))
        self.view.addGestureRecognizer(gesture)
        
        SwiftEventBus.onMainThread(self, name: "zoom", handler: { [weak self] result in
            guard let sf = self else {
                return
            }
            guard let scale = result?.object as? CGFloat else {
                return
            }
            sf._collectView.isScrollEnabled = scale <= 1.0
        })
    }
    
    @objc func recognizerAction(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
        var scale = 1 - translation.y / self.view.frame.height
        scale = min(scale, 1)
        scale = max(scale, 0)
        let location = gestureRecognizer.location(in: self.view)
        switch gestureRecognizer.state {
        case .began:
            _offsetX = 0.0
            _offsetY = 0.0
            startPoint = gestureRecognizer.location(in: self.view)
            break
        case .changed:
            if (scale < 0.7) {
                scale = 0.7
            }
            _offsetX = (location.x - startPoint!.x)
            _offsetY = (location.y - startPoint!.y)
            let translationTransform = CGAffineTransform(
                translationX: (location.x - startPoint!.x),
                y: (location.y - startPoint!.y)
            )
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            let combinedTransform = translationTransform.concatenating(scaleTransform)
            self._collectView.transform = combinedTransform
            self.view.backgroundColor = UIColor.black.withAlphaComponent(scale)
            break
        case .ended, .cancelled, .failed:
            if (scale < 0.7) {
                scale = 0.7
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                UIView.animate(withDuration: 0.4, animations: { [weak self] in
                    guard let sf = self else {
                        return
                    }
                    if sf.defaultId != sf.currentId {
                        return
                    }
                    guard let toFrame = sf.enterFrame else {
                        return
                    }
                    let fromFrame = sf.view.frame
                    let finalScale = toFrame.size.width/fromFrame.size.width
                    let toX = toFrame.origin.x + toFrame.size.width/2
                    let toY = toFrame.origin.y + toFrame.size.height/2
                    let fromX = fromFrame.origin.x + fromFrame.size.width/2
                    let fromY = fromFrame.origin.y + fromFrame.size.height/2
                    let translationX = toX - fromX
                    let translationY = toY - fromY
                    let translationTransform = CGAffineTransform(
                        translationX: translationX,
                        y: translationY
                    )
                    let scaleTransform = CGAffineTransform(scaleX: finalScale, y: finalScale)
                    let combinedTransform = scaleTransform.concatenating(translationTransform)
                    sf._collectView.transform = combinedTransform
                    sf.startPoint = nil
                }, completion: { [weak self] _ in
                    self?.dismiss(animated: false)
                })
            } else {
                self.startPoint = nil
                self.view.backgroundColor = UIColor.black
                self._collectView.transform = CGAffineTransformMakeScale(1, 1)
                self._collectView.frame = self.view.frame
            }
            break
        default:
            print("MediaPreviewController, default  \(scale)")
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.sourceArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self._collectView.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let media = self.sourceArray[indexPath.row]
        if media.type == 1 {
            let mediaCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NSStringFromClass(PreviewImageCellView.self),
                for: indexPath
            ) as! PreviewImageCellView
            mediaCell.onMediaDownloaded = self.onMediaDownloaded
            mediaCell.setPreviewMedia(media)
            return mediaCell
        } else {
            let mediaCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NSStringFromClass(PreviewVideoCellView.self),
                for: indexPath
            ) as! PreviewVideoCellView
            mediaCell.onMediaDownloaded = self.onMediaDownloaded
            mediaCell.setPreviewMedia(media)
            return mediaCell
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let media = self.sourceArray[indexPath.row]
        if media.type == 1 {
            let mediaCall = cell as! PreviewImageCellView
            mediaCall.endDisplaying()
        } else {
            let mediaCall = cell as! PreviewVideoCellView
            mediaCall.endDisplaying()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let media = self.sourceArray[indexPath.row]
        self.currentId = media.id
        if indexPath.row == 0 {
            self.requestMoreMedia(media, true)
        } else if indexPath.row == self.sourceArray.count - 1 {
            self.requestMoreMedia(media, false)
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let frame = self.enterFrame else {
            return nil
        }
        let animator = PresentAnimator()
        animator.origin = CGPoint(
            x: frame.origin.x + frame.size.width / 2,
            y: frame.origin.y + frame.size.height / 2
        )
        return animator
    }
    
    func requestMoreMedia(_ media: Media, _ before: Bool) {
        if _isRequestingMore {
            return
        }
        _isRequestingMore = true
        DispatchQueue.global().async { [weak self] in
            guard let sf = self else {
                return
            }
            guard let medias = self?.onMediaDownloaded?.onMoreMediaFetch(media.id, before, 10) else {
                sf._isRequestingMore = false
                return
            }
            DispatchQueue.main.async { [weak sf] in
                guard let wSf = sf else {
                    return
                }
                if medias.count == 0 {
                    wSf._isRequestingMore = false
                    return
                }
                var at = 0
                if !before {
                    at = wSf.sourceArray.count
                }
                wSf.sourceArray.insert(contentsOf: (before ? medias.reversed() : medias), at: at)
                var paths = [IndexPath]()
                for i in (at ..< (medias.count+at)) {
                    paths.append(IndexPath.init(row: i, section: 0))
                }
                wSf._collectView.insertItems(at: paths)
                wSf._isRequestingMore = false
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self._collectView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
}
