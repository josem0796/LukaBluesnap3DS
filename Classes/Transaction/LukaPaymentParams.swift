//
//  LukaPaymentParams.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

public class LukaPaymentParams {
    
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
    var enable3DSecureAuthentication: Bool = true
    
    var customTraceId: String? = nil
    
    public init(method: CreditCardMethod, amount: Double, currency: LukaCurrency, email: String? = nil, enable3DSecureAuthentication: Bool = false, customTraceId: String? = nil) {
        self.method = method
        self.amount = amount
        self.currency = currency
        self.email = email
        self.enable3DSecureAuthentication = enable3DSecureAuthentication
        self.customTraceId = customTraceId
    }
    
}
