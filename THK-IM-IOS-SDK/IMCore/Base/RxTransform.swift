//
//  RxTransform.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import RxSwift
import Moya

public class RxTransformer {
    
    public static let shared = RxTransformer(queueSize: 16)
    
    var scheduler : ImmediateSchedulerType
    
    public init(queueSize: Int) {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = queueSize
        self.scheduler = RxSwift.OperationQueueScheduler(operationQueue: operationQueue)
    }
    
    public func io2Main<T>() -> ObservableTransformer<T, T> {
        return ObservableTransformer({ upstream in
            upstream.subscribe(on: self.scheduler).observe(on: MainScheduler.instance)
        })
    }
    
    public func io2Io<T>() -> ObservableTransformer<T, T> {
        return ObservableTransformer({ upstream in
            upstream.subscribe(on: self.scheduler).observe(on: self.scheduler)
        })
    }
    
    public func response2Bean<T: Decodable>(_ type: T.Type) -> ObservableTransformer<Response, T> {
        return ObservableTransformer({ upstream in
            upstream.flatMap({ (response) -> Observable<T> in
                if (response.statusCode >= 200 && response.statusCode < 300) {
                    let body = try JSONDecoder().decode(type, from: response.data)
                    return Observable.just(body)
                } else {
                    var codeMsg = try? JSONDecoder().decode(CodeMessage.self, from: response.data)
                    if (codeMsg != nil) {
                        return Observable.error(CodeMessageError(codeMsg: codeMsg!))
                    } else {
                        let msg = String(data: response.data, encoding: .utf8) ?? ""
                        codeMsg = CodeMessage(code: response.statusCode, message: msg)
                        return Observable.error(CodeMessageError(codeMsg: codeMsg!))
                    }
                }
            })
        })
    }
    
    public func response2Void() -> ObservableTransformer<Response, Void> {
        return ObservableTransformer({ upstream in
            upstream.flatMap({ (response) -> Observable<Void> in
                if (response.statusCode >= 200 && response.statusCode < 300) {
                    return Observable.empty()
                } else {
                    var codeMsg = try? JSONDecoder().decode(CodeMessage.self, from: response.data)
                    if (codeMsg != nil) {
                        return Observable.error(CodeMessageError(codeMsg: codeMsg!))
                    } else {
                        let msg = String(data: response.data, encoding: .utf8) ?? ""
                        codeMsg = CodeMessage(code: response.statusCode, message: msg)
                        return Observable.error(CodeMessageError(codeMsg: codeMsg!))
                    }
                }
            })
        })
    }
}
