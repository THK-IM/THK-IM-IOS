//
//  LoadTask.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

protocol LoadTask: AnyObject {
    
    func start()
    
    func cancel()
    
    func notify(progress: Int, state: Int, err: Error?)
}

