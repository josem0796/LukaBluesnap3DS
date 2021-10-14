//
//  LukaMethod.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

protocol LukaMethod {
    
    func gateway() -> LukaGateway
    
    func supportedCurrencies() -> [LukaCurrency]

}

class CreditCardMethod : LukaMethod {
    
    func gateway() -> LukaGateway {
        return BluesnapGateway()
    }
    
    func supportedCurrencies() -> [LukaCurrency] {
        return [.usd]
    }
    
}
