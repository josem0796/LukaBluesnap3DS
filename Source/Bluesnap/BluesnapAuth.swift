//
//  BluesnapAuth.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

internal struct BluesnapAuth {
    
    let userId: String
    let token: String
    
    init(userId: String, token: String) {
        self.userId = userId
        self.token = token
    }
    
}
