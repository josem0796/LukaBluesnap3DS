//
//  Address.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 11/10/21.
//

import Foundation

public struct Address: Codable {
    
    public let city: String?
    public let address: String?
    public let zipCode: String?
    public let state: String?
    public let countryId: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case city = "Ciudad"
        case address = "Direccion"
        case zipCode = "CodigoPostal"
        case state = "Estado"
        case countryId = "IdPais"
    }
    
}
