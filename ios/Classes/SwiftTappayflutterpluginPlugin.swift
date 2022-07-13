import Flutter
import UIKit
import TPDirect
import PassKit
import AdSupport


struct ErrorCode {
    /// 找不到對應的 method
    static let NoMatchedMethod = "0001"
    /// 完全沒有變數
    static let NoArguments = "0002"
    /// 缺少某個變數
    static let MissingArguments = "0003"
    
    // 針對各種錯誤狀況制定 ErrorCode
    static let SetupTappayError = "1002"
    static let IsCardValid = "1003"
    static let UserCanceled = "1004"
    
    // 針對支付功能不可用時的 ErrorCode
    static let ApplePayUnavailable = "2004"
    
    // apple pay 專屬的 error code
    static let ApplePayDidFailure = "4001"
}

public class SwiftTappayflutterpluginPlugin: NSObject, FlutterPlugin {
    
    /// apple pay 的 instance, 初始化後在 delegate 裡面會需要用到
    static var applePay : TPDApplePay!
    
    /// 用於存放 FlutterResult 的 instance, applepay 付款成功可以此通知 flutter 介面
    static var flutterResult: FlutterResult!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tappayflutterplugin", binaryMessenger: registrar.messenger())
        let instance = SwiftTappayflutterpluginPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        TPDLinePay.addExceptionObserver(#selector(tappayLinePayExceptionHandler(notofication:)))
        TPDEasyWallet.addExceptionObserver(#selector(tappayEasyWalletExceptionHandler(notofication:)))
        return true
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let tapPayHandled = TPDLinePay.handle(url)
        if (tapPayHandled) {
            return true
        }
        
        return false
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            let easyWalletHandled = TPDEasyWallet.handleUniversalLink(url)
            if (easyWalletHandled) {
                return true
            }
        }
        return true
    }
    
    @objc func tappayLinePayExceptionHandler(notofication: Notification) {
        
        let result : TPDLinePayResult = TPDLinePay.parseURL(notofication)
        
        print("status : \(result.status) , orderNumber : \(result.orderNumber ?? "") , recTradeid : \(result.recTradeId ?? "") , bankTransactionId : \(result.bankTransactionId ?? "") ")
        
    }
    
    @objc func tappayEasyWalletExceptionHandler(notofication: Notification) {
        
        let result : TPDEasyWalletResult = TPDEasyWallet.parseURL(notofication)
        
        print("status : \(result.status) , orderNumber : \(result.orderNumber ?? "") , recTradeid : \(result.recTradeId ?? "") , bankTransactionId : \(result.bankTransactionId ?? "") ")
        
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        let method = call.method
        
        // save FlutterResult instance
        SwiftTappayflutterpluginPlugin.flutterResult = result
        
        guard let args = call.arguments as? [String:Any] else {
            // 找不到 arguments, 這裡應該要收到一個 map
            // 如果是不帶參數的 method call, 請至少放入一個空的 map, 像這樣 {}
            result(FlutterError.init(code: ErrorCode.NoArguments, message: "No args", details: "There is no arguments map"))
            return
        }
        
        switch method {
        case "setupTappay":
            setupTappay(args: args) { (error) in
                result(error)
            }
            
        case "isCardValid":
            result(isCardValid(args: args))
            
        case "getPrime":
            getPrime(args: args) { (prime) in
                result(prime)
            } failCallBack: { (message) in
                result(message)
            }
            
        case "isEasyWalletAvailable":
            result(isEasyWalletAvailable())
            
        case "getEasyWalletPrime":
            getEasyWalletPrime(args: args) { (prime) in
                result(prime)
            } failCallBack: { (message) in
                result(message)
            }
            
        case "redirectToEasyWallet":
            redirectToEasyWallet(args: args) { (callBack) in
                result(callBack)
            }
            
        case "isLinePayAvailable":
            result(isLinePayAvailable())
            
        case "getLinePayPrime":
            getLinePayPrime(args: args) { (prime) in
                result(prime)
            } failCallBack: { (message) in
                result(message)
            }
            
        case "redirectToLinePay":
            redirectToLinePay(args: args) { (callBack) in
                result(callBack)
            }
            
        case "isApplePayAvailable":
            result(isApplePayAvailable())
        
        case "prepareApplePay":
            // 輸入各種參數進行 apple pay 的基本設定
            if let totalPrice = args["totalPrice"] as? String,
               let paymentTitle = args["paymentTitle"] as? String,
               let merchantName = args["merchantName"] as? String,
               let merchantId = args["merchantId"] as? String,
               let countryCode = args["countryCode"] as? String,
               let currencyCode = args["currencyCode"] as? String,
               let merchantCapabilities = args["merchantCapabilities"] as? Array<Int>,
               let allowedNetworks = args["allowedNetworks"] as? Array<Int>,
               let isAmountPending = args["isAmountPending"] as? Bool,
               let isShowPaymentItem = args["isShowPaymentItem"] as? Bool,
               let isShowTotalAmount = args["isShowTotalAmount"] as? Bool {
                
                prepareApplePay(
                    totalPrice: totalPrice,
                    paymentTitle: paymentTitle,
                    merchantName: merchantName,
                    merchantId: merchantId,
                    countryCode: countryCode,
                    currencyCode: currencyCode,
                    merchantCapability: translateCapability(capabilities: merchantCapabilities),
                    supportedNetworks: translateNetworks(networks: allowedNetworks),
                    isAmountPending: isAmountPending,
                    isShowPaymentItem: isShowPaymentItem,
                    isShowTotalAmount: isShowTotalAmount
                )
            } else {
                result(FlutterError.init(code: ErrorCode.MissingArguments, message: "Missing args", details: "Some arguments might be missing, please check invokeMethod input arguments"))
            }

        case "startApplePay":
            // 藉由剛剛設定過的資料, 彈出 apple pay 視窗進行付款請求
            startApplePay()

        case "showApplePayPaymentResult":
            // 執行完 pay by prime 之後, 將執行成功/失敗的狀態通知 apple pay 視窗更新狀態
            if let paymentResult = args["paymentResult"] as? Bool {
                showPaymentResult(paymentResult: paymentResult)
            } else {
                result(FlutterError.init(code: ErrorCode.MissingArguments, message: "Missing args", details: "Missing argument paymentResult"))
            }

        default:
            result(FlutterError.init(code: ErrorCode.NoMatchedMethod, message: "No matched method", details: "Method \(method) is not exist, please check method name is currect"))
        }
        
    }
    
