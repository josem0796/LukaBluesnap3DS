//
//  Bluesnap.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 15/9/21.
//

import Foundation
import BluesnapSDK
import RxSwift
import RxRelay

internal class BluesnapBridge: LukaBridge {
    
    private var api: LukaApi!
    private var session: LukaSession!
    private let _setupResult = BehavoirRelay<Bool?>(defaultValue: nil)
    private var setupResult: Observable<Bool>!
    private let disposeBag = DisposeBag()
    private var lastUsedToken = ""
    private var tokenRefresherObs: Observable<Int>!
    private let intervalTimeInSeconds = 45 * 60 // 45 minutes
    
    func setup(api: LukaApi, config: LukaConfig, session: LukaSession) -> Observable<Bool> {
        
        self.api = api
        self.session = session
        self.setupResult = _setupResult
            .asObservable()
            .filter { $0 != nil }
            .map { $0! }
        
        //Object to renew expired tokens
        Observable<Int>
            .interval(RxTimeInterval.seconds(intervalTimeInSeconds), scheduler: MainScheduler.instance)
            .do { _ in
                self.retrieveAndSetNewBSToken(completion: nil)
            }
            .subscribe()
            .disposed(by: self.disposeBag)
        
        // Initialize bluesnap sdk
        _setupResult
            .asObservable()
            .filter { $0 == nil}
            .flatMap { _ in
                return self.retrieveNewBsToken()
            }
            .subscribe(onNext: { newToken in
                self.initBluesnap(bsToken: newToken)
            })
            .disposed(by: disposeBag)
        
        return setupResult
        
    }
    
    func launch(step: LukaPaymentStep, request: LukaPaymentRequest, payload: Any?) -> Observable<LukaBridgeResponse> {
        switch request.action {
        case .anonymousCharge:
            switch step {
            case .begin:
                return anonymousPaymentBegin(request: request)
            case .prepare:
                return paymentPrepare(request: request, payload: payload as! BSBaseSdkResult)
            case .charge:
                return anonymousPaymentCharge(request: request, transaction: payload as! LukaTransaction)
            default:
                return .error(LukaErrors.unknownActionForBridge(action: "\(request.action)::\(step)", bridge: "BluesnapBridge"))
            }
        case .cardStorage:
            switch step {
            case .begin:
                return anonymousPaymentBegin(request: request)
            case .prepare:
                return paymentPrepare(request: request, payload: payload as! BSBaseSdkResult)
            case .charge:
                return anonymousPaymentCharge(request: request, transaction: payload as! LukaTransaction)
            default:
                return .error(LukaErrors.unknownActionForBridge(action: "\(request.action)::\(step)", bridge: "BluesnapBridge"))
            }
        case .cardSelectionCharge:
            switch step {
            case .begin:
                return cardPaymentBegin(request: request)
            case .prepare:
                return paymentPrepare(request: request, payload: payload as! BSBaseSdkResult)
            case .charge:
                return anonymousPaymentCharge(request: request, transaction: payload as! LukaTransaction)
            default:
                return .error(LukaErrors.unknownActionForBridge(action: "\(request.action)::\(step)", bridge: "BluesnapBridge"))
            }
        default:
            return .error(LukaErrors.unknownActionForBridge(action: "\(request.action)::\(step)", bridge: "BluesnapBridge"))
        }
    }
    
}

extension BluesnapBridge {
    
    private func initBluesnap(bsToken: String) {

        do {
            try BlueSnapSDK.initBluesnap(
                bsToken: BSToken(tokenStr: bsToken),
                generateTokenFunc: self.retrieveAndSetNewBSToken,
                initKount: true,
                fraudSessionId: nil,
                applePayMerchantIdentifier: "merchant.com.example.bluesnap",
                merchantStoreCurrency: "USD",
                completion: { error in
                    if let error = error {
                        self._setupResult.accept(false)
                    } else {
                        self._setupResult.accept(true)
                        self.lastUsedToken = bsToken
                        print("TOKEN: \(self.lastUsedToken)")
                    }
                }
            )
        } catch {
            self._setupResult.accept(false)
        }

    }
    
