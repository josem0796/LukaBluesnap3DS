//
//  LukaProtocol.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 15/9/21.
//

import Foundation
import RxSwift

/**
 Communicates Luka with third party gateways
 */
internal protocol LukaBridge {
    
    /// Initializes Gateway
    func setup(api: LukaApi, config: LukaConfig, session: LukaSession) -> Observable<Bool>
    
    /// Launches a gateway action
    func launch(step: LukaPaymentStep, request: LukaPaymentRequest, payload: Any?) -> Observable<LukaBridgeResponse>
    
}
