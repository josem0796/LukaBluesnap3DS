//
//  Address.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 11/10/21.
//

import Foundation

struct Address: Codable {
    
    let city: String?
    let address: String?
    let zipCode: String?
    let state: String?
    let countryId: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case city = "Ciudad"
        case address = "Direccion"
        case zipCode = "CodigoPostal"
        case state = "Estado"
        case countryId = "IdPais"
    }
    
}
