//
//  TransactionBuilder.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation
import RxSwift

class TransactionBuilder<Input, Progress, Output> {
    
    var onSuccess: ((Output) -> Void)? = nil
    var onError: ((LukaErrors) -> Void)? = nil
    var onProgress: ((Progress) -> Void)? = nil
    
    private let response: Observable<Input>
    
    private var disposeBag = DisposeBag()
    
    init(response: Observable<Input>) {
        self.response = response
    }
    
    init(response: Observable<Input>, disposeBag: DisposeBag) {
        self.response = response
        self.disposeBag = disposeBag
    }
    
    /**
     Registers the transaction successful callback
     */
    func registryOnSuccess(action: @escaping (Output) -> Void) -> TransactionBuilder<Input, Progress, Output> {
        onSuccess = action
        return self
    }
    
    /**
     Registers the transaction failure callback
     */
    func registryOnError(action: @escaping (LukaErrors) -> Void) -> TransactionBuilder<Input, Progress, Output> {
        onError = action
        return self
    }
    
    /**
     Registers the transaction progress callback
     */
    func registryOnProgress(action: @escaping (Progress) -> Void) -> TransactionBuilder<Input, Progress, Output> {
        onProgress = action
        return self
    }
    
    func execute() {
        onBegin()
        response
            .take(1)
            .subscribe(onNext: { [weak self] input in
                guard let strong = self else {
                    return
                }
                strong.onExecute(input: input)
            }, onError: { error in
                print(error)
            })
            .disposed(by: disposeBag)
    }
  
    func onBegin() {
        
    }
    
    open func onExecute(input: Input) {
        print("onExecute")
    }
    
}
