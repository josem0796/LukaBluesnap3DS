//
//  LukaConfig.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 16/9/21.
//

import Foundation

internal struct LukaConfig: Codable {
    
    let bluesnapCredentials: BluesnapCredentials
    let color: String
    let lang: String
    let paymentMethods: [String]
    let currency: String // LukaCurrency
    let decimalsCount: Int
    let decimalsSeparator: String
    let thousandsSeparator: String
    let paypalClientId: String?
    let termsType: String?
    let termsUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case bluesnapCredentials = "BluesnapApiCredentials"
        case color = "Color"
        case lang = "Idioma"
        case paymentMethods = "MetodosPago"
        case currency = "Moneda"
        case decimalsCount = "NumeroDecimales"
        case decimalsSeparator = "SeparadorDecimal"
        case thousandsSeparator = "SeparadorMiles"
        case paypalClientId = "PaypalClientId"
        case termsType = "TipoTerminosCondiciones"
        case termsUrl = "TerminosCondicionesUrl"
    }
    
}
