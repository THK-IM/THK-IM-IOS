//
//  IMCacheVideoPlayerView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/12.
//

import Foundation
import UIKit
import AVFoundation

public class IMCacheVideoPlayerView: UIView, AVAssetResourceLoaderDelegate {
    
    private var url: URL? = nil
    private var seconds: Int = 0
    private var player = AVPlayer()
    private var isSliderDragging = false
    private var coverPath: String?
    
    private var observer: Any?
    
    deinit {
        print("IMCacheVideoPlayerView de init")
        self.destroy()
    }
    
    private lazy var progressView: UISlider = {
        let p = UISlider()
        p.value = 0.0
        p.minimumValue = 0.0
        p.maximumValue = 1.0
        p.backgroundColor = UIColor.clear
        p.addTarget(
            self,
            action: #selector(self.playerSliderValueChanged(sender:)),
            for: UIControl.Event.valueChanged
        )
        p.addTarget(
            self,
            action: #selector(self.playerSliderTouchDown(sender:)),
            for: UIControl.Event.touchDown
        )
        p.addTarget(
            self,
            action: #selector(self.playerSliderTouchUpInside(sender:)),
            for: UIControl.Event.touchUpInside
        )
        let image = Bubble().drawRectWithRoundedCorner(radius: 2, borderWidth: 0, backgroundColor: UIColor.white, borderColor: UIColor.white, width: 4, height: 12)
        p.setThumbImage(image, for: .normal)
        p.setThumbImage(image, for: .highlighted)
        p.minimumTrackTintColor = UIColor.white
        p.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.1)
        return p
    }()
    
    private lazy var timeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textAlignment = .right
        l.textColor = UIColor.white
        return l
    }()
    
    private lazy var playButton: UIButton = {
        let b = UIButton()
        b.contentHorizontalAlignment = .fill
        b.contentVerticalAlignment = .fill
        b.setImage(UIImage(named: "icon_video_play"), for: UIControl.State.normal)
        b.setImage(UIImage(named: "icon_video_pause"), for: UIControl.State.selected)
        b.addTarget(
            self,
            action: #selector(self.playOrPauseClick(sender:)),
            for: UIControl.Event.touchUpInside
        )
        return b
    }()
    
    private lazy var controllerLayout: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        return view
    }()
    
    private lazy var playView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    private func setup() {
        self.setupView()
        self.setupTimer()
    }
    
    private func setupView() {
        let safeBottom = UIApplication.shared.windows[0].safeAreaInsets.bottom + 60
        self.addSubview(self.controllerLayout)
        self.controllerLayout.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-safeBottom)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
        self.controllerLayout.addSubview(self.timeLabel)
        self.timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(40)
        }
        
        self.controllerLayout.addSubview(self.progressView)
        self.progressView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.centerY.equalToSuperview()
            make.height.equalTo(10)
            make.left.equalToSuperview().offset(6)
            make.right.equalTo(sf.timeLabel.snp.left).offset(-6)
        }
        
        self.addSubview(self.playView)
        self.playView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.bringSubviewToFront(self.controllerLayout)
        
        self.addSubview(self.playButton)
        self.playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(60)
        }
        
    }
    
    private func setupTimer() {
        self.destroyTimer()
        if self.player.currentItem != nil {
            self.observer = self.player.addPeriodicTimeObserver(
                forInterval: CMTime(value: 1, timescale: 60),
                queue: DispatchQueue.main
            ) { [weak self] t in
                guard let sf = self else {
                    return
                }
                let remain = max(0, sf.seconds - Int(t.seconds))
                sf.timeLabel.text = DateUtils.secondToDuration(seconds: remain)
                if !sf.isSliderDragging {
                    sf.progressView.value = Float(min(t.seconds/Double(sf.seconds), 1.0))
                }
                if (remain == 0) {
                    let seekTime = CMTimeMakeWithSeconds(0, preferredTimescale: 60)
                    self?.pause()
                    self?.seekTo(time: seekTime)
                    self?.playButton.isSelected = false
                }
            }
        }
    }
    
    public func initDuration(_ seconds: Int) {
        self.seconds = seconds
        self.progressView.value = 0
        self.playButton.isSelected = false
        self.timeLabel.text = DateUtils.secondToDuration(seconds: seconds)
    }
    
    public func initCover(_ path: String) {
        self.coverPath = path
        self.playView.renderImageByPath(path: path)
    }
    
    public func initDataSource(_ url: URL?) {
        if self.url != nil {
            if self.url!.absoluteString == url?.absoluteString {
                return
            }
        }
        self.progressView.value = 0
        self.url = url
        self.prepare()
    }
    
    public func prepare() {
        guard let url = self.url else {
            return
        }
        var customUrl = url.absoluteString
        if (customUrl.hasPrefix("http")) {
            customUrl = url.absoluteString.replacingOccurrences(of: "http", with: AVCacheManager.customProtocol)
        }
        let urlAssets = AVURLAsset(url: URL(string: customUrl)!, options:["AVURLAssetOutOfBandMIMETypeKey": "video/mp4"])
        urlAssets.resourceLoader.setDelegate(self, queue: DispatchQueue.global())
        let item = AVPlayerItem(asset: urlAssets)
        self.player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        self.player.replaceCurrentItem(with: item)
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        let playerLayer = AVPlayerLayer.init(player: self.player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = self.bounds
        self.player.volume = 1.0
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [
            .defaultToSpeaker,
            .allowAirPlay,
            .allowBluetooth,
            .allowBluetoothA2DP
        ])
        try? AVAudioSession.sharedInstance().setActive(true)
        self.playView.layer.addSublayer(playerLayer)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loadedTimeRanges" {
        }
        if keyPath == "status" {
            let err = player.currentItem?.error
            if (err != nil) {
                print("IMCacheVideoPlayerView err \(err!)")
            }
        }
    }
    
    public func play() {
        self.playButton.isHidden = true
        self.setupTimer()
        self.resume()
    }
    
    public func pause() {
        self.playButton.isSelected = false
        self.playButton.isHidden = false
        self.player.pause()
    }
    
    public func resume() {
        if self.observer == nil {
            self.setupTimer()
        }
        if self.progressView.value >= 1.0 {
            let seekTime = CMTimeMakeWithSeconds(0, preferredTimescale: 60)
            self.seekTo(time: seekTime)
        }
        self.player.play()
        self.playButton.isSelected = true
    }
    
    public func destroy() {
        self.player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        self.pause()
        self.destroyTimer()
    }
    
    private func destroyTimer() {
        if self.observer != nil {
            self.player.removeTimeObserver(self.observer!)
        }
    }
    
    public func seekTo(time: CMTime) {
        player.seek(to: time)
    }
    
    
    //进度条被触摸
    @objc private func playerSliderTouchDown(sender:UISlider) {
        self.isSliderDragging = true
    }
    
    //拖动进度条
    @objc private func playerSliderValueChanged(sender:UISlider) {
        self.pause()
        // 跳转到拖拽秒处
        let seconds = sender.value * Float(self.seconds)
        let changedTime = CMTimeMakeWithSeconds(Float64(seconds), preferredTimescale: 60)
        self.seekTo(time: changedTime)
    }
    
    //手指松开进度条
    @objc private func playerSliderTouchUpInside(sender:UISlider) {
        self.isSliderDragging = false
        self.resume()
    }
    
    
    //播放/暂停按钮事件
    @objc private func playOrPauseClick(sender:UIButton) {
        if playButton.isSelected == true {
            self.pause()
        } else {
            self.resume()
            DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: { [weak self] in
                self?.hideController(true)
            })
        }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.hideController(!self.playButton.isHidden)
    }
    
    private func hideController(_ hide :Bool) {
        self.playButton.isHidden = hide
        self.controllerLayout.isHidden = hide
    }
    
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel authenticationChallenge: URLAuthenticationChallenge) {
        print("IMCacheVideoPlayerView resourceLoader authenticationChallenge")
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        print("IMCacheVideoPlayerView resourceLoader didCancel")
        AVCacheManager.shared.cancelRequest(loadingRequest)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let response = AVCacheManager.shared.addRequest(loadingRequest)
        print("IMCacheVideoPlayerView resourceLoader shouldWaitForLoadingOfRequestedResource \(Thread.current) \(response)")
        return response
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        print("IMCacheVideoPlayerView resourceLoader shouldWaitForRenewalOfRequestedResource")
        return true
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge) -> Bool {
        return true
    }
    
}

