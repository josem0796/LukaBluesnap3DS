//
//  Luka.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 15/9/21.
//

import Foundation

public class Luka {
    
    /**
     Api object
     */
    private static var shared: LukaApi!
    
    private init() {
        // private init to avoid multiple instances
    }
    
    public static func initialize(credentials: LukaAuthCredentials, forDebug: Bool) -> LukaApi {
        generateLukaApi(forDebug: forDebug)
        shared.authenticate(credentials: credentials)
        return shared
    }
    
    private static func generateLukaApi(forDebug: Bool) {
        if shared == nil {
            shared = LukaApi(forDebug: forDebug)
        }
    }
    
}