    /// Check device support Apple Pay
    fileprivate func isApplePayAvailable() -> Bool {
        return TPDApplePay.canMakePayments()
    }

    /// 輸入付款相關資料, 金額, 名稱等
    /// - Parameters:
    ///   - totalPrice: 付款總金額
    ///   - paymentTitle: 付款名稱
    ///   - merchantName: 商家名稱
    ///   - merchantId: Your Apple Pay Merchant ID  (https://developer.apple.com/account/ios/identifier/merchant)
    ///   - countryCode: country code, like TW
    ///   - currencyCode: currency code, like TWD
    ///   - merchantCapability: merchantCapability
    ///   - supportedNetworks: 支援的卡片類型, 目前僅支援常見的信用卡組織, visa, mastercard, jcb, amex, union pay
    ///   - isAmountPending: 此購物車是否會立即扣款並付款完成交易
    ///   - isShowPaymentItem: 是否顯示購物車的品項
    ///   - isShowTotalAmount: 是否顯示總金額
    fileprivate func prepareApplePay(
        totalPrice: String,
        paymentTitle: String,
        merchantName: String,
        merchantId: String,
        countryCode: String,
        currencyCode: String,
        merchantCapability: PKMerchantCapability,
        supportedNetworks: [PKPaymentNetwork],
        isAmountPending: Bool,
        isShowPaymentItem: Bool,
        isShowTotalAmount: Bool
    ) {

         if (!isApplePayAvailable()) {
             SwiftTappayflutterpluginPlugin.flutterResult(FlutterError.init(code: ErrorCode.ApplePayUnavailable, message: "Cannot use Pay with ApplePay", details: ""))
         }
        
        // 設定商家資訊, 支援的支付方式, 幣別..等
        let merchant = TPDMerchant()
        merchant.merchantName               = merchantName
        merchant.applePayMerchantIdentifier = merchantId;
        merchant.merchantCapability         = merchantCapability
        merchant.countryCode                = countryCode;
        merchant.currencyCode               = currencyCode;
        merchant.supportedNetworks          = supportedNetworks
        
        // 設定配送選項, 配送相關資訊與費用
        // Set Shipping Method.
        // let shipping1 = PKShippingMethod()
        // shipping1.identifier = "TapPayExpressShippint024"
        // shipping1.detail     = "Ships in 24 hours"
        // shipping1.amount     = NSDecimalNumber(string: "10.0");
        // shipping1.label      = "Shipping 24"
        // let shipping2 = PKShippingMethod()
        // shipping2.identifier = "TapPayExpressShippint006";
        // shipping2.detail     = "Ships in 6 hours";
        // shipping2.amount     = NSDecimalNumber(string: "50.0");
        // shipping2.label      = "Shipping 6";
        // merchant.shippingMethods            = [shipping1, shipping2];
    
        // 設定聯絡資訊
        // Set Consumer Contact.
        // let contact = PKContact()
        // var name    = PersonNameComponents()
        // name.familyName = "Cherri"
        // name.givenName  = "TapPay"
        // contact.name    = name;
        
        // 設定消費者資訊, 帳單地址, 配送地址, 收件人..等
        let consumer = TPDConsumer()
        // consumer.billingContact     = contact
        // consumer.shippingContact    = contact
        // consumer.requiredShippingAddressFields  = []
        // consumer.requiredBillingAddressFields   = []
        
        // 設定購物車細節
        let cart = TPDCart()
        
        // 是否立即付款完成交易
        // isAmountPending
        // false 代表會立即扣款並成功付款
        // true 一樣會立即扣款, 但不會馬上成功付款, 錢會被 apple pay 扣著, 此時的交易狀態會是 pending
        // 待商家確認完訂單, 確認完金額後才會向 apple pay 進行請款動作, 此時的交易狀態才會是 successful
        cart.isAmountPending = isAmountPending
        // 是否顯示總金額, 目前這個設定 false 會無法正常付款, 原因待查
        cart.isShowTotalAmount = isShowTotalAmount
        let totalAmount = NSDecimalNumber(string: totalPrice)
        cart.totalAmount = totalAmount
        
        let paymentItem = TPDPaymentItem(itemName: paymentTitle, withAmount: totalAmount, withIsVisible: isShowPaymentItem)
        cart.add(paymentItem)
        
        // 用途不明
        // let pendingPaymentItem = TPDPaymentItem.pendingPaymentItem(withItemName: "pendingItem")
        // cart.add(pendingPaymentItem)
        
        SwiftTappayflutterpluginPlugin.applePay = TPDApplePay.setupWthMerchant(merchant, with: consumer, with: cart, withDelegate: self)
        
        SwiftTappayflutterpluginPlugin.flutterResult(SwiftTappayflutterpluginPlugin.applePay != nil)
    }

