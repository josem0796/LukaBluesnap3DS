//
//  LukaApiConfig.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 24/9/21.
//

import Foundation

internal class LukaApiConfig {
    
    private static let apiUrl = "https://lukaapi.payco.net.ve/api/v1/"
    private static let testApiUrl = "https://bspaycoapi-qa.payco.net.ve/api/v1/"
    
    static func getDefaultHeaders() -> [String: String] {
        return [
            "ContentType": "application/json"
        ]
    }
    
    static func getTestApiUrl() -> String {
        return testApiUrl
    }
    
    static func getProductionApiUrl() -> String {
        return apiUrl
    }
    
}
