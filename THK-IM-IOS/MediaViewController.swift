//
//  MediaViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/11.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import WCDBSwift
import RxSwift
import RxCocoa
import CocoaLumberjack


class MediaViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    
    var isRecording = OggOpusAudioRecorder.shared.isRecording()
    var isPlaying = OggOpusAudioPlayer.shared.isPlaying()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let textView1 = UIButton(type: .custom)
        textView1.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 100, self.view.frame.size.width, 60)
        if isRecording {
            textView1.setTitle("停止录音", for: .normal)
        } else {
            textView1.setTitle("录音", for: .normal)
        }
        textView1.backgroundColor = UIColor.red;
        textView1.setTitleColor(UIColor.white, for: .normal)
        textView1.rx.tap
            .subscribe(onNext: { data in
                self.isRecording = OggOpusAudioRecorder.shared.isRecording()
                if (!self.isRecording) {
                    let filePath = NSTemporaryDirectory() + "temp.oga"
                    let _ = OggOpusAudioRecorder.shared.startRecording(filePath, 60) {
                        db, duration, path, stopped in
                        DDLogDebug(
                            "recording: callback \(db), \(stopped) ")
                        if stopped {
                            DispatchQueue.main.async {
                                textView1.setTitle("录音", for: .normal)
                            }
                        }
                    }
                } else {
                    OggOpusAudioRecorder.shared.stopRecording()
                }
                self.isRecording = OggOpusAudioRecorder.shared.isRecording()
                if self.isRecording {
                    textView1.setTitle("停止录音", for: .normal)
                } else {
                    textView1.setTitle("录音", for: .normal)
                }
            }).disposed(by: self.disposeBag)
        self.view.addSubview(textView1)
        
        let textView2 = UIButton(type: .custom)
        textView2.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 200, self.view.frame.size.width, 60)
        if self.isPlaying {
            textView2.setTitle("停止播放", for: .normal)
        } else {
            textView2.setTitle("播放", for: .normal)
        }
        textView2.backgroundColor = UIColor.red;
        textView2.setTitleColor(UIColor.white, for: .normal)
        textView2.rx.tap
            .subscribe(onNext: { data in
                self.isPlaying = OggOpusAudioPlayer.shared.isPlaying()
                if (!self.isPlaying) {
                    let filePath = NSTemporaryDirectory() + "temp.oga"
                    let res = OggOpusAudioPlayer.shared.startPlaying(filePath) {db, duration ,path, stopped in
                        DDLogDebug("playing: callback \(db), \(duration) \(path), \(stopped),  \(Thread.current)  ")
                        if stopped {
                            DispatchQueue.main.async {
                                textView2.setTitle("播放", for: .normal)
                            }
                        }
                    }
                    DDLogDebug("playing: startPlaying \(res) ")
                } else {
                    OggOpusAudioPlayer.shared.stopPlaying()
                }
                self.isPlaying = OggOpusAudioPlayer.shared.isPlaying()
                if self.isPlaying {
                    textView2.setTitle("停止播放", for: .normal)
                } else {
                    textView2.setTitle("播放", for: .normal)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView2)
        
        
        
        
        let textView3 = UIButton(type: .custom)
        textView3.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 300, self.view.frame.size.width, 60)
        textView3.setTitle("webrtc", for: .normal)
        textView3.backgroundColor = UIColor.red;
        textView3.setTitleColor(UIColor.white, for: .normal)
        textView3.rx.tap
            .subscribe(onNext: { [weak self] in
                if (self?.navigationController != nil) {
                    let vc = LiveController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView3)
        
        let textView4 = UIButton(type: .custom)
        textView4.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 300, self.view.frame.size.width, 60)
        textView4.setTitle("跳转到视频播放页面", for: .normal)
        textView4.backgroundColor = UIColor.red;
        textView4.setTitleColor(UIColor.white, for: .normal)
        textView4.rx.tap
            .subscribe(onNext: { [weak self] data in
                if (self?.navigationController != nil) {
                    let vc = VideoController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView4)
    }
    
}