    /// 開始付款
    fileprivate func startApplePay() {
        SwiftTappayflutterpluginPlugin.applePay.startPayment()
    }
    
    /// 在 ApplePay 的 UI 上顯示付款結果
    /// 執行完 pay by prime 之後, 將執行成功/失敗的狀態通知 apple pay 視窗更新狀態
    /// - Parameters:
    ///   - paymentResult: 付款成功/失敗
    fileprivate func showPaymentResult(paymentResult: Bool) {
        SwiftTappayflutterpluginPlugin.applePay.showPaymentResult(paymentResult)
    }
    
    /// 將 flutter 端傳回來的 int array 轉成 PKPaymentNetwork array
    /// 用於 applePay 的 merchant.supportedNetworks
    ///
    /// Note: applePay 的 PKPaymentNetwork 有十幾種, 連日本的西瓜卡都有
    /// 不過暫時用不到那麼多, 剩下的之後有需求再處理, 目前這個版本先放最常見的信用卡組織
    ///
    /// - Parameters:
    ///   - networks: flutter 端傳回來的 int array
    /// - Returns: PKPaymentNetwork array for merchant.supportedNetworks
    fileprivate func translateNetworks(networks: Array<Int>) -> [PKPaymentNetwork] {
        var supportedNetworks = [PKPaymentNetwork]()

        // 將 allowedNetworks 轉成 supportedNetworks
        for network in networks {
            switch network {
            case 1:
                if #available(iOS 10.1, *) {
                  // iOS 10.1 以上才支援 JCB, 低於 10.1 不做處理
                  supportedNetworks.append(PKPaymentNetwork.JCB)
                }
            case 2:
                supportedNetworks.append(PKPaymentNetwork.visa)
            case 3:
                supportedNetworks.append(PKPaymentNetwork.masterCard)
            case 4:
                supportedNetworks.append(PKPaymentNetwork.amex)
            case 5:
                if #available(iOS 9.2, *) {
                  // iOS 9.2 以上才支援 union pay, 低於 9.2 不做處理
                  supportedNetworks.append(PKPaymentNetwork.chinaUnionPay)
                }
            default:
                print("do nothing")
            }
        }
        return supportedNetworks
    }
    
    /// 將 flutter 端傳回來的 capabilities int array 轉成 PKMerchantCapability
    /// 用於 applePay 的 merchant.merchantCapability
    ///
    /// - Parameters:
    ///   - capabilities: flutter 端傳回來的 int array
    /// - Returns: PKMerchantCapability for merchant.merchantCapability
    fileprivate func translateCapability(capabilities: Array<Int>) -> PKMerchantCapability {
        var merchantCapability: PKMerchantCapability = []

        // 將 capabilities 轉成 merchantCapability
        for capability in capabilities {
            switch capability {
            case 1:
                merchantCapability.insert(.capability3DS)
            case 2:
                merchantCapability.insert(.capabilityEMV)
            case 3:
                merchantCapability.insert(.capabilityCredit)
            case 4:
                merchantCapability.insert(.capabilityDebit)
            default:
                print("do nothing")
            }
        }
        return merchantCapability
    }
    
    //設置Tappay環境
    fileprivate func setupTappay(args: [String:Any], errorMessage: @escaping(String) -> Void) {
        
        var message: String = ""
        
        let appId = (args["appId"] as? Int32 ?? 0)
        let appKey = (args["appKey"] as? String ?? "")
        let serverType = (args["serverType"] as? String ?? "")
        
        if appId == 0 {
            message += "appId error"
        }
        
        if appKey.isEmpty {
            message += "/appKey error"
        }
        
        if serverType.isEmpty {
            message += "/serverType error"
        }
        
        if !message.isEmpty {
            errorMessage(message)
            return
        }
        
        let st: TPDServerType = {
            return serverType == "sandBox" ? TPDServerType.sandBox : TPDServerType.production
        }()
        
        
        TPDSetup.setWithAppId(appId, withAppKey: appKey, with: st)
//        TPDSetup.shareInstance().setupIDFA(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
//        TPDSetup.shareInstance().serverSync()
    }
    
    //檢查信用卡的有效性
    fileprivate func isCardValid(args: [String:Any]) -> Bool {
        
        let cardNumber = (args["cardNumber"] as? String ?? "")
        let dueMonth = (args["dueMonth"] as? String ?? "")
        let dueYear = (args["dueYear"] as? String ?? "")
        let ccv = (args["ccv"] as? String ?? "")
        
        
        guard let cardValidResult = TPDCard.validate(withCardNumber: cardNumber, withDueMonth: dueMonth, withDueYear: dueYear, withCCV: ccv) else { return false }
        
        if cardValidResult.isCardNumberValid && cardValidResult.isExpiryDateValid && cardValidResult.isCCVValid {
            return true
        }else{
            return false
        }
    }
    
    //取得prime
    fileprivate func getPrime(args: [String:Any], prime: @escaping(String) -> Void, failCallBack: @escaping(String) -> Void) {
        
        let cardNumber = (args["cardNumber"] as? String ?? "")
        let dueMonth = (args["dueMonth"] as? String ?? "")
        let dueYear = (args["dueYear"] as? String ?? "")
        let ccv = (args["ccv"] as? String ?? "")
        
        let card = TPDCard.setWithCardNumber(cardNumber, withDueMonth: dueMonth, withDueYear: dueYear, withCCV: ccv)
        card.onSuccessCallback { (tpPrime, cardInfo, cardIdentifier, merchantReferenceInfo) in
            if let tpPrime = tpPrime {
                prime("{\"status\":\"\", \"message\":\"\", \"prime\":\"\(tpPrime)\"}")
            }
        }.onFailureCallback { (status, message) in
            failCallBack("{\"status\":\"\(status)\", \"message\":\"\(message)\", \"prime\":\"\"}")
        }.createToken(withGeoLocation: "UNKNOWN")
    }
    
    //檢查是否有安裝Easy wallet
    fileprivate func isEasyWalletAvailable() -> Bool {
        return TPDEasyWallet.isEasyWalletAvailable()
    }
    
    
    //取得Easy wallet prime
    fileprivate func getEasyWalletPrime(args: [String:Any], prime: @escaping(String) -> Void, failCallBack: @escaping(String) -> Void) {
        
        let universalLink = (args["universalLink"] as? String ?? "")
        
        if (universalLink.isEmpty) {
            failCallBack("{\"status\":\"\", \"message\":\"universalLink is empty\", \"prime\":\"\"}")
            return
        }
        
        let easyWallet = TPDEasyWallet.setup(withReturUrl: universalLink)
        easyWallet.onSuccessCallback { (tpPrime) in
            
            if let tpPrime = tpPrime {
                prime("{\"status\":\"\", \"message\":\"\", \"prime\":\"\(tpPrime)\"}")
            }
            
        }.onFailureCallback { (status, message) in
            
            failCallBack("{\"status\":\"\(status)\", \"message\":\"\(message)\", \"prime\":\"\"}")
            
        }.getPrime()
        
    }
    
    //重導向至Easy wallet
    fileprivate func redirectToEasyWallet(args: [String:Any], callBack: @escaping(String) -> Void) {
        
        let universalLink = (args["universalLink"] as? String ?? "")
        let easyWallet = TPDEasyWallet.setup(withReturUrl: universalLink)
        
        let paymentUrl = (args["paymentUrl"] as? String ?? "")
        easyWallet.redirect(paymentUrl) { (result) in
            callBack("{\"status\":\"\(String(result.status))\", \"recTradeId\":\"\(String(result.recTradeId))\", \"orderNumber\":\"\(String(result.orderNumber))\", \"bankTransactionId\":\"\(String(result.bankTransactionId))\"}")
        }
    }
    
    //檢查是否有安裝Line pay
    fileprivate func isLinePayAvailable() -> Bool {
        let result = TPDLinePay.isLinePayAvailable()
        return result
    }
    
    
    //取得line pay prime
    fileprivate func getLinePayPrime(args: [String:Any], prime: @escaping(String) -> Void, failCallBack: @escaping(String) -> Void) {
        
        let universalLink = (args["universalLink"] as? String ?? "")
        
        if (universalLink.isEmpty) {
            failCallBack("{\"status\":\"\", \"message\":\"universalLink is empty\", \"prime\":\"\"}")
            return
        }
        
        let linePay = TPDLinePay.setup(withReturnUrl: universalLink)
        linePay.onSuccessCallback { (tpPrime) in
            
            if let tpPrime = tpPrime {
                prime("{\"status\":\"\", \"message\":\"\", \"prime\":\"\(tpPrime)\"}")
            }
            
        }.onFailureCallback { (status, message) in
            
            failCallBack("{\"status\":\"\(status)\", \"message\":\"\(message)\", \"prime\":\"\"}")
            
        }.getPrime()
        
    }
    
    //重導向至line pay
    fileprivate func redirectToLinePay(args: [String:Any], callBack: @escaping(String) -> Void) {
        
        let universalLink = (args["universalLink"] as? String ?? "")
        let linePay = TPDLinePay.setup(withReturnUrl: universalLink)
        
        let paymentUrl = (args["paymentUrl"] as? String ?? "")
        
//        let rootViewController = UIApplication.shared.windows.filter({ (w) -> Bool in
//                    return w.isHidden == false
//         }).first?.rootViewController
        
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController else { return }
        
        linePay.redirect(paymentUrl, with: vc) { (result) in
            callBack("{\"status\":\"\(String(result.status))\", \"recTradeId\":\"\(String(result.recTradeId))\", \"orderNumber\":\"\(String(result.orderNumber))\", \"bankTransactionId\":\"\(String(result.bankTransactionId))\"}")
        }
    }
}

