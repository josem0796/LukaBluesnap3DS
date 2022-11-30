//
//  LukaCardVaultParams.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 11/10/21.
//

import Foundation

class LukaCardVaultParams : LukaPaymentParams {
    
    let lukaCustomerId: String?
    
    init(customerId: String?, email: String) {
        self.lukaCustomerId = customerId
        super.init(method: CreditCardMethod(), amount: 1.0, currency: LukaCurrency.usd, email: email, enable3DSecureAuthentication: true)
    }
    
}
