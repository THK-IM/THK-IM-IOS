//
//  IMCustomModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/7.
//  Copyright © 2024 THK. All rights reserved.
//

import CocoaLumberjack
import Foundation
import RxSwift


class IMCustomModule: DefaultCustomModule {

    static let liveCallSignalType = 400

    private let disposeBag = DisposeBag()

    override func onSignalReceived(_ type: Int, _ body: String) {
        if type == IMCustomModule.liveCallSignalType {
            if let signal = try? JSONDecoder().decode(
                LiveSignal.self, from: body.data(using: .utf8) ?? Data())
            {
                DDLogInfo("IMLiveManager: onSignalReceived \(signal)")
                LiveManager.shared.onLiveSignalReceived(signal: signal)
            }
        }
    }

}
