//
//  LukaPaymentResult.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

public struct LukaPaymentResult {
    
    let method: LukaMethod
    let amount: Double
    let currency: LukaCurrency
    let traceId: String
    let charged: Bool
    let customerId: String?
    
    init(data: LukaPayment) {
        self.method = CreditCardMethod()
        self.amount = data.amount
        self.currency = data.currency
        self.traceId = data.traceId
        self.charged = data.isSuccessful
        self.customerId = data.cardOwner?.id
    }
    
}
