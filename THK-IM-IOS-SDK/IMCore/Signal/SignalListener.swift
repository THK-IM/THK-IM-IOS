//
//  SignalListener.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/20.
//

import Foundation

public protocol SignalListener {

    func onSignalStatusChange(_ status: SignalStatus)

    func onNewSignal(_ type: Int, _ body: String)

}
