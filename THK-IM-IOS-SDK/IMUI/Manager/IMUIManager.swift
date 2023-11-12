//
//  IMUIManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

public class IMUIManager: NSObject {
    
    static let shared = IMUIManager()
    
    private var msgCellProviders = [Int:IMBaseMessageCellProvider]()
    private var sessionCellProviders = [Int:IMBaseSessionCellProvider]()
    private var bottomFunctionProviders = [IMBaseFunctionCellProvider]()
    private var panelProviders = [IMBasePanelViewProvider]()
    private var msgOperators = [String: IMMessageOperator]()
    var contentProvider: IMProvider? = nil
    var contentPreviewer: IMPreviewer? = nil
    
    private var cornerImageMap = [String: UIImage]()
    
    private let lock = NSLock()
    
    private override init() {
        super.init()
        
        IMCoreManager.shared.getMessageModule().registerMsgProcessor(IMUnSupportMsgProcessor())
        IMCoreManager.shared.getMessageModule().registerMsgProcessor(IMTextMsgProcessor())
        IMCoreManager.shared.getMessageModule().registerMsgProcessor(IMImageMsgProcessor())
        IMCoreManager.shared.getMessageModule().registerMsgProcessor(IMAudioMsgProcessor())
        IMCoreManager.shared.getMessageModule().registerMsgProcessor(IMVideoMsgProcessor())
        
        self.registerMsgCellProviders(IMUnSupportMsgCellProvide())
        self.registerMsgCellProviders(IMTimeLineMsgCellProvider())
        self.registerMsgCellProviders(IMTextMsgCellProvider())
        self.registerMsgCellProviders(IMImageMsgCellProvider())
        self.registerMsgCellProviders(IMAudioMsgCellProvider())
        self.registerMsgCellProviders(IMVideoMsgCellProvider())
        
        self.registerSessionCellProvider(IMSingleSessionCellProvider())
        
        self.registerBottomFunctionProvider(IMPhotoFunctionProvider(), IMCameraFunctionProvider())
        self.registerPanelProvider(IMUnicodeEmojiPanelProvider(), IMUnicodeEmojiPanelProvider())
        self.registerSessionCellProvider(IMDefaultSessionCellProvider())
        
        self.registerMessageOperator(IMMsgDeleteOperator())
        self.registerMessageOperator(IMMsgCopyOperator())
        self.registerMessageOperator(IMMsgForwardOperator())
        self.registerMessageOperator(IMMsgRevokeOperator())
        self.registerMessageOperator(IMMsgReplyOperator())
        self.registerMessageOperator(IMMsgMultiSelectOperator())
        
    }
    
    func registerMsgCellProviders(_ provider: IMBaseMessageCellProvider) {
        lock.lock()
        defer {lock.unlock()}
        self.msgCellProviders[provider.messageType()] = provider
    }
    
    func getMsgCellProvider(_ type: Int) -> IMBaseMessageCellProvider {
        lock.lock()
        defer {lock.unlock()}
        let provider = self.msgCellProviders[type]
        return provider == nil ? self.msgCellProviders[MsgType.UnSupport.rawValue]! : provider!
    }
    
    func registerSessionCellProvider(_ provider: IMBaseSessionCellProvider) {
        lock.lock()
        defer {lock.unlock()}
        self.sessionCellProviders[provider.sessionType()] = provider
    }
    
    func getSessionCellProvider(_ type: Int) -> IMBaseSessionCellProvider {
        lock.lock()
        defer {lock.unlock()}
        let provider = self.sessionCellProviders[type]
        return provider == nil ? self.sessionCellProviders[0]! : provider!
    }
    
    func registerBottomFunctionProvider(_ ps: IMBaseFunctionCellProvider...) {
        lock.lock()
        defer {lock.unlock()}
        for p in ps {
            self.bottomFunctionProviders.append(p)
        }
    }
    
    func getBottomFunctionProviders() -> Array<IMBaseFunctionCellProvider> {
        return bottomFunctionProviders
    }
    
    func registerPanelProvider(_ ps: IMBasePanelViewProvider...) {
        lock.lock()
        defer {lock.unlock()}
        for p in ps {
            self.panelProviders.append(p)
        }
    }
    
    func getPanelProviders() -> Array<IMBasePanelViewProvider> {
        return panelProviders
    }
    
    func registerMessageOperator(_ msgOperator: IMMessageOperator) {
        msgOperators[msgOperator.id()] = msgOperator
    }
    
    func getMessageOperators(_ message: Message) -> [IMMessageOperator] {
        var operators = [IMMessageOperator]()
        for msgOperator in msgOperators {
            operators.append(msgOperator.value)
        }
        return operators
    }
    
    lazy var bubble: Bubble = {
        return Bubble()
    }()
    
    lazy var systemBubbleImage = {
        let image = self.bubble.drawRectWithRoundedCorner(
            radius: 6.0, borderWidth: 0.0,
            backgroundColor: UIColor.init(hex: "333333").withAlphaComponent(0.2),
            borderColor: UIColor.init(hex: "333333"), width: 20, height: 20, pos: 0)
        return image
    }()
    
    func cornerBackgroundImage(_ radius: Int, _ color: UIColor) -> UIImage {
        let key = "\(radius)-\(color.toHexString())"
        var image = cornerImageMap[key]
        if image == nil {
            let size = CGFloat(2 * (radius+1) + 8)
            image = self.bubble.drawRectWithRoundedCorner(radius: CGFloat(radius), borderWidth: 1, backgroundColor: color, borderColor: color, width: size, height: size)
            cornerImageMap[key] = image
        }
        return image!
    }
    
    func initConfig() {
        
    }
    
    
}
