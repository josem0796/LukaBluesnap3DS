//
//  CardOwner.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

struct CardOwner: Codable {
    
    let id: String?
    let lastName: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "LukapayId"
        case lastName = "Apellido"
        case name = "Nombre"
    }
    
}
