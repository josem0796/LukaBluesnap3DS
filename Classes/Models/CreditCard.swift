//
//  CreditCard.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

public struct CreditCard: Codable {
    
    public let bin: String?
    public let category: String?
    public let city: String?
    public let description: String?
    public let address: Address?
    public let zipCode: String?
    public let thisVault: Bool?
    public let state: String?
    public let expiresAt: String?
    public let id: UInt64
    public let statusId: Int?
    let _currency: String?
    public let countryCode: String?
    public let subType: String?
    public let type: String
    public let last4: String
    
    enum CodingKeys: String, CodingKey {
        case bin = "Bin"
        case category = "CategoriaTarjeta"
        case city = "Ciudad"
        case description = "Descripcion"
        case address = "Direccion"
        case zipCode = "CodigoPostal"
        case thisVault = "EstaBoveda"
        case state = "Estado"
        case expiresAt = "FechaVencimiento"
        case id = "Id"
        case statusId = "IdStatus"
        case _currency = "Moneda"
        case countryCode = "Pais"
        case subType = "SubTipoTarjeta"
        case type = "TipoTarjeta"
        case last4 = "UltimosCuatroDigitos"
    }
    
    public var currency: LukaCurrency {
        return LukaCurrency.from(iso: _currency)
    }
    
}
