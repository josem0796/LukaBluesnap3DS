//
//  LukaPayment.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

public struct LukaPayment: Codable {
    
    let channel: String
    let description: String
    let isSuccessful: Bool
    let processInfo: LukaProcessInfo?
    let creditCard: CreditCard?
    let userInfo: LukaPayer
    let paymentMethod: String
    let _currency: String
    let amount: Double
    let originalAmount: Double?
    let usdAmount: Double
    let cardOwner: CardOwner?
    let transactionId: UInt64
    let transactionMerchantId: Int
    let traceId: String
    
    enum CodingKeys: String, CodingKey {
        case channel = "Canal"
        case description = "Descripcion"
        case isSuccessful = "Exitoso"
        case processInfo = "InfoProceso"
        case creditCard = "InfoTarjeta"
        case userInfo = "InfoUsuarioPagador"
        case paymentMethod = "MedioDePago"
        case _currency = "Moneda"
        case amount = "Monto"
        case originalAmount = "MontoOriginal"
        case usdAmount = "MontoUsd"
        case cardOwner = "TarjetaHabiente"
        case transactionId = "TransaccionId"
        case transactionMerchantId = "TransaccionMerchantId"
        case traceId = "TrazaId"
    }
    
    var currency: LukaCurrency {
        return LukaCurrency.from(iso: _currency)
    }
    
}
