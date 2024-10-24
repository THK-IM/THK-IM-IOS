//
//  MediaPreviewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/25.
//

import Foundation
import RxSwift
import SJMediaCacheServer
import SJVideoPlayer
import UIKit

public class IMMediaPreviewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDelegate,
    UIViewControllerTransitioningDelegate,
    PreviewDelegate
{

    var enterFrame: CGRect?
    var messages = [Message]()
    var defaultId = Int64(0)
    var loadMore = false
    private var isLoadingOlder = false
    private var isLoadingNewer = false
    private var currentId = Int64(0)
    private var startPoint: CGPoint?
    private var _offsetX = 0.0
    private var _offsetY = 0.0
    private var _isRequestingMore = false
    private var disposeBag = DisposeBag()

    deinit {
        print("deinit IMMediaPreviewController")
    }

    private let muteAudioTag = 31005
    private lazy var muteAudioButton: SJEdgeControlButtonItem = {
        let v = SJEdgeControlButtonItem(
            image: UIImage.init(named: "ic_audio_on")?.scaledToSize(CGSize(width: 20, height: 20)),
            target: self, action: #selector(mutePlayer), tag: self.muteAudioTag)
        return v
    }()

    lazy var videoPlayer: SJVideoPlayer = {
        let player = SJVideoPlayer()
        player.rotationManager?.isDisabledAutorotation = true
        player.isMuted = true
        player.autoplayWhenSetNewAsset = true
        player.resumePlaybackWhenScrollAppeared = false
        player.defaultEdgeControlLayer.loadingView.showsNetworkSpeed = true
        if #available(iOS 14.0, *) {
            player.defaultEdgeControlLayer.automaticallyShowsPictureInPictureItem = false
        }
        player.controlLayerAppearManager.keepAppearState()
        player.controlLayerAppearManager.isDisabled = true
        player.defaultEdgeControlLayer.isDisabledPromptingWhenNetworkStatusChanges = false

        player.defaultEdgeControlLayer.topAdapter.removeItem(forTag: SJEdgeControlLayerTopItem_Back)
        player.defaultEdgeControlLayer.topAdapter.removeItem(
            forTag: SJEdgeControlLayerTopItem_Title)
        player.defaultEdgeControlLayer.topAdapter.removeItem(forTag: SJEdgeControlLayerTopItem_More)
        if #available(iOS 14.0, *) {
            player.defaultEdgeControlLayer.topAdapter.removeItem(
                forTag: SJEdgeControlLayerTopItem_PictureInPicture)
            player.defaultEdgeControlLayer.topAdapter.item(
                forTag: SJEdgeControlLayerTopItem_PictureInPicture)?.isHidden = true
        }
        player.defaultEdgeControlLayer.bottomAdapter.removeItem(
            forTag: SJEdgeControlLayerBottomItem_Full)
        player.defaultEdgeControlLayer.bottomAdapter.add(self.muteAudioButton)
        if player.isMuted {
            self.muteAudioButton.image = ResourceUtils.loadImage(named: "ic_audio_off")?
                .scaledToSize(CGSize(width: 20, height: 20))
        } else {
            self.muteAudioButton.image = ResourceUtils.loadImage(named: "ic_audio_on")?
                .scaledToSize(CGSize(width: 20, height: 20))
        }
        player.defaultEdgeControlLayer.leftAdapter.removeAllItems()
        player.defaultEdgeControlLayer.rightAdapter.removeAllItems()

        player.defaultEdgeControlLayer.rightAdapter.reload()
        player.defaultEdgeControlLayer.leftAdapter.reload()
        player.defaultEdgeControlLayer.bottomAdapter.reload()
        player.defaultEdgeControlLayer.topAdapter.reload()
        return player
    }()

    private func playVideoAtIndexPath(_ indexPath: IndexPath) {
        let message = self.messages[indexPath.row]
        if message.type != MsgType.Video.rawValue {
            return
        }
        if let mediaCell = self.collectView.cellForItem(at: indexPath) as? PreviewCellView {
            mediaCell.startPreview()
        }
    }

    @objc func mutePlayer() {
        self.videoPlayer.isMuted = !self.videoPlayer.isMuted
        if self.videoPlayer.isMuted {
            self.muteAudioButton.image = ResourceUtils.loadImage(named: "ic_audio_off")?
                .scaledToSize(CGSize(width: 20, height: 20))
        } else {
            self.muteAudioButton.image = ResourceUtils.loadImage(named: "ic_audio_on")?
                .scaledToSize(CGSize(width: 20, height: 20))
        }
        self.videoPlayer.defaultEdgeControlLayer.bottomAdapter.updateContentForItem(
            withTag: self.muteAudioTag)
    }

    private lazy var collectView: UICollectionView = {
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

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.addSubview(self.collectView)
        self.collectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let defaultRow = self.defatultRow()
        self.collectView.selectItem(
            at: IndexPath(row: defaultRow, section: 0), animated: false, scrollPosition: .bottom)

        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(recognizerAction))
        self.view.addGestureRecognizer(gesture)
        self.videoPlayer.playbackObserver.assetStatusDidChangeExeBlock = { [weak self] player in
            if player.assetStatus == .preparing || player.assetStatus == .unknown {
                self?.videoPlayer.defaultEdgeControlLayer.loadingView.start()
            } else if player.assetStatus == .readyToPlay {
                self?.videoPlayer.defaultEdgeControlLayer.loadingView.stop()
            }
        }
        self.videoPlayer.gestureController.gestureRecognizerShouldTrigger = { _, _, _ in
            return false
        }
        self.videoPlayer.playbackObserver.playbackDidFinishExeBlock = { player in
            player.replay()
        }
        initEvents()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.5,
            execute: { [weak self] in
                guard let sf = self else { return }
                sf.playVideoAtIndexPath(IndexPath.init(row: defaultRow, section: 0))
            })
    }

    private func defatultRow() -> Int {
        var row = 0
        if self.messages.count > 0 {
            for i in 0..<self.messages.count {
                if self.messages[i].msgId == self.defaultId {
                    row = i
                    break
                }
            }
        }
        return row
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.videoPlayer.vc_viewDidAppear()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoPlayer.vc_viewWillDisappear()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.videoPlayer.vc_viewDidDisappear()
    }

    private func initEvents() {
        SwiftEventBus.onMainThread(
            self, name: "zoom",
            handler: { [weak self] result in
                guard let sf = self else {
                    return
                }
                guard let scale = result?.object as? CGFloat else {
                    return
                }
                sf.collectView.isScrollEnabled = scale <= 1.0
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgNew.rawValue,
            handler: { [weak self] result in
                guard let msg = result?.object as? Message else {
                    return
                }
                self?.messageUpdate(msg: msg)
            })
        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgUpdate.rawValue,
            handler: { [weak self] result in
                guard let msg = result?.object as? Message else {
                    return
                }
                self?.messageUpdate(msg: msg)
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgLoadStatusUpdate.rawValue,
            handler: { [weak self] result in
                guard let loadProgress = result?.object as? IMLoadProgress else {
                    return
                }
                self?.onItemLoadUpdate(loadProgress)
            })
    }

    private func messageUpdate(msg: Message) {
        for i in 0...self.messages.count - 1 {
            if self.messages[i].id == msg.id {
                if self.messages[i].type == MsgType.Image.rawValue {
                    let cell = self.collectView.cellForItem(at: IndexPath.init(row: i, section: 0))
                    if cell == nil {
                        self.messages[i] = msg
                        self.collectView.reloadItems(at: [IndexPath(row: i, section: 0)])
                    }
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
            if scale < 0.7 {
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
            self.collectView.transform = combinedTransform
            self.view.backgroundColor = UIColor.black.withAlphaComponent(scale)
            break
        case .ended, .cancelled, .failed:
            if scale < 0.7 {
                scale = 0.7
                self.close()
            } else {
                self.startPoint = nil
                self.view.backgroundColor = UIColor.black
                self.collectView.transform = CGAffineTransformMakeScale(1, 1)
                self.collectView.frame = self.view.frame
            }
            break
        default:
            print("MediaPreviewController, default  \(scale)")
            break
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        return self.messages.count
    }

    public func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return self.collectView.frame.size
    }

    public func collectionView(
        _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        self.currentId = self.messages[indexPath.row].msgId
        if indexPath.row == 0 {
            self.loadMoreMessage(self.messages[indexPath.row], true)
        }
        if indexPath.row == self.messages.count - 1 {
            self.loadMoreMessage(self.messages[indexPath.row], false)
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let message = self.messages[indexPath.row]
        if message.type == MsgType.Image.rawValue {
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: NSStringFromClass(PreviewImageCellView.self),
                    for: indexPath
                ) as! PreviewImageCellView
            cell.delegate = self
            cell.setMessage(message)
            return cell
        } else {
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: NSStringFromClass(PreviewVideoCellView.self),
                    for: indexPath
                ) as! PreviewVideoCellView
            cell.delegate = self
            cell.setMessage(message)
            return cell
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.findCellInCenter()
    }

    public func animationController(
        forPresented presented: UIViewController, presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let frame = self.enterFrame else {
            return nil
        }
        let animator = PresentAnimator()
        animator.origin = CGPoint(
            x: frame.origin.x + frame.size.width / 2,
            y: frame.origin.y + frame.size.height / 2
        )
        animator.size = self.enterFrame?.size
        return animator
    }

    public override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(
            alongsideTransition: { (context) in
                self.collectView.collectionViewLayout.invalidateLayout()
            }, completion: nil)
    }

    private func findCellInCenter() {
        videoPlayer.pause()
        let visibleIndexPaths = self.collectView.indexPathsForVisibleItems
        let centerOffset = self.collectView.contentOffset.x + self.collectView.bounds.width / 2

        for indexPath in visibleIndexPaths {
            let attributes = self.collectView.layoutAttributesForItem(at: indexPath)
            if let attributes = attributes {
                if attributes.frame.contains(CGPoint(x: centerOffset, y: self.collectView.center.y))
                {
                    self.playVideoAtIndexPath(indexPath)
                }
            }
        }
    }

    private func onItemLoadUpdate(_ loadProgress: IMLoadProgress) {
        for i in 0...self.messages.count - 1 {
            let cell =
                self.collectView.cellForItem(at: IndexPath.init(row: i, section: 0))
                as? PreviewCellView
            cell?.onIMLoadProgress(loadProgress)
        }
    }

    private func loadMoreMessage(_ message: Message, _ older: Bool) {
        if !loadMore {
            return
        }
        if older {
            if isLoadingOlder {
                return
            }
            isLoadingOlder = true
        } else {
            if isLoadingNewer {
                return
            }
            isLoadingNewer = true
        }
        Observable.just(message)
            .map({ message in
                if older {
                    let messages = try IMCoreManager.shared.database.messageDao().findOlderMessages(
                        message.msgId, [MsgType.Image.rawValue, MsgType.Video.rawValue],
                        message.sessionId, 10)
                    return messages
                } else {
                    let messages = try IMCoreManager.shared.database.messageDao().findNewerMessages(
                        message.msgId, [MsgType.Image.rawValue, MsgType.Video.rawValue],
                        message.sessionId, 10)
                    return messages
                }
            })
            .compose(RxTransformer.shared.io2Main())
            .subscribe(
                onNext: { [weak self] messages in
                    guard let sf = self else {
                        return
                    }
                    if messages.count == 0 {
                        return
                    }
                    var pos = 0
                    if older {
                        sf.messages.insert(contentsOf: messages.reversed(), at: 0)
                    } else {
                        pos = sf.messages.count
                        sf.messages.insert(contentsOf: messages, at: pos)
                    }
                    var paths = [IndexPath]()
                    for i in (pos..<pos + messages.count) {
                        paths.append(IndexPath.init(row: i, section: 0))
                    }
                    sf.collectView.insertItems(at: paths)
                },
                onCompleted: { [weak self] in
                    guard let sf = self else {
                        return
                    }
                    if older {
                        sf.isLoadingOlder = false
                    } else {
                        sf.isLoadingNewer = false
                    }
                }
            )
            .disposed(by: self.disposeBag)
    }

    public func close() {
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        UIView.animate(
            withDuration: 0.4,
            animations: { [weak self] in
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
                let finalScale = toFrame.size.width / fromFrame.size.width
                let toX = toFrame.origin.x + toFrame.size.width / 2
                let toY = toFrame.origin.y + toFrame.size.height / 2
                let fromX = fromFrame.origin.x + fromFrame.size.width / 2
                let fromY = fromFrame.origin.y + fromFrame.size.height / 2
                let translationX = toX - fromX
                let translationY = toY - fromY
                let translationTransform = CGAffineTransform(
                    translationX: translationX,
                    y: translationY
                )
                let scaleTransform = CGAffineTransform(scaleX: finalScale, y: finalScale)
                let combinedTransform = scaleTransform.concatenating(translationTransform)
                sf.collectView.transform = combinedTransform
                sf.startPoint = nil
            },
            completion: { [weak self] _ in
                self?.dismiss(animated: false)
            })
    }

}
