//
//  LukaPaymentStep.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 15/9/21.
//

import Foundation

/**
 Current payment step
 */
public enum LukaPaymentStep {
    
    /// Setup payment before start
    case setup
    
    /// The payment process is starting
    case begin
    
    /// The payment is being prepared
    case prepare
    
    /// The payment is being charged
    case charge
    
    /// The payment was completed successfully
    case finishSuccess
    
    /// The payment process was aborted due to an error
    case finishError
    
}
