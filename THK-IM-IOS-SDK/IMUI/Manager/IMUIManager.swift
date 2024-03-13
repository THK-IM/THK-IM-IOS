//
//  IMUIManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

open class IMUIManager: NSObject {
    
    public static let shared = IMUIManager()
    
    private var msgCellProviders = [Int:IMBaseMessageCellProvider]()
    private var sessionCellProviders = [Int:IMBaseSessionCellProvider]()
    private var bottomFunctionProviders = [IMBaseFunctionCellProvider]()
    private var panelProviders = [IMBasePanelViewProvider]()
    private var msgOperators = [IMMessageOperator]()
    public var contentProvider: IMProvider? = nil
    public var contentPreviewer: IMPreviewer? = nil
    public var pageRouter: IMPageRouter? = nil
    public var uiResourceProvider: IMUIResourceProvider? = nil
    
    private override init() {
        super.init()
        
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMUnSupportMsgProcessor())
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMTextMsgProcessor())
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMImageMsgProcessor())
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMAudioMsgProcessor())
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMVideoMsgProcessor())
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMReeditMsgProcessor())
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMRevokeMsgProcessor())
        IMCoreManager.shared.messageModule.registerMsgProcessor(IMRecordMsgProcessor())
        
        self.registerMsgCellProviders(IMUnSupportMsgCellProvider())
        self.registerMsgCellProviders(IMTimeLineMsgCellProvider())
        self.registerMsgCellProviders(IMTextMsgCellProvider())
        self.registerMsgCellProviders(IMImageMsgCellProvider())
        self.registerMsgCellProviders(IMAudioMsgCellProvider())
        self.registerMsgCellProviders(IMVideoMsgCellProvider())
        self.registerMsgCellProviders(IMRevokeMsgCellProvider())
        self.registerMsgCellProviders(IMRecordMsgCellProvider())
        
        self.registerSessionCellProvider(IMSingleSessionCellProvider())
        self.registerSessionCellProvider(IMGroupSessionCellProvider())
        self.registerSessionCellProvider(IMSuperGroupSessionCellProvider())
        
        self.registerBottomFunctionProvider(IMPhotoFunctionProvider(), IMCameraFunctionProvider())
        self.registerPanelProvider(IMUnicodeEmojiPanelProvider(), IMUnicodeEmojiPanelProvider())
        self.registerSessionCellProvider(IMDefaultSessionCellProvider())
        
        self.registerMessageOperator(IMMsgDeleteOperator())
        self.registerMessageOperator(IMMsgCopyOperator())
        self.registerMessageOperator(IMMsgForwardOperator())
        self.registerMessageOperator(IMMsgRevokeOperator())
        self.registerMessageOperator(IMMsgReplyOperator())
        self.registerMessageOperator(IMMsgMultiSelectOperator())
        self.registerMessageOperator(IMMsgEditOperator())
        
    }
    
    public func registerMsgCellProviders(_ provider: IMBaseMessageCellProvider) {
        self.msgCellProviders[provider.messageType()] = provider
    }
    
    public func getMsgCellProvider(_ type: Int) -> IMBaseMessageCellProvider {
        let provider = self.msgCellProviders[type]
        return provider == nil ? self.msgCellProviders[MsgType.UnSupport.rawValue]! : provider!
    }
    
    public func registerSessionCellProvider(_ provider: IMBaseSessionCellProvider) {
        self.sessionCellProviders[provider.sessionType()] = provider
    }
    
    public func getSessionCellProvider(_ type: Int) -> IMBaseSessionCellProvider {
        let provider = self.sessionCellProviders[type]
        return provider == nil ? self.sessionCellProviders[0]! : provider!
    }
    
    public func registerBottomFunctionProvider(_ ps: IMBaseFunctionCellProvider...) {
        for p in ps {
            self.bottomFunctionProviders.append(p)
        }
    }
    
    public func getBottomFunctionProviders() -> Array<IMBaseFunctionCellProvider> {
        return bottomFunctionProviders
    }
    
    public func registerPanelProvider(_ ps: IMBasePanelViewProvider...) {
        for p in ps {
            self.panelProviders.append(p)
        }
    }
    
    public func getPanelProviders() -> Array<IMBasePanelViewProvider> {
        return panelProviders
    }
    
    public func registerMessageOperator(_ msgOperator: IMMessageOperator) {
        msgOperators.append(msgOperator)
        msgOperators = msgOperators.sorted { p1, p2 in
            return p1.id() < p2.id()
        }
    }
    
    public func getMessageOperators(_ message: Message) -> [IMMessageOperator] {
        return msgOperators.filter { p in
            return p.supportMessage(message)
        }
    }
    
    public func nicknameForSessionMember(_ user: User, _ sessionMember: SessionMember?) -> String {
        if (sessionMember != nil && sessionMember!.noteName != nil && !sessionMember!.noteName!.isEmpty) {
            return sessionMember!.noteName!
        } else {
            return user.nickname
        }
    }
    
    public func avatarForSessionMember(_ user: User, _ sessionMember: SessionMember?) -> String? {
        var avatar : String? = nil
        if (sessionMember != nil && sessionMember!.noteAvatar != nil && !sessionMember!.noteAvatar!.isEmpty) {
            avatar = sessionMember!.noteAvatar!
        } else {
            avatar = user.avatar
        }
        return avatar
    }
    
    public func initConfig() {
        
    }
    
    
}
