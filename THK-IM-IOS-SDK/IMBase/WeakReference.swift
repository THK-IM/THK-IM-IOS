//
//  WeakReference.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation

class WeakReference<T: AnyObject> {
  weak var value: T?
  init (value: T) {
    self.value = value
  }
}