/// Use extension implement TPDApplePayDelegate
/// You can receive every state change event
extension SwiftTappayflutterpluginPlugin : TPDApplePayDelegate {
    public func tpdApplePayDidStartPayment(_ applePay: TPDApplePay!) {
        print("=====================================================")
        print("Apple Pay On Start")
        print("===================================================== \n\n")
    }
    
    public func tpdApplePay(_ applePay: TPDApplePay!, didSuccessPayment result: TPDTransactionResult!) {
        print("=====================================================")
        print("Apple Pay Did Success ==> Amount : \(result.amount.stringValue)")
        
        print("shippingContact.name : \(applePay.consumer.shippingContact?.name?.givenName ?? "") \( applePay.consumer.shippingContact?.name?.familyName ?? "")")
        print("shippingContact.emailAddress : \(applePay.consumer.shippingContact?.emailAddress ?? "")")
        print("shippingContact.phoneNumber : \(applePay.consumer.shippingContact?.phoneNumber?.stringValue ?? "")")
        print("===================================================== \n\n")

    }
    
    public func tpdApplePay(_ applePay: TPDApplePay!, didFailurePayment result: TPDTransactionResult!) {
        print("=====================================================")
        print("Apple Pay Did Failure ==> Message : \(result.message ?? ""), ErrorCode : \(result.status)")
        print("===================================================== \n\n")
        
        SwiftTappayflutterpluginPlugin.flutterResult(FlutterError.init(code: ErrorCode.ApplePayDidFailure, message: "Apple Pay Did Failure", details: "Message: \(result.message ?? ""), ErrorCode: \(result.status)"))
    }
    
