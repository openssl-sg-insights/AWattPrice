//
//  Region.swift
//  AWattPrice
//
//  Created by Léon Becker on 11.08.21.
//

import Foundation

enum Region: Int16 {
    case DE = 0
    case AT = 1
    
    var apiName: String {
        switch self {
        case .DE:
            return "DE"
        case .AT:
            return "AT"
        }
    }
}