    /**
        Called by the BlueSnapSDK when token expired error is recognized.
        Here we generate and set a new token, so that when the action re-tries, it will succeed.
        In your real app you should get the token from your app server, then call
        BlueSnapSDK.setBsToken to set it.
        */
    private func retrieveAndSetNewBSToken(completion: ((_ token: BSToken?, _ error: BSErrors?) -> Void)?) {
        retrieveNewBsToken()
            .subscribe(onNext: { newToken in
                self.lastUsedToken = newToken
                do {
                    let newBsToken = try BSToken(tokenStr: newToken)
                    try BlueSnapSDK.setBsToken(bsToken: BSToken(tokenStr: newToken))
                    completion?(newBsToken, nil)
                } catch {
                    completion?(nil, BSErrors.unknown)
                    NSLog("Unexpected error: \(error).")
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func retrieveNewBsToken() -> Observable<String> {
        return self.api
            .bluesnapAuth(session: self.session)
            .take(1)
            .map { $0.token }
    }
    
}

extension BluesnapBridge {
    
    private func anonymousPaymentBegin(request: LukaPaymentRequest) -> Observable<LukaBridgeResponse> {
        
        return setupResult
            .filter { $0 }
            .flatMap { isInitialized -> Observable<LukaBridgeResponse> in
                
                let resultObs = PublishRelay<LukaBridgeResponse>()
                
                let params = request.params
                
                let priceDetails = BSPriceDetails(amount: params.amount, taxAmount: 0.0, currency: params.currency.iso)
                
                let billingDetails = BSBillingAddressDetails(email: params.email, name: "", address: nil, city: nil, zip: nil, country: nil, state: nil)
                
                let sdkRequest = BSSdkRequest(
                    withEmail: true,
                    withShipping: false,
                    fullBilling: true,
                    priceDetails: priceDetails,
                    billingDetails: billingDetails,
                    shippingDetails: nil,
                    purchaseFunc: { result in
                        resultObs.accept(LukaBridgeResponse(action: .prepare, payload: result))
                    }
                ) { a, b, bsPriceDetails in
                    
                }
                
                sdkRequest.hideStoreCardSwitch = true
                sdkRequest.activate3DS = params.enable3DSecureAuthentication
                sdkRequest.allowCurrencyChange = false
                sdkRequest.hideStoreCardSwitch = true
                
                if let navController = self.api.navController {
                    do {
                        try BlueSnapSDK.showCheckoutScreen(
                            inNavigationController: navController,
                            animated: true,
                            sdkRequest: sdkRequest
                        )
                    } catch {
                        print("error charging \(error)")
                        return Observable.error(LukaErrors.unknownError)
                    }
                } else {
                    return Observable.error(LukaErrors.missingNavigationController)
                }
                
                return resultObs.asObservable()
                
            }
        
    }
    
    private func paymentPrepare(request: LukaPaymentRequest, payload: BSBaseSdkResult) -> Observable<LukaBridgeResponse> {
        
        var customerId: String?
        var storeCard: Bool
        
        switch request.params {
        case is LukaCardVaultParams:
            customerId = (request.params as? LukaCardVaultParams)?.lukaCustomerId
            storeCard = true
            break
        default:
            customerId = nil
            storeCard = false
            break
        }
        
        
        let resultObs = BehavoirRelay<LukaBridgeResponse?>(defaultValue: nil)
        
        // for credit cards
        if let purchaseDetails =  payload as? BSCcSdkResult {
            
            let billingDetails = purchaseDetails.billingDetails
            
            let creditCard = CreditCard(
                bin: nil,
                category: "CONSUMER",
                city: nil,
                description: nil,
                address: nil,
                zipCode: nil,
                thisVault: nil,
                state: nil,
                expiresAt: purchaseDetails.creditCard.getExpiration(),
                id: 0,
                statusId: nil,
                _currency: nil,
                countryCode: billingDetails?.country,
                subType: "CREDIT",
                type: purchaseDetails.creditCard.ccType ?? "",
                last4: purchaseDetails.creditCard.last4Digits ?? ""
            )
            
            let splitName = billingDetails?.getSplitName()
            
            let cardOwner = CardOwner(
                id: customerId ?? "",
                lastName: splitName?.firstName ?? "",
                name: splitName?.lastName ?? ""
            )
            
            let transaction = LukaTransaction(
                cardOwnerEmail: billingDetails?.email,
                channelId: LukaTransaction.iosChannel,
                traceId: request.session.id,
                currency: payload.getCurrency(),
                amount: payload.getAmount(),
                ref: "",
                creditCard: creditCard,
                creditCardOwner: cardOwner,
                bluesnapToken: self.lastUsedToken, // check token
                cardValidation: storeCard,
                creditCardId: nil
            )
            
            resultObs.accept(LukaBridgeResponse(action: .charge, payload: transaction))
            
        }
        
        return resultObs
            .asObservable()
            .filter { $0 != nil }
            .map { $0! }
        
    }
    
    private func anonymousPaymentCharge(request: LukaPaymentRequest, transaction: LukaTransaction) -> Observable<LukaBridgeResponse> {
        return api
            .chargeTransaction(session: request.session, transaction: transaction)
            .onSuccess { lukaPayment in
                if lukaPayment.isSuccessful {
                    return LukaBridgeResponse(action: .finishSuccess, payload: LukaPaymentResult(data: lukaPayment))
                } else {
                    return LukaBridgeResponse(action: .finishError, payload: LukaErrors.errorProcessingTransaction(apiError: ApiError(message: lukaPayment.description, code: 200)))
                }
            }
            .onError { error in
                return LukaBridgeResponse(action: .finishError, payload: error)
            }
            .chain()
    }
    
    private func cardPaymentBegin(request: LukaPaymentRequest) -> Observable<LukaBridgeResponse> {
        
        let params = request.params as! LukaCardPaymentParams
        let card = params.card
        
        let cardOwner = CardOwner(id: params.customerId, lastName: "", name: "")
        
        let transaction = LukaTransaction(
            cardOwnerEmail: request.params.email ?? params.email,
            channelId: LukaTransaction.iosChannel,
            traceId: request.session.id,
            currency: params.currency.iso,
            amount: params.amount,
            ref: nil,
            creditCard: card,
            creditCardOwner: cardOwner,
            bluesnapToken: nil,
            cardValidation: nil,
            creditCardId: card.id
        )
        
        return Observable.just(LukaBridgeResponse(action: .charge, payload: transaction))
        
    }
    
}
