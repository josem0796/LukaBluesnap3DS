//
//  Types.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 20/9/21.
//

import Foundation

internal typealias Pair<A, B> = (first: A, second: B)
internal typealias TransactionHolder<A, B, C> = [String: TransactionBuilder<A, B, C>?]
