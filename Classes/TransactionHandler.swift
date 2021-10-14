//
//  TransactionHandler.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 17/9/21.
//

import Foundation

class TransactionHandler {
    
    private var onPause: (() -> Void)
    private var onResume: (() -> Void)
    
    init(onPause: @escaping () -> Void, onResume: @escaping () -> Void) {
        self.onPause = onPause
        self.onResume = onResume
    }
    
    init() {
        onPause = {}
        onResume = {}
    }
    
    func updateHandlers(onPause: @escaping (() -> Void), onResume: @escaping (() -> Void)) {
        self.onPause = onPause
        self.onResume = onResume
    }
    
}
