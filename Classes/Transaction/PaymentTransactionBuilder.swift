//
//  PaymentTransactionBuilder.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 20/9/21.
//

import Foundation
import RxSwift

internal class PaymentTransactionBuilder : TransactionBuilder<LukaPaymentRequest?, LukaTransactionProgress, LukaPaymentResult> {
    
    private let pause = BehaviorSubject(value: false)
    
    private let handler = TransactionHandler() // initialized without handlers
    private let disposeBag = DisposeBag()
    
    init(request: Observable<LukaPaymentRequest?>) {
        super.init(response: request)
        handler.updateHandlers(
            onPause: {
                self.pause.on(.next(true))
            },
            onResume: {
                self.pause.on(.next(false))
            }
        )
    }
    
    override func onExecute(input: LukaPaymentRequest?) {
        if let input = input {
            launchAction(action: .begin, request: input)
        } else {
            onError?(LukaErrors.transactionSetupFailedException)
        }
    }
    
    override func onBegin() {
        //Setup progress step
        onProgress?(LukaTransactionProgress(acton: .setup, traceId: nil, handler: self.handler))
    }
    
    func launchAction(action: LukaPaymentStep, request: LukaPaymentRequest?, payload: Any? = nil) {
        
        guard let req = request else {
            //Setup failed
            onError?(LukaErrors.transactionSetupFailedException)
            return
        }
        
        pause
            .asObservable()
            .filter {
                //Checks if not paused. This only works for setup step
                !$0
            }
            .do(onNext: { isPaused in
                //Calls the onProgress procedure
                self.onProgress?(LukaTransactionProgress(acton: action, traceId: req.session.id, handler: self.handler))
            })
            .filter {
                //Checks if not paused.
                !$0
            }
            .flatMap { isPaused in
                //Builds the launch callback
                req.bridge.launch(step: action, request: req, payload: payload)
            }
            .take(1)
            .do { response in
                //Handles the action result
                switch response.action {
                case LukaPaymentStep.finishSuccess:
                    //Finishes with success result
                    self.onSuccess?(response.payload as! LukaPaymentResult)
                case LukaPaymentStep.finishError:
                    //Finishes with error result
                    self.onError?((response.payload as! LukaErrors))
                default:
                    //Next step
                    self.launchAction(action: response.action, request: req, payload: response.payload)
                }
            }
            .subscribe()
            .disposed(by: disposeBag)

    }
    
}