    public func tpdApplePayDidCancelPayment(_ applePay: TPDApplePay!) {
        print("=====================================================")
        print("Apple Pay Did Cancel")
        print("===================================================== \n\n")
        
        SwiftTappayflutterpluginPlugin.flutterResult(FlutterError.init(code: ErrorCode.UserCanceled, message: "User canceled", details: "User canceled this payment"))
    }
    
    public func tpdApplePayDidFinishPayment(_ applePay: TPDApplePay!) {
        print("=====================================================")
        print("Apple Pay Did Finish")
        print("===================================================== \n\n")
    }
    
    public func tpdApplePay(_ applePay: TPDApplePay!, didSelect shippingMethod: PKShippingMethod!) {
        print("=====================================================")
        print("======> didSelectShippingMethod: ")
        print("Shipping Method.identifier : \(shippingMethod.identifier?.description ?? "")")
        print("Shipping Method.detail : \(shippingMethod.detail ?? "")")
        print("===================================================== \n\n")
    }
    
    public func tpdApplePay(_ applePay: TPDApplePay!, didSelect paymentMethod: PKPaymentMethod!, cart: TPDCart!) -> TPDCart! {
        print("=====================================================");
        print("======> didSelectPaymentMethod: ");
        print("===================================================== \n\n");
        return cart;        
    }
    
