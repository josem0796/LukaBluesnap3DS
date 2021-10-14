//
//  LukaSession.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 16/9/21.
//

import Foundation

internal struct LukaSession {
    
    /**
     The id of the user
     */
    let id: String
    
    /**
     The token authenticate Luka request with
     */
    let token: String
    
    let retrievedAt: Date
    
    init(id: String, token: String, retrievedAt: Date) {
        self.id = id
        self.token = token
        self.retrievedAt = retrievedAt
    }
    
    var bearerToken: String {
        get {
            return "Bearer \(token)"
        }
    }
    
    var isExpired: Bool {
        get {
            let current = Date()
            let currentMins = current.timeIntervalSinceReferenceDate / 60
            let oldMins = retrievedAt.timeIntervalSinceReferenceDate / 60
            return currentMins - oldMins > 10
        }
    }
 
}
