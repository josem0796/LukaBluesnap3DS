//
//  LukaCurrency.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 16/9/21.
//

import Foundation

internal struct LukaCurrency: Codable {
    
    let iso: String
    let symbol: String
    
    static let usd = LukaCurrency(iso: "USD", symbol: "$")
    
    enum CodingKeys: String, CodingKey {
        case iso, symbol
    }
    
    static func from(iso: String?) -> LukaCurrency {
        if iso == usd.iso {
            return usd
        } else {
            return usd // default
        }
    }
    
}
