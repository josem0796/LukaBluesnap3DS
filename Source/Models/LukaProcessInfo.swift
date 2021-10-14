//
//  LukaProcessInfo.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

struct LukaProcessInfo: Codable {
    
    let status: String
    let cvvResponse: String
    
    enum CodingKeys: String, CodingKey {
        case status = "EstatusProcesamiento"
        case cvvResponse = "CodigoRespuestaCvv"
    }
    
}
