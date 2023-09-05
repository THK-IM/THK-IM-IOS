//
//  RxTransform.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import RxSwift
import Moya

let DefaultRxTransformer = RxTransformer(queueSize: 8)

class RxTransformer {
    
    var scheduler : ImmediateSchedulerType
    
    init(queueSize: Int) {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = queueSize
        self.scheduler = RxSwift.OperationQueueScheduler(operationQueue: operationQueue)
    }
    
    func io2Main<T>() -> ObservableTransformer<T, T> {
        return ObservableTransformer({ upstream in
            upstream.subscribe(on: self.scheduler).observe(on: MainScheduler.instance)
        })
    }
    
    func io2Io<T>() -> ObservableTransformer<T, T> {
        return ObservableTransformer({ upstream in
            upstream.subscribe(on: self.scheduler).observe(on: self.scheduler)
        })
    }
    
    func response2Bean<T: Decodable>(_ type: T.Type) -> ObservableTransformer<Response, T> {
        return ObservableTransformer({ upstream in
            upstream.flatMap({ (response) -> Observable<T> in
                if (response.statusCode >= 200 && response.statusCode < 300) {
                    let body = try JSONDecoder().decode(type, from: response.data)
                    return Observable.just(body)
                } else {
                    let errorBean = try JSONDecoder().decode(ErrorBean.self, from: response.data)
                    return Observable.error(Exception.IMHttp(errorBean.code, errorBean.message))
                }
            })
        })
    }
    
    func response2Void() -> ObservableTransformer<Response, Void> {
        return ObservableTransformer({ upstream in
            upstream.flatMap({ (response) -> Observable<Void> in
                if (response.statusCode >= 200 && response.statusCode < 300) {
                    return Observable.empty()
                } else {
                    let errorBean = try JSONDecoder().decode(ErrorBean.self, from: response.data)
                    return Observable.error(Exception.IMHttp(errorBean.code, errorBean.message))
                }
            })
        })
    }
}
