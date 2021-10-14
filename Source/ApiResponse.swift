//
//  ApiResponse.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 22/9/21.
//

import Foundation

internal class ApiResponse<T> {
    
    let data: T?
    let error: Error?
    
    init(data: T) {
        self.data = data
        self.error = nil
    }
    
    init(error: Error) {
        self.error = error
        self.data = nil
    }
    
    func isSuccessful() -> Bool {
        return data != nil
    }
    
    func hasErrors() -> Bool {
        return error != nil
    }
    
}
