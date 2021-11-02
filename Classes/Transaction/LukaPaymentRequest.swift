//
//  LukaPaymentRequest.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation
import RxSwift

public class LukaPaymentRequest {
    
    let params: LukaPaymentParams
    let api: LukaApi
    let config: LukaConfig
    let session: LukaSession
    let action: LukaPaymentAction
    
    let method: LukaMethod
    let gateway: LukaGateway
    let bridge: LukaBridge
    let setupResult: Observable<Bool>
    
    init(params: LukaPaymentParams, api: LukaApi, config: LukaConfig, session: LukaSession, action: LukaPaymentAction) {
        
        self.params = params
        self.api = api
        self.config = config
        self.session = session
        
        self.method = params.method
        self.gateway = method.gateway()
        self.bridge = gateway.bridge()
        self.action = action
        
        self.setupResult = bridge.setup(api: api, config: config, session: session)
        
    }
    
    func callBack() -> Observable<Pair<LukaPaymentRequest, Bool>> {
        
        let myObs = Observable.just(self)
        let setupObs = setupResult
        
        return Observable
            .combineLatest(myObs, setupObs)
            .map { (paymentRequest, result) in
                return Pair(paymentRequest, result)
            }
        
    }
    
    func dispatch() -> Observable<LukaBridgeResponse> {
        return Observable
            .empty()
            .do(
                onNext: { _ in
                    print("dispatching empty observable dispatch()")
                }
            )
    }
    
}
