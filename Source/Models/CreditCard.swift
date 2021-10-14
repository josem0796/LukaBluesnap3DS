//
//  CreditCard.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

struct CreditCard: Codable {
    
    let bin: String?
    let category: String?
    let city: String?
    let description: String?
    let address: Address?
    let zipCode: String?
    let thisVault: Bool?
    let state: String?
    let expiresAt: String?
    let id: UInt64
    let statusId: Int?
    let _currency: String?
    let countryCode: String?
    let subType: String?
    let type: String
    let last4: String
    
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
    
    var currency: LukaCurrency {
        return LukaCurrency.from(iso: _currency)
    }
    
}
