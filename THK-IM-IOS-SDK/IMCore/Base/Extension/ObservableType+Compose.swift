//
//  ObservableType+compose.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation
import RxSwift

public struct ObservableTransformer<T, R> {
    public let transformer: (Observable<T>) -> Observable<R>
    public init(_ transformer: @escaping (Observable<T>) -> Observable<R>) {
        self.transformer = transformer
    }

    public func call(_ observable: Observable<T>) -> Observable<R> {
        return transformer(observable)
    }
}

extension ObservableType {
    public func compose<R>(_ transformer: ObservableTransformer<Element, R>) -> Observable<R> {
        return transformer.call(self.asObservable())
    }
}
