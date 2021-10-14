//
//  LukaBridgeResponse.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 15/9/21.
//

import Foundation

internal class LukaBridgeResponse {
    
    let action: LukaPaymentStep
    let payload: Any
    
    internal init(action: LukaPaymentStep, payload: Any) {
        self.action = action
        self.payload = payload
    }
    
}
