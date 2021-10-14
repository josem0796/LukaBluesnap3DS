//
//  LukaPayer.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

struct LukaPayer: Codable {
    
    let lastName: String
    let name: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case lastName = "Apellido"
        case name = "Nombre"
        case email = "Email"
    }
    
}
