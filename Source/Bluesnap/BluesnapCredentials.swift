//
//  BluesnapCredentials.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 16/9/21.
//

import Foundation

internal struct BluesnapCredentials: Codable {
    
    let password: String
    let usePaycoMiddleware: Bool
    let userName: String
    
    enum CodingKeys: String, CodingKey {
        case password = "Password"
        case usePaycoMiddleware = "RecaudaPayco"
        case userName = "Username"
    }
    
}
