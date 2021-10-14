//
//  LukaTransaction.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 16/9/21.
//

import Foundation

internal struct LukaTransaction: Codable {
    
    let cardOwnerEmail: String?
    let channelId: Int //5 IOs channel
    let traceId: String
    let currency: String?
    let amount: Double?
    let ref: String?
    let creditCard: CreditCard?
    let creditCardOwner: CardOwner?
    let bluesnapToken: String?
    let cardValidation: Bool?
    let creditCardId: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case cardOwnerEmail = "EmailTarjetaHabiente"
        case channelId = "IdCanal"
        case traceId = "IdTraza"
        case currency = "Moneda"
        case amount = "Monto"
        case ref = "Referencia"
        case creditCard = "TarjetaCredito"
        case creditCardOwner = "TarjetaHabiente"
        case bluesnapToken = "TokenBluesnap"
        case cardValidation = "ValidacionTarjeta"
        case creditCardId = "IdTarjetaCredito"
    }
    
    internal static let androidChannel = 4
    internal static let iosChannel = 5
    
}
