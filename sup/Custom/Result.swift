//
//  Result.swift
//  sup
//
//  Created by Robert Malko on 6/9/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}
