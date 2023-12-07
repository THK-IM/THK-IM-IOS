//
//  MainViewController.swift
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


class MainViewController: UIViewController, PerformanceMonitorDelegate {
    
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
            .compose(RxTransformer.shared.io2Main())
            .flatMap({ (value) -> Observable<Session> in
//                let entityId = Int64(arc4random() % 100000) + 100
                let entityId = Int64(4)
                return IMCoreManager.shared.getMessageModule().createSingleSession(entityId)
            })
            .subscribe(onNext: { data in
                print(data)
                do {
                    try IMCoreManager.shared.database.sessionDao().insertOrUpdateSessions(data)
                } catch {
                    print(error)
                }
            }, onError: { error in
                print(error)
            }).disposed(by: self.disposeBag)
        self.view.addSubview(textView1)
        
        
        let textView5 = UIButton(type: .custom)
        textView5.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 300, self.view.frame.size.width, 60)
        textView5.setTitle("音视频测试", for: .normal)
        textView5.backgroundColor = UIColor.red;
        textView5.setTitleColor(UIColor.white, for: .normal)
        textView5.rx.tap
            .subscribe(onNext: { [weak self] in
                if (self?.navigationController != nil) {
                    let vc = MediaViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView5)
        
        let textView6 = UIButton(type: .custom)
        textView6.frame = CGRectMake(self.view.safeAreaInsets.left, self.view.safeAreaInsets.top + 400, self.view.frame.size.width, 60)
        textView6.setTitle("测试sql", for: .normal)
        textView6.backgroundColor = UIColor.red;
        textView6.setTitleColor(UIColor.white, for: .normal)
        textView6.rx.tap
            .asObservable()
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: {
                do {
                    let sessions = try IMCoreManager.shared.database
                        .sessionDao().findSessions(0, 1708851739664322560, IMCoreManager.shared.severTime)
                    if (sessions != nil) {
                        for session in sessions! {
                            print("\(session.id) \(session.entityId)")
                            let count = try IMCoreManager.shared.database.messageDao().getUnReadCount(session.id)
                            print("count: \(count)")
                        }
                    }
                    
                } catch {
                    print(error)
                }
            })
            .disposed(by: self.disposeBag)
        self.view.addSubview(textView6)
    }
    
}

