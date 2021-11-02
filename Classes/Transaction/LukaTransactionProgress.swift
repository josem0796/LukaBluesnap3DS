//
//  LukaTransactionProgress.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

public struct LukaTransactionProgress {
    let acton: LukaPaymentStep
    let traceId: String?
    let handler: TransactionHandler
}
