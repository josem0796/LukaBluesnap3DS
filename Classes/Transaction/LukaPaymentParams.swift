//
//  LukaPaymentParams.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

class LukaPaymentParams {
    
    /**
     The choosen payment method
     */
    let method: LukaMethod
    
    /**
     The amount to charge
     */
    let amount: Double
    
    /**
     The currency for the charge
     */
    let currency: LukaCurrency
    
    /**
     The email is mandatory for lukapay. If not specified, it will be asked in the paument form
     */
    let email: String?
    
    /**
     Enablee 3D secure authentication
     */
    var enable3DSecureAuthentication: Bool = false
    
    init(method: LukaMethod, amount: Double, currency: LukaCurrency, email: String? = nil, enable3DSecureAuthentication: Bool = false) {
        self.method = method
        self.amount = amount
        self.currency = currency
        self.email = email
        self.enable3DSecureAuthentication = enable3DSecureAuthentication
    }
    
}