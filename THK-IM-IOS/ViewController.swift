//
//  ViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import UIKit
import WCDBSwift
import RxSwift
import RxCocoa
import CocoaLumberjack
import GDPerformanceView_Swift


class ViewController: UIViewController, PerformanceMonitorDelegate {
    
    func performanceMonitor(didReport performanceReport: PerformanceReport) {
    }
    
    
    var disposeBag = DisposeBag()
    
    var isRecording = OggOpusAudioRecorder.shared.isRecording()
    var isPlaying = OggOpusAudioPlayer.shared.isPlaying()
    var performanceView :PerformanceMonitor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.performanceView = PerformanceMonitor()
        self.performanceView?.delegate = self
        self.performanceView?.performanceViewConfigurator.style = .dark
        self.performanceView?.performanceViewConfigurator.options = .all
        self.performanceView?.start()
        self.performanceView?.show()
        
        // Do any additional setup after loading the view.
        let textView = UIButton(type: .custom)
        textView.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 100, self.view.frame.size.width, 60)
        textView.setTitle("跳转到session页面", for: .normal)
        textView.backgroundColor = UIColor.red;
        textView.setTitleColor(UIColor.white, for: .normal)
        textView.rx.tap
            .subscribe(onNext: { [weak self] data in
                print(data)
                if (self?.navigationController != nil) {
                    let sessionViewController = IMSessionViewController()
                    self?.navigationController?.pushViewController(sessionViewController, animated: true)
                }
            }).disposed(by: self.disposeBag)
        self.view.addSubview(textView)
        let textView1 = UIButton(type: .custom)
        textView1.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 200, self.view.frame.size.width, 60)
        textView1.setTitle("创建session", for: .normal)
        textView1.backgroundColor = UIColor.red;
        textView1.setTitleColor(UIColor.white, for: .normal)
        textView1.rx.tap
            .compose(DefaultRxTransformer.io2Main())
            .flatMap({ (value) -> Observable<Session> in
//                let entityId = Int64(arc4random() % 100000) + 100
                let entityId = Int64(4)
                return IMCoreManager.shared.getMessageModule().createSingleSession(entityId)
            })
            .subscribe(onNext: { data in
                print(data)
                do {
                    try IMCoreManager.shared.database.sessionDao.insertOrUpdateSessions(data)
                } catch {
                    print(error)
                }
            }, onError: { error in
                print(error)
            }).disposed(by: self.disposeBag)
        self.view.addSubview(textView1)
        
        let textView2 = UIButton(type: .custom)
        textView2.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 300, self.view.frame.size.width, 60)
        if isRecording {
            textView2.setTitle("停止录音", for: .normal)
        } else {
            textView2.setTitle("录音", for: .normal)
        }
        textView2.backgroundColor = UIColor.red;
        textView2.setTitleColor(UIColor.white, for: .normal)
        textView2.rx.tap
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
                                textView2.setTitle("录音", for: .normal)
                            }
                        }
                    }
                } else {
                    OggOpusAudioRecorder.shared.stopRecording()
                }
                self.isRecording = OggOpusAudioRecorder.shared.isRecording()
                if self.isRecording {
                    textView2.setTitle("停止录音", for: .normal)
                } else {
                    textView2.setTitle("录音", for: .normal)
                }
            }).disposed(by: self.disposeBag)
        self.view.addSubview(textView2)
        
        let textView3 = UIButton(type: .custom)
        textView3.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 400, self.view.frame.size.width, 60)
        if self.isPlaying {
            textView3.setTitle("停止播放", for: .normal)
        } else {
            textView3.setTitle("播放", for: .normal)
        }
        textView3.backgroundColor = UIColor.red;
        textView3.setTitleColor(UIColor.white, for: .normal)
        textView3.rx.tap
            .subscribe(onNext: { data in
                self.isPlaying = OggOpusAudioPlayer.shared.isPlaying()
                if (!self.isPlaying) {
                    let filePath = NSTemporaryDirectory() + "temp.oga"
                    let res = OggOpusAudioPlayer.shared.startPlaying(filePath) {db, duration ,path, stopped in
                        DDLogDebug("playing: callback \(db), \(duration) \(path), \(stopped),  \(Thread.current)  ")
                        if stopped {
                            DispatchQueue.main.async {
                                textView3.setTitle("播放", for: .normal)
                            }
                        }
                    }
                    DDLogDebug("playing: startPlaying \(res) ")
                } else {
                    OggOpusAudioPlayer.shared.stopPlaying()
                }
                self.isPlaying = OggOpusAudioPlayer.shared.isPlaying()
                if self.isPlaying {
                    textView3.setTitle("停止播放", for: .normal)
                } else {
                    textView3.setTitle("播放", for: .normal)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView3)
        
        let textView4 = UIButton(type: .custom)
        textView4.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 500, self.view.frame.size.width, 60)
        textView4.setTitle("跳转到视频播放页面", for: .normal)
        textView4.backgroundColor = UIColor.red;
        textView4.setTitleColor(UIColor.white, for: .normal)
        textView4.rx.tap
            .subscribe(onNext: { [weak self] data in
                if (self?.navigationController != nil) {
                    let vc = IMVideoController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView4)
        
        
        let textView5 = UIButton(type: .custom)
        textView5.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 600, self.view.frame.size.width, 60)
        textView5.setTitle("webrtc", for: .normal)
        textView5.backgroundColor = UIColor.red;
        textView5.setTitleColor(UIColor.white, for: .normal)
        textView5.rx.tap
            .subscribe(onNext: { [weak self] in
                if (self?.navigationController != nil) {
                    let vc = LiveController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView5)
        
        let textView6 = UIButton(type: .custom)
        textView6.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 700, self.view.frame.size.width, 60)
        textView6.setTitle("测试sql", for: .normal)
        textView6.backgroundColor = UIColor.red;
        textView6.setTitleColor(UIColor.white, for: .normal)
        textView6.rx.tap
            .asObservable()
            .compose(DefaultRxTransformer.io2Main())
            .subscribe(onNext: { [weak self] in
                do {
                    guard let sf = self else {
                        return
                    }
//                    let msgs = try IMCoreManager.shared.database.sessionDao.querySessions(100, IMCoreManager.shared.severTime)
//                    if (msgs != nil) {
//                        for m in msgs! {
//                            print("\(m.id) \(m.entityId) \(m.id)")
//                            let count = try IMCoreManager.shared.database.messageDao.getUnReadCount(m.id, MsgOperateStatus.ClientRead.rawValue)
//                            print("count: \(count)")
//                        }
//                    }
                    
                    let msgDao = IMCoreManager.shared.database.messageDao
                    let message = Message(id: 1, sessionId: 1, fromUId: 1, msgId: 1, type: 1, content: "fsfdsf", sendStatus: MsgSendStatus.Success.rawValue, operateStatus: 1, data: nil,
                        cTime: Date().timeMilliStamp, mTime: Date().timeMilliStamp)
                    try msgDao.insertOrReplaceMessages([message])
                    message.msgId = 2
                    message.content = "fsfafa"
                    try msgDao.insertOrIgnoreMessages([message])
                    let dbMsg = try msgDao.findMessage(1, 1, 1)
                    print(dbMsg)
                } catch {
                    print(error)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView6)
    }
    
}

