//
//  LukaGateway.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

protocol LukaGateway {
    
    func bridge() -> LukaBridge
    
    func onMakeResolver() -> BluesnapResolver
    
}

class BluesnapGateway : LukaGateway {
    
    func bridge() -> LukaBridge {
        return BluesnapBridge()
    }
    
    func onMakeResolver() -> BluesnapResolver {
        return BluesnapResolver()
    }
    
}
