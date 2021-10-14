//
//  LukaCardPaymentParams.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 11/10/21.
//

import Foundation

class LukaCardPaymentParams : LukaPaymentParams {
    
    let customerId: String
    let card: CreditCard
    
    init(customerId: String, card: CreditCard, amount: Double, currency: LukaCurrency, email: String? = nil, enable3DSecureAuthentication: Bool = false) {
        self.customerId = customerId
        self.card = card
        super.init(method: CreditCardMethod(), amount: amount, currency: currency, email: email, enable3DSecureAuthentication: false)
    }
    
    
}