    public func tpdApplePay(_ applePay: TPDApplePay!, canAuthorizePaymentWithShippingContact shippingContact: PKContact?) -> Bool {
        //
        print("=====================================================")
        print("======> canAuthorizePaymentWithShippingContact ")
        print("shippingContact.name : \(shippingContact?.name?.givenName ?? "") \(shippingContact?.name?.familyName ?? "")")
        print("shippingContact.emailAddress : \(shippingContact?.emailAddress ?? "")")
        print("shippingContact.phoneNumber : \(shippingContact?.phoneNumber?.stringValue ?? "")")
        print("===================================================== \n\n")
        return true;
    }
    
    // With Payment Handle
    public func tpdApplePay(_ applePay: TPDApplePay!, didReceivePrime prime: String!, withExpiryMillis expiryMillis: Int, with cardInfo: TPDCardInfo, withMerchantReferenceInfo merchantReferenceInfo: [AnyHashable : Any]!) {
        // 1. Send Your Prime To Your Server, And Handle Payment With Result
        // ...
        print("=====================================================");
        print("======> didReceivePrime");
        print("Prime : \(prime!)");
        print("Expiry millis : \(expiryMillis)");
        print("total Amount :   \(applePay.cart.totalAmount!)")
        print("Client IP : \(applePay.consumer.clientIP!)")
        print("merchantReferenceInfo : \(merchantReferenceInfo["affiliateCodes"]!)")
        print("shippingContact.name : \(applePay.consumer.shippingContact?.name?.givenName ?? "") \(applePay.consumer.shippingContact?.name?.familyName ?? "")");
        print("shippingContact.emailAddress : \(applePay.consumer.shippingContact?.emailAddress ?? "")");
        print("shippingContact.phoneNumber : \(applePay.consumer.shippingContact?.phoneNumber?.stringValue ?? "")");

        let paymentMethod = applePay.consumer.paymentMethod!

        print("type : \(paymentMethod.type.rawValue)")
        print("Network : \(paymentMethod.network!.rawValue)")
        print("Display Name : \(paymentMethod.displayName!)")
        print("===================================================== \n\n");
        
        // 2. If Payment Success, set paymentReault = ture.
        // let paymentReault = true;
        // applePay.showPaymentResult(paymentReault)
        
        // callback 通知 flutter 端收到 getPrime
        SwiftTappayflutterpluginPlugin.flutterResult(prime)
    }
}
