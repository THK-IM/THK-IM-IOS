//
//  ObservableType+compose.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation
import RxSwift

struct ObservableTransformer<T, R> {
    let transformer: (Observable<T>) -> Observable<R>
    init(_ transformer: @escaping (Observable<T>) -> Observable<R>) {
        self.transformer = transformer
    }
    
    func call(_ observable: Observable<T>) -> Observable<R> {
        return transformer(observable)
    }
}

extension ObservableType {
    func compose<R>(_ transformer: ObservableTransformer<Element, R>) -> Observable<R> {
        return transformer.call(self.asObservable())
    }
}
