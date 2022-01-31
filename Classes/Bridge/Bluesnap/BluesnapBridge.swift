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
                applePayMerchantIdentifier: nil,
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
                
                var mode: BSForm.Mode = .pay
                
                if request.params is LukaCardVaultParams {
                    mode = .storeCard
                }
                
                let sdkRequest = BSSdkRequest(
                    withEmail: false,
                    withShipping: false,
                    fullBilling: false,
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
                       
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            
                            let foundController = navController.viewControllers.first { (controller: UIViewController) in
                                let controllerClassName = String(describing: type(of: controller))
                                return controllerClassName == "BSPaymentViewController"
                            }
                            
                            if let bsPaymentViewController = foundController {
                                if let aView = bsPaymentViewController.view {
                                    let form = BSForm(rootView: aView)
                                    form.style(mode: mode)
                                }
                            }
                            
                        }
                        
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
    
    private class BSForm {
        
        static let fieldVerticalMargin = CGFloat(8.0)
        
        let root: UIView!
        
        init(rootView: UIView) {
            self.root = rootView
        }
        
        func getCardInputField() -> UIView? {
            return root.viewWithTag(1)
        }
        
        func getNameField() -> UIView? {
            return root.viewWithTag(2)
        }
        
        func getEmailField() -> UIView? {
            return root.viewWithTag(3)
        }
        
        func getZipField() -> UIView? {
            return root.viewWithTag(4)
        }
        
        func getAddressField() -> UIView? {
            return root.viewWithTag(5)
        }
        
        func getCityField() -> UIView? {
            return root.viewWithTag(6)
        }
        
        func getStateField() -> UIView? {
            // the state field hasn't tag to be selected
            return getCityField()?.superview?.subviews.last(where: { view in
                if let _ = view as? BluesnapSDK.BSBaseTextInput {
                    return true
                }
                return false
            })
        }
        
        func getPayButton() -> UIView? {
            return root.subviews.first { view in
                if let _ = view as? UIButton {
                    return true
                }
                return false
            }
        }
        
        func style(mode: Mode) {
            
            guard let zip = getZipField(), let name = getNameField() else  { return }
            
            // marginForRelation(first: getEmailField(), second: getNameField())
            marginForRelation(first: getZipField(), second: getEmailField())
            //marginForRelation(first: getAddressField(), second: getZipField())
            //marginForRelation(first: getCityField(), second: getAddressField())
            //marginForRelation(first: getStateField(), second: getCityField())
            
            if let input = getCardInputField() as? BSCcInputLine {
                
                let fields = input.subviews.filter { view in
                    if let _ = view as? UITextField {
                        return true
                    }
                    return false
                }
                
                fields.forEach { view in
                    if let viewField = view as? UITextField {
                        let placeHolderText = viewField.placeholder ?? ""
                        viewField.attributedPlaceholder = NSAttributedString(
                            string: placeHolderText,
                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
                        )
                    }
                    view.layer.borderWidth = 0.5
                    view.layer.cornerRadius = 3
                    view.layer.borderColor = UIColor.systemBlue.cgColor
                }
                
            }
            
            // payment button styling
            let payButton = getPayButton()
            
            payButton?.backgroundColor = colorFromHexString(hexString: "#196076")
            
            if case .storeCard = mode {
                (payButton as? UIButton)?.setTitle("Registrar Tarjeta", for: .normal)
            }
            
            root.layoutSubviews()
            root.layoutIfNeeded()
            
        }
        
        private func alterMargin(constraint: NSLayoutConstraint) {
            constraint.constant = BSForm.fieldVerticalMargin
        }
        
        func marginForRelation(first: UIView?, second: UIView?) {
            
            guard let firstField = first, let secondField = second else { return }
            
            let constraints = firstField.constraintsAffectingLayout(for: .vertical)
            
            constraints.forEach { constraint in
                if let constraintFirtsItem = constraint.firstItem as? UIView,
                   let constraintSecondItem = constraint.secondItem as? UIView {
                    if constraintFirtsItem.tag == firstField.tag && constraintSecondItem.tag == secondField.tag {
                        if constraintFirtsItem.tag == 4 && constraintSecondItem.tag == 3 { // email field
                            if let nameField = getNameField() {
                                constraint.constant = -nameField.bounds.height + BSForm.fieldVerticalMargin
                            }
                        } else {
                            alterMargin(constraint: constraint)
                        }
                        return
                    }
                }
            }
            
        }
        
        public func colorFromHexString(hexString: String, alpha: CGFloat = 1.0) -> UIColor {

            // Convert hex string to an integer
            let hexint = Int(self.intFromHexString(hexStr: hexString))
            let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
            let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
            let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
            
            // Create color object, specifying alpha as well
            let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            return color
        
        }
        
        private func intFromHexString(hexStr: String) -> UInt32 {
            var hexInt: UInt32 = 0
            // Create scanner
            let scanner: Scanner = Scanner(string: hexStr)
            // Tell scanner to skip the # character
            scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
            // Scan hex value
            scanner.scanHexInt32(&hexInt)
            return hexInt
        }
        
        enum Mode {
            case pay
            case storeCard
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
                expiresAt: purchaseDetails.creditCard.getExpiration().replacingOccurrences(of: " ", with: ""),
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
                traceId: request.params.customTraceId ?? request.session.id,
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
            traceId: params.customTraceId ?? request.session.id,
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
