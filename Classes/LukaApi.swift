//
//  LukaApi.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 15/9/21.
//

import Foundation
import RxSwift
import Alamofire

public class LukaApi {
    
    private let credentials = LukaAuthCredentials()
    internal var currentSession: LukaSession? = nil
    internal var navController: UINavigationController!
    
    // used to store temporal transactions
    private var transactionHolder: TransactionHolder<ApiResponse<[LukaPayment]>, Any?, LukaPaymentResult> = [:]
    private var cardsTransactionHolder: TransactionHolder<ApiResponse<[CreditCard]>, Any, [CreditCard]> = [:]
    private var cardsDeleteTransactionHolder: TransactionHolder<ApiResponse<Void>, Any, Void> = [:]
    
    private let db = DisposeBag()
    
    private let isDebug: Bool
    
    init(forDebug: Bool) {
        self.isDebug = forDebug
    }
    
    public func setup(controller: UINavigationController) {
        navController = controller
    }
    
    private func session() -> Observable<LukaSession> {
        
        let params = [
            "Username": credentials.userName,
            "Password": credentials.password
        ]
        
        return Observable<LukaSession>.create { observer in
            
            let request = AF
                .request(
                    "\(self.apiUrl())servicio/login",
                    method: .post,
                    parameters: params,
                    encoder: JSONParameterEncoder.default,
                    headers: HTTPHeaders(LukaApiConfig.getDefaultHeaders())
                )
                .response { res in
                    if let headers = res.response?.allHeaderFields {
                        if let id = headers["id"] as? String, let token = headers["token"] as? String {
                            observer.on(.next(LukaSession(id: id, token: token, retrievedAt: Date())))
                            observer.on(.completed)
                        }
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
            
        }
       
        
    }
    
    private func config() -> Observable<(LukaConfig, LukaSession)> {
        
        return session()
            .flatMap { session -> Observable<(LukaConfig, LukaSession)> in
                let obs: Observable<(LukaConfig, LukaSession)> =  Observable<LukaConfig>
                    .create { observer in
                    
                        var headers = LukaApiConfig.getDefaultHeaders()
                        headers["Authorization"] = session.bearerToken
                        
                        let request = AF
                            .request(
                                "\(self.apiUrl())servicio/config",
                                method: .get,
                                headers: HTTPHeaders(headers)
                            )
                            .response { res in
                                switch res.result {
                                case .failure(let error):
                                    observer.on(.error(LukaErrors.transactionSetupFailedException))
                                    observer.on(.completed)
                                    break
                                case .success(let data):
                                    guard let obj = self.deserialize(LukaConfig.self, data: data!) else { return }
                                    observer.on(.next(obj))
                                    observer.on(.completed)
                                    break
                                default: break
                                }
                            }
                        
                        return Disposables.create {
                            request.cancel()
                        }
                    
                    }
                    .map { lukaConfig in
                        return (lukaConfig, session)
                    }
                return obs.flatMap { (sessionConfig: (LukaConfig, LukaSession)) -> Observable<(LukaConfig, LukaSession)> in
                    if !sessionConfig.1.isExpired {
                        return .just(sessionConfig)
                    } else {
                        return .empty()
                    }
                }
            }
            
    }
    
    internal func authenticate(credentials: LukaAuthCredentials) {
        self.credentials.userName = credentials.userName
        self.credentials.password = credentials.password
    }
    
    internal func bluesnapAuth(session: LukaSession) -> Observable<BluesnapAuth> {
        
        return Observable<BluesnapAuth>.create { observer in
        
            var headers = LukaApiConfig.getDefaultHeaders()
            headers["Authorization"] = session.bearerToken
            
            let request = AF
                .request(
                    "\(self.apiUrl())transaccion/token",
                    method: .get,
                    headers: HTTPHeaders(headers)
                )
                .response { res in
                    if let headers = res.response?.allHeaderFields {
                        if let bstoken = headers["bstoken"] as? String {
                            return observer.on(.next(BluesnapAuth(userId: session.id, token: bstoken)))
                        }
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
            
        }
        
    }
    
    internal func chargeTransaction(session: LukaSession, transaction: LukaTransaction) -> ApiTransactionBuilder<LukaPayment, LukaBridgeResponse> {

        let obs = Observable<ApiResponse<LukaPayment>>.create { observer in
            
            var headers = LukaApiConfig.getDefaultHeaders()
            headers["Authorization"] = session.bearerToken

            let request = AF
                .request(
                    "\(self.apiUrl())transaccion",
                    method: .post,
                    parameters: transaction,
                    encoder: JSONParameterEncoder.default,
                    headers: HTTPHeaders(headers)
                )
                .response { res in
                    switch res.result {
                    case .failure(let error):
                        observer.on(.next(ApiResponse<LukaPayment>(error: error)))
                        observer.on(.completed)
                        break
                    case .success(let data):
                        guard let obj = self.deserialize(LukaPayment.self, data: data!) else {
                            guard let errorObj = self.deserialize(ApiError.self, data: data!) else {
                                observer.on(.next(ApiResponse<LukaPayment>(error: LukaErrors.unknownError)))
                                observer.on(.completed)
                                return
                            }
                            observer.on(.next(ApiResponse<LukaPayment>(error: LukaErrors.errorProcessingTransaction(apiError: errorObj))))
                            observer.on(.completed)
                            return
                        }
                        observer.on(.next(ApiResponse<LukaPayment>(data: obj)))
                        observer.on(.completed)
                        break
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
            
        }
        
        return ApiTransactionBuilder<LukaPayment, LukaBridgeResponse>(response: obs)
        
    }
    
    func clear() {
        // todo
    }
    
    /**
     Creates a new payment request
     */
    public func createPaymentRequest(params: LukaPaymentParams) -> TransactionBuilder<LukaPaymentRequest?, LukaTransactionProgress, LukaPaymentResult> {
        
        let requestData = config()
            .asObservable()
            .flatMap { [unowned self] sessionConfig -> Observable<Pair<LukaPaymentRequest, Bool>> in
                
                let config = sessionConfig.0
                let session = sessionConfig.1
                
                var action: LukaPaymentAction
                
                switch params {
                case is LukaCardVaultParams:
                    action = .cardStorage
                    break
                case is LukaCardPaymentParams:
                    action = .cardSelectionCharge
                    break
                default:
                    action = .anonymousCharge
                    break
                }
                
                return LukaPaymentRequest(params: params, api: self, config: config, session: session, action: action).callBack()
                
            }
            .map { (requestResult) -> LukaPaymentRequest? in
                if requestResult.second {
                    return requestResult.first
                } else {
                    return nil
                }
            }
        
        return PaymentTransactionBuilder(request: requestData)
        
    }
    
    public func checkTransaction(traceId: String) -> TransactionBuilder<ApiResponse<[LukaPayment]>, Any?, LukaPaymentResult> {
        
        let obs = Observable<ApiResponse<[LukaPayment]>>.create { observer in
        
            var headers = LukaApiConfig.getDefaultHeaders()
            headers["Authorization"] = self.credentials.basic()
        
            let request = AF
                .request(
                    "\(self.apiUrl())transaccion",
                    method: .get,
                    parameters: ["trazaId": traceId],
                    headers: HTTPHeaders(headers)
                )
                .response { res in
                    switch res.result {
                    case .failure(let error):
                        observer.on(.next(ApiResponse<[LukaPayment]>(error: error)))
                        observer.on(.completed)
                        break
                    case .success(let data):
                        guard let obj = self.deserialize([LukaPayment].self, data: data!) else {
                            guard let errorObj = self.deserialize(ApiError.self, data: data!) else {
                                observer.on(.next(ApiResponse<[LukaPayment]>(error: LukaErrors.unknownError)))
                                observer.on(.completed)
                                return
                            }
                            observer.on(.next(ApiResponse<[LukaPayment]>(error: LukaErrors.errorProcessingTransaction(apiError: errorObj))))
                            observer.on(.completed)
                            return
                        }
                        observer.on(.next(ApiResponse<[LukaPayment]>(data: obj)))
                        observer.on(.completed)
                        break
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
            
        }
        
        let transactionBuilder: TransactionBuilder<ApiResponse<[LukaPayment]>, Any?, LukaPaymentResult> = {
            
            class CustomTransactionBuilder : TransactionBuilder<ApiResponse<[LukaPayment]>, Any?, LukaPaymentResult> {
                
                public var traceId: String = ""
                public var lukaApi: LukaApi? = nil
                
                override func onExecute(input: ApiResponse<[LukaPayment]>) {
                    super.onExecute(input: input)
                    if input.isSuccessful() {
                        guard let result = input.data else { return }
                        if result.isEmpty {
                            onError?(LukaErrors.paymentNotFoundException)
                        } else {
                            onSuccess?(LukaPaymentResult(data: result[0]))
                        }
                    } else if input.hasErrors() {
                        onError?(input.error as! LukaErrors)
                    } else {
                        onError?(LukaErrors.unknownError)
                    }
                    let possibleIndex = lukaApi?.transactionHolder.index(forKey: traceId)
                    if possibleIndex != nil {
                        lukaApi?.transactionHolder.remove(at: possibleIndex!)
                    }
                    
                }
            }
            
            let ctb = CustomTransactionBuilder(response: obs, disposeBag: self.db)
            ctb.traceId = traceId
            ctb.lukaApi = self
            
            return ctb
            
        }()
        
        transactionHolder[traceId] = transactionBuilder
        
        return transactionBuilder

    }
    
    /**
     Adds new card to Vault. if LukaCustomerId is nil, the customer will be created. Otherwise, the card will be added to the cystomer's vault
     */
    public func addCustomerCardRequest(email: String, lukaCustomerId: String? = nil) -> TransactionBuilder<LukaPaymentRequest?, LukaTransactionProgress, LukaPaymentResult> {
        let params = LukaCardVaultParams(customerId: lukaCustomerId, email: email)
        return createPaymentRequest(params: params)
    }
    
    public func indexCustomerCardsRequest(lukaCustomerId: String) -> TransactionBuilder<ApiResponse<[CreditCard]>, Any, [CreditCard]> {
        
        let traceId = "customerCardsRequest-\(lukaCustomerId)"
        
        let requestData = config()
            .asObservable()
            .flatMap { [unowned self] sessionConfig -> Observable<ApiResponse<[CreditCard]>> in
                
                let obs: Observable<ApiResponse<[CreditCard]>> = Observable<ApiResponse<[CreditCard]>>
                    .create { observer in
                    
                        let lukaSession = sessionConfig.1
                        
                        var headers = LukaApiConfig.getDefaultHeaders()
                        headers["Authorization"] = lukaSession.bearerToken
                        
                        let request = AF
                            .request(
                                "\(self.apiUrl())tarjetacredito/servicio/\(lukaCustomerId)",
                                method: .get,
                                headers: HTTPHeaders(headers)
                            )
                            .response { res in
                                
                                switch res.result {
                                case .failure(let error):
                                    observer.on(.next(ApiResponse<[CreditCard]>(error: error)))
                                    observer.on(.completed)
                                    break
                                case .success(let data):
                                    guard let obj = self.deserialize([CreditCard].self, data: data!) else {
                                        guard let errorObj = self.deserialize(ApiError.self, data: data!) else {
                                            observer.on(.next(ApiResponse<[CreditCard]>(error: LukaErrors.unknownError)))
                                            observer.on(.completed)
                                            return
                                        }
                                        observer.on(.next(ApiResponse<[CreditCard]>(error: LukaErrors.errorProcessingTransaction(apiError: errorObj))))
                                        observer.on(.completed)
                                        return
                                    }
                                    observer.on(.next(ApiResponse<[CreditCard]>(data: obj)))
                                    observer.on(.completed)
                                    break
                                }
                            }
                        
                        return Disposables.create {
                            request.cancel()
                        }
                    
                    }
                
                return obs
                
            }
        
        let transactionBuilder: TransactionBuilder<ApiResponse<[CreditCard]>, Any, [CreditCard]> = {
        
            class CustomTransactionBuilder : TransactionBuilder<ApiResponse<[CreditCard]>, Any, [CreditCard]> {
                
                public var traceId: String = ""
                public var lukaApi: LukaApi? = nil
                
                override func onExecute(input: ApiResponse<[CreditCard]>) {
                    
                    super.onExecute(input: input)
                    
                    if input.isSuccessful() {
                        onSuccess?(input.data ?? [])
                    } else if input.hasErrors() {
                        onError?(input.error as! LukaErrors)
                    } else {
                        onError?(LukaErrors.unknownError)
                    }
                    let possibleIndex = lukaApi?.cardsTransactionHolder.index(forKey: traceId)
                    if possibleIndex != nil {
                        lukaApi?.cardsTransactionHolder.remove(at: possibleIndex!)
                    }
            
                }
                
            }
            
            let ctb = CustomTransactionBuilder(response: requestData, disposeBag: self.db)
            ctb.traceId = traceId
            ctb.lukaApi = self
            return ctb
            
        }()
        
        cardsTransactionHolder[traceId] = transactionBuilder
        
        return transactionBuilder
        
    }
    
    public func deleteCustomerCard(cardId: UInt64, lukaCustomerId: String) -> TransactionBuilder<ApiResponse<Void>, Any, Void> {
        
        let traceId = "deleteCustomerCardsRequest-\(lukaCustomerId)"
        
        let requestData = session()
            .asObservable()
            .flatMap { [unowned self] lukaSession -> Observable<ApiResponse<Void>> in
                
                let obs: Observable<ApiResponse<Void>> = Observable<ApiResponse<Void>>.create { observer in
                    
                    var headers = LukaApiConfig.getDefaultHeaders()
                    headers["Authorization"] = lukaSession.bearerToken
                    
                    let request = AF
                        .request(
                            "\(self.apiUrl())tarjetacredito/\(cardId)/user/\(lukaCustomerId)",
                            method: .delete,
                            headers: HTTPHeaders(headers)
                        )
                        .response { res in
                            
                            switch res.result {
                            case .failure(let error):
                                observer.on(.next(ApiResponse<Void>(error: error)))
                                observer.on(.completed)
                                break
                            case .success(let data):
                                if let resData = data {
                                    if let errorObj = self.deserialize(ApiError.self, data: resData) {
                                        observer.on(.next(ApiResponse<Void>(error: LukaErrors.errorProcessingTransaction(apiError: errorObj))))
                                        observer.on(.completed)
                                    } else {
                                        observer.on(.next(ApiResponse<Void>(error: LukaErrors.unknownError)))
                                        observer.on(.completed)
                                    }
                                } else {
                                    observer.on(.next(ApiResponse<Void>(data: Void())))
                                    observer.on(.completed)
                                }
                                break
                            }
                        }
                    
                    return Disposables.create {
                        request.cancel()
                    }
                    
                }
                
                return obs
                
            }
        
        let transactionBuilder: TransactionBuilder<ApiResponse<Void>, Any, Void> = {
        
            class CustomTransactionBuilder : TransactionBuilder<ApiResponse<Void>, Any, Void> {
                
                public var traceId: String = ""
                public var lukaApi: LukaApi? = nil
                
                override func onExecute(input: ApiResponse<Void>) {
                    
                    super.onExecute(input: input)
                    
                    if input.isSuccessful() {
                        onSuccess?(input.data ?? Void())
                    } else if input.hasErrors() {
                        onError?(input.error as! LukaErrors)
                    } else {
                        onError?(LukaErrors.unknownError)
                    }
                    let possibleIndex = lukaApi?.cardsDeleteTransactionHolder.index(forKey: traceId)
                    if possibleIndex != nil {
                        lukaApi?.cardsDeleteTransactionHolder.remove(at: possibleIndex!)
                    }
            
                }
                
            }
            
            let ctb = CustomTransactionBuilder(response: requestData, disposeBag: self.db)
            ctb.traceId = traceId
            ctb.lukaApi = self
            return ctb
            
        }()
        
        cardsDeleteTransactionHolder[traceId] = transactionBuilder
        
        return transactionBuilder
        
    }
    
}

extension LukaApi {
    
    private func deserialize<T: Decodable>(_ type: T.Type, data: Data) -> T? {
        do {
            let item = try JSONDecoder().decode(type, from: data)
            return item
        } catch {
            print("deserialize ERROR Deserializing \(error)")
            let stringRep = String(data: data, encoding: .utf8)
            print("String representation: \(stringRep)")
            return nil
        }
    }
    
    private func serialize<T: Encodable>(obj: T) -> Data? {
        do {
            let encoded = try JSONEncoder().encode(obj)
            return encoded
        } catch {
            print("serialize ERROR Serializing")
            return nil
        }
    }
    
    private func apiUrl() -> String {
        if isDebug {
            return LukaApiConfig.getTestApiUrl()
        } else {
            return LukaApiConfig.getProductionApiUrl()
        }
    }
    
}
