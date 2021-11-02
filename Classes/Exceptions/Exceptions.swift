//
//  Exceptions.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 20/9/21.
//

import Foundation

public enum LukaErrors: Error {
    case transactionSetupFailedException
    case unknownActionForBridge(action: String, bridge: String)
    case errorProcessingTransaction(apiError: ApiError?)
    case missingNavigationController
    case paymentNotFoundException
    case unknownError
    case apiErrorResponse
}

public struct ApiError : Codable {
    
    let message: String
    let code: Int
    
    enum CodingKeys: String, CodingKey {
        case message = "Mensaje"
        case code = "Codigo"
    }
    
}

extension LukaErrors {
    
    public var message: String {
        switch self {
        case .transactionSetupFailedException:
            return "SDK setup failed"
        case .unknownActionForBridge(let action, let bridge):
            return "Unknown action \(action) for bridge \(bridge)"
        case .errorProcessingTransaction(let error):
            return "Error procesando la transacción \(String(describing: error))"
        case .unknownError:
            return "Error desconocido"
        case .missingNavigationController:
            return "No se registró ningún navigation controller para mostrar el formulario de pago"
        case .paymentNotFoundException:
            return "No se encontró un pago asociado a ese traceId"
        case .apiErrorResponse:
            return "Error de api"
        default:
            return "Unknown error"
        }
    }
    
}
