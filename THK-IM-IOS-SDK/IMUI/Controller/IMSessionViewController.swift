//
//  IMSessionViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation
import RxSwift
import UIKit
import CocoaLumberjack
import SwiftEventBus


class IMSessionViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var sessionTableView : UITableView?
    private var sessions: Array<Session> = Array()
    private let disposeBag = DisposeBag()
    private var isLoading = false
    private let lock = NSLock()
    
    deinit {
        print("IMSessionViewController, de init")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let frame = self.view.frame
        self.sessionTableView = UITableView(frame: frame)
        self.sessionTableView?.rowHeight = UITableView.automaticDimension
        self.sessionTableView?.estimatedRowHeight = 100
        self.sessionTableView?.dataSource = self
        self.sessionTableView?.delegate = self
        self.view.addSubview(self.sessionTableView!)
        self.loadSessions()
    }
    
    func loadSessions() {
        if (isLoading) {
            return
        }
        DDLogDebug("scrollViewDidScroll loadSessions ing")
        isLoading = true
        var latestSessionTime: Int64 = 0
        if (self.sessions.count == 0) {
            latestSessionTime = IMCoreManager.shared.severTime
        } else {
            latestSessionTime = self.sessions[self.sessions.count-1].mTime
        }
        IMCoreManager.shared.getMessageModule()
            .queryLocalSessions(20, latestSessionTime)
            .compose(DefaultRxTransformer.io2Main())
            .subscribe(onNext: { [weak self ]value in
                self?.sessions.append(contentsOf: value)
                self?.sessionTableView?.reloadData()
                if (value.count >= 20) {
                    self?.isLoading = false
                }
            }).disposed(by: self.disposeBag)
     
        registerSessionEvent()
    }
    
    private func insertSession(_ session: Session) {
        lock.lock()
        defer {lock.unlock()}
        guard let tableView = self.sessionTableView else { return }
        let pos = findPosition(session)
        if (pos != -1) {
            self.sessions.remove(at: pos)
            tableView.deleteRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
        }
        
        // 新Session
        let insertPos = findInsertPosition(session)
        self.sessions.insert(session, at: insertPos)
        tableView.insertRows(at: [IndexPath.init(row: insertPos, section: 0)], with: .none)
    }
    
    private func removeSession(_ session: Session) {
        lock.lock()
        defer {lock.unlock()}
        guard let tableView = self.sessionTableView else { return }
        let pos = findPosition(session)
        if (pos == -1) {
            // 老session，替换reload
            self.sessions.remove(at: pos)
            tableView.deleteRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
        }
    }
    
    private func findPosition(_ session: Session) -> Int {
        var pos = 0
        for s in self.sessions {
            if (s.id == session.id) {
                return pos
            }
            pos += 1
        }
        return -1
    }
    
    private func findInsertPosition(_ session: Session) -> Int {
        return 0
    }
    
    
    func registerSessionEvent() {
        SwiftEventBus.onMainThread(self, name: IMEvent.SessionNew.rawValue, handler: { [weak self ] result in
            guard let session = result?.object as? Session else {
                return
            }
            self?.insertSession(session)
        })
        SwiftEventBus.onMainThread(self, name: IMEvent.SessionUpdate.rawValue, handler: { [weak self ] result in
            guard let session = result?.object as? Session else {
                return
            }
            self?.insertSession(session)
        })
        
        SwiftEventBus.onMainThread(self, name: IMEvent.SessionDelete.rawValue, handler: { [weak self ] result in
            guard let session = result?.object as? Session else {
                return
            }
            self?.removeSession(session)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = self.sessions[indexPath.row]
        let provider = IMUIManager.shared.getSessionCellProvider(session.type)
        let identifier = provider.identifier()
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (cell == nil) {
            cell = provider.viewCell()
        }
        let sessionCell = cell as! BaseSessionCell
        sessionCell.setSession(self.sessions[indexPath.row])
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sessionCell = cell as! BaseSessionCell
        sessionCell.appear()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sessionCell = cell as! BaseSessionCell
        sessionCell.disappear()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let messageController = IMMessageViewController()
        messageController.session = self.sessions[indexPath.row]
        self.navigationController?.pushViewController(messageController, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let h = self.sessionTableView!.frame.height
        let distance = self.sessionTableView!.contentSize.height - self.sessionTableView!.contentOffset.y
        DDLogDebug("scrollViewDidScroll, h:" + h.description + ", dis: " + distance.description)
        if (h > distance) {
            DDLogDebug("scrollViewDidScroll loadSessions start")
            self.loadSessions()
        }
        if (self.sessionTableView!.contentOffset.y < 0) {
            DDLogDebug("scrollViewDidScroll 最顶部")
        }
    }
    
}
