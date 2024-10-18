//
//  SignalModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/20.
//

import Foundation

public protocol SignalModule: AnyObject {

    func connect()

    func sendSignal(_ signal: String)

    func disconnect(_ reason: String)

    func getSignalStatus() -> SignalStatus

    func setSignalListener(_ listener: SignalListener)
}
