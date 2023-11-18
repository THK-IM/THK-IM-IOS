//
//  DefaultUserModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/4.
//

import Foundation
import RxSwift

open class DefaultUserModule : UserModule {

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
    
    lazy var selfBubbleImage = {
        let image = self.bubble.drawRectWithRoundedCorner(
            radius: 12.0, borderWidth: 1.0,
            backgroundColor: UIColor.init(hex: "dddddd").withAlphaComponent(0.5),
            borderColor: UIColor.init(hex: "cccccc"), width: 40, height: 40, pos: 1)
        return image
    }()
    
    lazy var userDefaultImage = {
        let image = self.bubble.drawRectWithRoundedCorner(
            radius: 12.0, borderWidth: 1.0,
            backgroundColor: UIColor.init(hex: "dddddd").withAlphaComponent(0.5),
            borderColor: UIColor.init(hex: "cccccc"), width: 40, height: 40, pos: 2)
        return image
    }()
    
    public func onUserInfoUpdate(user: User) {
        
    }
    
    public func getUserChatBubble(id: Int64) -> Observable<UIImage> {
        return Observable.create({[weak self] observer -> Disposable in
            if id == 0 {
                if self?.systemBubbleImage == nil {
                    observer.onError(CocoaError.error(CocoaError.featureUnsupported))
                } else {
                    observer.onNext((self?.systemBubbleImage)!)
                    observer.onCompleted()
                }
            } else if id == IMCoreManager.shared.uId {
                if self?.selfBubbleImage == nil {
                    observer.onError(CocoaError.error(CocoaError.featureUnsupported))
                } else {
                    observer.onNext((self?.selfBubbleImage)!)
                    observer.onCompleted()
                }
            } else {
                if self?.userDefaultImage == nil {
                    observer.onError(CocoaError.error(CocoaError.featureUnsupported))
                } else {
                    observer.onNext((self?.userDefaultImage)!)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        })
    }
    
    public func getUserInfo(id: Int64) -> Observable<User> {
        return Observable.create({observer -> Disposable in
            let now = Date().timeMilliStamp
            let user = User(
                id: id, name: "thinking", avatar: "https://picsum.photos/300/300",
                sex: 0, status: 1, cTime: now, mTime: now
            )
            observer.onNext(user)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    public func onSignalReceived(_ subType: Int, _ body: String) {
        
    }
    
    
}
