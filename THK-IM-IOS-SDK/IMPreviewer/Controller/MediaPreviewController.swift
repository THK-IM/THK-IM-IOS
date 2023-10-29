//
//  MediaPreviewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/25.
//

import Foundation
import UIKit
import SwiftEventBus
import RxSwift

class MediaPreviewController: UIViewController,
                              UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout,
                              UICollectionViewDelegate,
                              UIViewControllerTransitioningDelegate {
    var enterFrame: CGRect?
    var messages = [Message]()
    var defaultId = Int64(0)
    private var currentId = Int64(0)
    private var startPoint: CGPoint?
    private var _offsetX = 0.0
    private var _offsetY = 0.0
    private var _isRequestingMore = false
    private var disposeBag = DisposeBag()
    
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
        if self.messages.count > 0 {
            for i in 0 ..< self.messages.count {
                if self.messages[i].id == self.defaultId {
                    position = i
                }
            }
            self._collectView.selectItem(at: IndexPath(row: position, section: 0), animated: false, scrollPosition: .bottom)
        }
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(recognizerAction))
        self.view.addGestureRecognizer(gesture)
        initEvents()
    }
    
    private func initEvents() {
        SwiftEventBus.onMainThread(self, name: "zoom", handler: { [weak self] result in
            guard let sf = self else {
                return
            }
            guard let scale = result?.object as? CGFloat else {
                return
            }
            sf._collectView.isScrollEnabled = scale <= 1.0
        })
        SwiftEventBus.onMainThread(self, name: IMEvent.MsgNew.rawValue, handler: { [weak self ] result in
            guard let msg = result?.object as? Message else {
                return
            }
            self?.messageUpdate(msg: msg)
        })
        SwiftEventBus.onMainThread(self, name: IMEvent.MsgUpdate.rawValue, handler: { [weak self ]result in
            guard let msg = result?.object as? Message else {
                return
            }
            self?.messageUpdate(msg: msg)
        })
    }
    
    private func messageUpdate(msg: Message) {
        for  i in 0 ... self.messages.count-1 {
            if (self.messages[i].id == msg.id) {
                if (self.messages[i].type == MsgType.IMAGE.rawValue) {
                    self.messages[i] = msg
                    self._collectView.reloadItems(at: [IndexPath(row: i, section: 0)])
                }
                break
            }
        }
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
        return self.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self._collectView.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = self.messages[indexPath.row]
        if message.type == MsgType.IMAGE.rawValue {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NSStringFromClass(PreviewImageCellView.self),
                for: indexPath
            ) as! PreviewImageCellView
            cell.setMessage(message)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NSStringFromClass(PreviewVideoCellView.self),
                for: indexPath
            ) as! PreviewVideoCellView
            cell.setMessage(message)
            return cell
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let previewCell = cell as! PreviewCellView
        previewCell.stopPreview()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.currentId = self.messages[indexPath.row].id
        if (indexPath.row == 0) {
            self.loadMoreMessage(self.messages[indexPath.row], true)
        } else if (indexPath.row == self.messages.count - 1) {
            self.loadMoreMessage(self.messages[indexPath.row], false)
        }
        
        let previewCell = cell as! PreviewCellView
        previewCell.startPreview()
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self._collectView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
    
    private func loadMoreMessage(_ message: Message, _ older: Bool) {
        Observable.just(message)
            .map({ message in
                if (older) {
                    let messages = try IMCoreManager.shared.database.messageDao.findOlderMessages(message.msgId, [MsgType.IMAGE.rawValue, MsgType.VIDEO.rawValue], message.sessionId, 10)
                    return messages
                } else {
                    let messages = try IMCoreManager.shared.database.messageDao.findNewerMessages(message.msgId, [MsgType.IMAGE.rawValue, MsgType.VIDEO.rawValue], message.sessionId, 10)
                    return messages
                }
            })
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] messages in
                guard let sf = self else {
                    return
                }
                var pos = 0
                if (older) {
                    sf.messages.insert(contentsOf: messages.reversed() , at: 0)
                } else {
                    pos = sf.messages.count
                    sf.messages.insert(contentsOf: messages, at: pos)
                }
                var paths = Array<IndexPath>()
                for i in (pos ..< pos + messages.count) {
                    paths.append(IndexPath.init(row: i, section: 0))
                }
                sf._collectView.insertItems(at: paths)
            })
            .disposed(by: self.disposeBag)
    }
    
}
