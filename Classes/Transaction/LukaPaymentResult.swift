//
//  LukaPaymentResult.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

public struct LukaPaymentResult {
    
    public let method: CreditCardMethod
    public let amount: Double
    public let currency: LukaCurrency
    public let traceId: String
    public let charged: Bool
    public let customerId: String?
    
    init(data: LukaPayment) {
        self.method = CreditCardMethod()
        self.amount = data.amount
        self.currency = data.currency
        self.traceId = data.traceId
        self.charged = data.isSuccessful
        self.customerId = data.cardOwner?.id
    }
    
}
