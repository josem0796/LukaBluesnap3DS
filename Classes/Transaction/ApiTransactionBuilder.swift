//
//  ApiTransactionBuilder.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 20/9/21.
//

import Foundation
import RxSwift

internal class ApiTransactionBuilder<Type, Output> {
    
    private let response: Observable<ApiResponse<Type>>
 
    var onSuccess: ((Type) -> Output)? = nil
    var onError: ((Error) -> Output)? = nil
    
    init(response: Observable<ApiResponse<Type>>) {
        self.response = response
    }
    
    /**
    Registers the transaction successful callback
    */
    func onSuccess(action: @escaping (Type) -> Output) -> ApiTransactionBuilder<Type, Output> {
        self.onSuccess = action
        return self
    }
    
    /**
     Registers the transaction failure callback
     */
    func onError(action: @escaping (Error) -> Output) -> ApiTransactionBuilder<Type, Output> {
        self.onError = action
        return self
    }
    
    /**
     Launches the transaction chain
     */
    func chain() -> Observable<Output> {
        return response.flatMap { (res: ApiResponse<Type>) -> Observable<Output> in
            if let next = self.onExecute(res: res) {
                return .just(next)
            } else {
                return .empty()
            }
        }
    }
    
    private func onExecute(res: ApiResponse<Type>) -> Output? {
        if res.isSuccessful() {
            return self.onSuccess?(res.data!)
        } else if res.hasErrors() {
            return self.onError?(res.error!)
        }
        return nil
    }
    
}
