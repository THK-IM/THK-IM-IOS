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


open class IMSessionViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate, IMSessionCellOperator {
    
    private var containerView = UIView()
    private var sessionTableView = UITableView()
    private var sessions: Array<Session> = Array()
    private var isLoading = false
    private let lock = NSLock()
    private var isTop = false
    private var newSessions = [Session]()
    private var removeSessions = [Session]()
    
    public var parentId: Int64 = 0
    
    deinit {
        print("IMSessionViewController, de init")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(containerView)
        self.containerView.backgroundColor = UIColor.init(hex: "#F8F8F8")
        let top = getTitleBarHeight()
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        containerView.clipsToBounds = true
        self.sessionTableView.separatorStyle = .none
        self.sessionTableView.rowHeight = UITableView.automaticDimension
        self.sessionTableView.estimatedRowHeight = 100
        self.sessionTableView.dataSource = self
        self.sessionTableView.delegate = self
        self.sessionTableView.backgroundColor = .clear
        self.containerView.addSubview(self.sessionTableView)
        self.sessionTableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.loadSessions()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isTop = true
        for s in newSessions {
            self.onSessionUpdate(s)
        }
        newSessions.removeAll()
        for s in removeSessions {
            self.onSessionRemove(s)
        }
        removeSessions.removeAll()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.isTop = false
    }
    
    open func loadSessions() {
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
        IMCoreManager.shared.messageModule
            .queryLocalSessions(self.parentId, 20, latestSessionTime)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self ]value in
                self?.sessions.append(contentsOf: value)
                self?.sessionTableView.reloadData()
                if (value.count >= 20) {
                    self?.isLoading = false
                }
            }).disposed(by: self.disposeBag)
     
        registerSessionEvent()
    }
    
    private func onNewSession(_ session: Session) {
        self.onSessionUpdate(session)
    }
    
    private func onSessionUpdate(_ session: Session) {
        if !isTop {
            newSessions.removeAll(where: { newSession in
                return newSession.id == session.id
            })
            newSessions.append(session)
            return
        }
        let tableView = self.sessionTableView
        let oldPos = findPosition(session)
        if (oldPos >= 0 && oldPos < self.sessions.count) {
            self.sessions.remove(at: oldPos)
            let insertPos = findInsertPosition(session)
            if (oldPos == insertPos) {
                self.sessions.insert(session, at: insertPos)
                tableView.reloadRows(at: [IndexPath.init(row: insertPos, section: 0)], with: .none)
            } else {
                tableView.deleteRows(at: [IndexPath.init(row: oldPos, section: 0)], with: .none)
                self.sessions.insert(session, at: insertPos)
                tableView.insertRows(at: [IndexPath.init(row: insertPos, section: 0)], with: .none)
            }
        } else {
            // 新Session
            let insertPos = findInsertPosition(session)
            self.sessions.insert(session, at: insertPos)
            tableView.insertRows(at: [IndexPath.init(row: insertPos, section: 0)], with: .none)
        }

    }
    
    private func onSessionRemove(_ session: Session) {
        if !isTop {
            removeSessions.removeAll(where: { newSession in
                return newSession.id == session.id
            })
            removeSessions.append(session)
            return
        }
        
        let tableView = self.sessionTableView
        let pos = findPosition(session)
        if (pos != -1) {
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
        for i in 0 ..< sessions.count {
            if session.topTimestamp > sessions[i].topTimestamp {
                return i
            } else if (session.topTimestamp == sessions[i].topTimestamp) {
                if (session.mTime >= sessions[i].mTime) {
                    return i
                }
            }
        }
        return sessions.count
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let h = self.sessionTableView.frame.height
        let distance = self.sessionTableView.contentSize.height - self.sessionTableView.contentOffset.y
        if (h > distance) {
            self.loadSessions()
        }
    }
    
    
    func registerSessionEvent() {
        SwiftEventBus.onMainThread(self, name: IMEvent.SessionNew.rawValue, handler: { [weak self ] result in
            guard let session = result?.object as? Session else {
                return
            }
            self?.onNewSession(session)
        })
        
        SwiftEventBus.onMainThread(self, name: IMEvent.SessionUpdate.rawValue, handler: { [weak self ] result in
            guard let session = result?.object as? Session else {
                return
            }
            self?.onSessionUpdate(session)
        })
        
        SwiftEventBus.onMainThread(self, name: IMEvent.SessionDelete.rawValue, handler: { [weak self ] result in
            guard let session = result?.object as? Session else {
                return
            }
            self?.onSessionRemove(session)
        })
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = self.sessions[indexPath.row]
        let provider = IMUIManager.shared.getSessionCellProvider(session.type)
        let identifier = provider.identifier()
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (cell == nil) {
            cell = provider.viewCell()
        }
        let sessionCell = cell as! IMBaseSessionCell
        sessionCell.setSession(self.sessions[indexPath.row])
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sessionCell = cell as! IMBaseSessionCell
        sessionCell.appear()
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sessionCell = cell as! IMBaseSessionCell
        sessionCell.disappear()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let session = self.sessions[indexPath.row]
        self.openSession(session)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = self.sessions[indexPath.row]
        var topText = "置顶"
        var silenceText = "免打扰"
        let deleteText = "删除"
        if (session.topTimestamp > 0) {
            topText = "取消置顶"
        }
        if (session.status & SessionStatus.Silence.rawValue != 0) {
            silenceText = "取消静音"
        }
        let top = UIContextualAction(style: .normal, title: topText, handler: { [weak self] action, view, completionHandler in
            guard let sf = self else {
                return
            }
            let session = sf.sessions[indexPath.row]
            if (session.topTimestamp > 0) {
                session.topTimestamp = 0
            } else {
                session.topTimestamp = IMCoreManager.shared.commonModule.getSeverTime()
            }
            sf.updateSession(session)
            completionHandler(true)
        })
        top.backgroundColor = UIColor.init(hex: "2466e9")
        
        let mute = UIContextualAction(style: .normal, title: silenceText, handler: { [weak self] action, view, completionHandler in
            guard let sf = self else {
                return
            }
            let session = sf.sessions[indexPath.row]
            session.status = session.status ^ SessionStatus.Silence.rawValue
            sf.updateSession(session)
            completionHandler(true)
        })
        mute.backgroundColor = UIColor.init(hex: "f9b018")
        
        let delete = UIContextualAction(style: .normal, title: deleteText, handler: { [weak self] action, view, completionHandler in
            guard let sf = self else {
                return
            }
            let session = sf.sessions[indexPath.row]
            sf.deleteSession(session)
            completionHandler(true)
        })
        delete.backgroundColor = UIColor.init(hex: "d22c69")
        
        let configuration = UISwipeActionsConfiguration(actions: [delete, mute, top])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    
    open func updateSession(_ session: Session) {
        IMCoreManager.shared.messageModule
            .updateSession(session, true)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onError: { error in
                DDLogError("deleteSession error \(error)")
            }, onCompleted: {
            })
            .disposed(by: self.disposeBag)
    }
    
    open func deleteSession(_ session: Session) {
        IMCoreManager.shared.messageModule
            .deleteSession(session, true)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onError: { error in
                DDLogError("deleteSession error \(error)")
            }, onCompleted: {
            })
            .disposed(by: self.disposeBag)
    }
    
    open func openSession(_ session: Session) {
        IMUIManager.shared.pageRouter?.openSession(controller: self, session: session)
    }
    
}
