package com.tungwang.tappayflutterplugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.common.api.Status
import com.google.android.gms.wallet.AutoResolveHelper
import com.google.android.gms.wallet.PaymentData
import com.google.android.gms.wallet.TransactionInfo
import com.google.android.gms.wallet.WalletConstants
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import tech.cherri.tpdirect.api.*
import tech.cherri.tpdirect.callback.dto.TPDCardInfoDto
import tech.cherri.tpdirect.callback.dto.TPDMerchantReferenceInfoDto

private var paymentData: PaymentData? = null
private var methodResult: Result? = null

/** TappayflutterpluginPlugin */
class TappayflutterpluginPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  lateinit var plugin: TappayflutterpluginPlugin
  private var context: Context? = null
  private var activity: Activity? = null
  private var tpdLinePayResultListenerInterface: TPDLinePayResultListenerInterface = TPDLinePayResultListenerInterface()
  private val tpdEasyWalletResultListenerInterface: TPDEasyWalletResultListenerInterface = TPDEasyWalletResultListenerInterface()
  private val tpdMerchant = TPDMerchant()
  private val tpdConsumer = TPDConsumer()
  private var tpdGooglePay: TPDGooglePay? = null

  constructor()

  constructor(context: Context) {
    this.context = context
  }

  companion object{
    const val TAG = "TappayPlugin"

    const val LOAD_PAYMENT_DATA_REQUEST_CODE = 102

    // 針對各種錯誤狀況制定 ErrorCode
    const val ERROR_CODE_CONTEXT_IS_NULL = "1001"
    const val ERROR_CODE_SETUP_TAPPAY_ERROR = "1002"
    const val ERROR_CODE_IS_CARD_VALID = "1003"
    const val ERROR_CODE_USER_CANCELED = "1004"

    // 針對支付功能不可用時的 ErrorCode
    const val ERROR_CODE_EASY_WALLET_UNAVAILABLE = "2001"
    const val ERROR_CODE_LINE_PAY_UNAVAILABLE = "2002"
    const val ERROR_CODE_GOOGLE_PAY_UNAVAILABLE = "2003"

    // 針對 getPrime 失敗的 ErrorCode
    const val ERROR_CODE_GET_PRIME_FAILED = "3000"
    const val ERROR_CODE_GET_EASY_WALLET_PRIME_FAILED = "3001"
    const val ERROR_CODE_GET_LINE_PAY_PRIME_FAILED = "3002"
    const val ERROR_CODE_GET_GOOGLE_PAY_PRIME_FAILED = "3003"
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tappayflutterplugin")
    plugin = TappayflutterpluginPlugin(flutterPluginBinding.applicationContext)
    channel.setMethodCallHandler(plugin)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    binding.addActivityResultListener(this)
    plugin.activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
//    TODO("Not yet implemented")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
//    TODO("Not yet implemented")
  }

  override fun onDetachedFromActivity() {
//    TODO("Not yet implemented")
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    when (requestCode) {
      LOAD_PAYMENT_DATA_REQUEST_CODE -> when (resultCode) {
        Activity.RESULT_OK -> {
          if (data != null) {
            paymentData = PaymentData.getFromIntent(data)
            methodResult?.success(paymentData!!.toJson())
          }
        }
        Activity.RESULT_CANCELED -> {
          methodResult?.error(ERROR_CODE_USER_CANCELED, "User canceled", "User canceled the payment")
        }
        AutoResolveHelper.RESULT_ERROR -> {
          val status: Status? = AutoResolveHelper.getStatusFromIntent(data)
          if (status != null) {
            Log.d("RESULT_ERROR", "AutoResolveHelper.RESULT_ERROR : " + status.statusCode.toString() + " , message = " + status.statusMessage)
            methodResult?.error(ERROR_CODE_USER_CANCELED, status.statusCode.toString(), status.statusMessage)
          }
        }
      }
    }
    return false
  }

//  companion object : PluginRegistry.ActivityResultListener {
//    @JvmStatic
//    fun registerWith(registrar: Registrar) {
//      val channel = MethodChannel(registrar.messenger(), "tappayflutterplugin")
//      val plugin = TappayflutterpluginPlugin(registrar.context())
//      channel.setMethodCallHandler(plugin)
//
//      registrar.addActivityResultListener(this)
//
//    }
//
//    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
//      TODO("Not yet implemented")
//    }
//  }

//  fun registerWith(registrar: PluginRegistry.Registrar) {
//    val channel = MethodChannel(registrar.messenger(), "tappayflutterplugin")
//    val plugin = TappayflutterpluginPlugin(registrar.context())
//    channel.setMethodCallHandler(plugin)
//    registrar.addActivityResultListener(this)
//  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    methodResult = result

    when (call.method) {
      in "setupTappay" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val appId: Int? = call.argument("appId")
          val appKey: String? = call.argument("appKey")
          val serverType: String? = call.argument("serverType")
          setupTappay(appId, appKey, serverType, errorMessage = {
            result.error(ERROR_CODE_SETUP_TAPPAY_ERROR, "Setup Tappay error", it)
          })
        }
      }

      in "isCardValid" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val cardNumber: String? = call.argument("cardNumber")
          val dueMonth: String? = call.argument("dueMonth")
          val dueYear: String? = call.argument("dueYear")
          val ccv: String? = call.argument("ccv")
          result.success(isCardValid(cardNumber, dueMonth, dueYear, ccv))
        }
      }

      in "getPrime" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val cardNumber: String? = call.argument("cardNumber")
          val dueMonth: String? = call.argument("dueMonth")
          val dueYear: String? = call.argument("dueYear")
          val ccv: String? = call.argument("ccv")
          getPrime(cardNumber, dueMonth, dueYear, ccv, prime = {
            result.success(it)
          }, failCallBack = {
            result.success(it)
          })
        }
      }

      in "isEasyWalletAvailable" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          result.success(isEasyWalletAvailable())
        }
      }

      in "getEasyWalletPrime" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val universalLink: String? = call.argument("universalLink")
          getEasyWalletPrime(universalLink, prime = {
            result.success(it)
          }, failCallBack = {
            result.success(it)
          })
        }
      }

      in "redirectToEasyWallet" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val universalLink: String? = call.argument("universalLink")
          val paymentUrl: String? = call.argument("paymentUrl")
          redirectToEasyWallet(universalLink, paymentUrl, callBack = {
            result.success(it)
          })
        }
      }

      in "parseToEasyWalletResult" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val universalLink: String? = call.argument("universalLink")
          val uri: String? = call.argument("uri")
          parseToEasyWalletResult(universalLink, uri, failCallBack = {
            result.success(it)
          }, successCallBack = {
            result.success(it)
          })
        }
      }

      in "getEasyWalletResult" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          getEasyWalletResult {
            result.success(it)
          }
        }
      }

      in "isLinePayAvailable" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          result.success(isLinePayAvailable())
        }
      }

      in "getLinePayPrime" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val universalLink: String? = call.argument("universalLink")
          getLinePayPrime(universalLink, prime = {
            result.success(it)
          }, failCallBack = {
            result.success(it)
          })
        }
      }

      in "redirectToLinePay" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val universalLink: String? = call.argument("universalLink")
          val paymentUrl: String? = call.argument("paymentUrl")
          redirectToLinePay(universalLink, paymentUrl, callBack = {
            result.success(it)
          })
        }
      }

      in "parseToLinePayResult" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          val universalLink: String? = call.argument("universalLink")
          val uri: String? = call.argument("uri")
          parseToLinePayResult(universalLink, uri, failCallBack = {
            result.success(it)
          }, successCallBack = {
            result.success(it)
          })
        }
      }

      in "getLinePayResult" -> {
        if (context == null) {
          result.error(ERROR_CODE_CONTEXT_IS_NULL, "context is null", "")
        } else {
          getLinePayResult {
            result.success(it)
          }
        }
      }

      in "preparePaymentData" -> {
        //取得allowedNetworks
        val allowedNetworks: ArrayList<TPDCard.CardType> = ArrayList()
        val cardTypeMap = mapOf(
                Pair(0, TPDCard.CardType.Unknown),
                Pair(1, TPDCard.CardType.JCB),
                Pair(2, TPDCard.CardType.Visa),
                Pair(3, TPDCard.CardType.MasterCard),
                Pair(4, TPDCard.CardType.AmericanExpress),
                Pair(5, TPDCard.CardType.UnionPay)
        )

        val networks: List<Int>? = call.argument("allowedNetworks")
        for (i in networks!!) {
          val type = cardTypeMap[i]
          type?.let { allowedNetworks.add(it) }
        }

        //取得allowedAuthMethods
        val allowedAuthMethods: MutableList<TPDCard.AuthMethod> = mutableListOf()
        val authMethodMap = mapOf(
                Pair(0, TPDCard.AuthMethod.PanOnly),
                Pair(1, TPDCard.AuthMethod.Cryptogram3DS)
        )
        val authMethods: List<Int>? = call.argument("allowedAuthMethods")
        for (i in authMethods!!) {
          val type = authMethodMap[i]
          type?.let { allowedAuthMethods.add(it) }
        }

        val merchantName: String? = call.argument("merchantName")
        val isPhoneNumberRequired: Boolean? = call.argument("isPhoneNumberRequired")
        val isShippingAddressRequired: Boolean? = call.argument("isShippingAddressRequired")
        val isEmailRequired: Boolean? = call.argument("isPhoneNumberRequired")

        preparePaymentData(allowedNetworks.toTypedArray(), allowedAuthMethods.toTypedArray(), merchantName, isPhoneNumberRequired, isShippingAddressRequired, isEmailRequired)
      }

      in "requestPaymentData" -> {
        val totalPrice: String? = call.argument("totalPrice")
        val currencyCode: String? = call.argument("currencyCode")
        requestPaymentData(totalPrice, currencyCode)
      }

      in "getGooglePayPrime" -> {
        getGooglePayPrime()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }

  //設置Tappay環境
  private fun setupTappay(appId: Int?, appKey: String?, serverType: String?, errorMessage: (String) -> (Unit)) {
    var message = ""

    if (appId == 0 || appId == null) {
      message += "appId error"
    }

    if (appKey.isNullOrEmpty()) {
      message += "/appKey error"
    }

    if (serverType.isNullOrEmpty()) {
      message += "/serverType error"
    }

    if (message.isNotEmpty()) {
      errorMessage(message)
      return
    }

    val st: TPDServerType = if (serverType == "sandBox") (TPDServerType.Sandbox) else (TPDServerType.Production)

    TPDSetup.initInstance(context, appId!!, appKey, st)
  }

  //檢查信用卡的有效性
  private fun isCardValid(cardNumber: String?, dueMonth: String?, dueYear: String?, ccv: String?): Boolean {

    if (cardNumber.isNullOrEmpty()) {
      return false
    }

    if (dueMonth.isNullOrEmpty()) {
      return false
    }

    if (dueYear.isNullOrEmpty()) {
      return false
    }

    if (ccv.isNullOrEmpty()) {
      return false
    }

    val result = TPDCard.validate(StringBuffer(cardNumber), StringBuffer(dueMonth), StringBuffer(dueYear), StringBuffer(ccv))

    return result.isCCVValid && result.isCardNumberValid && result.isExpiryDateValid
  }

  //取得Prime
  private fun getPrime(cardNumber: String?, dueMonth: String?, dueYear: String?, ccv: String?, prime: (String) -> (Unit), failCallBack: (String) -> (Unit)) {

    if (cardNumber == null || dueMonth == null || dueYear == null || ccv == null) {
      failCallBack("{\"status\":\"\", \"message\":\"something is null\", \"prime\":\"\"}")
    }else{
      val cn = StringBuffer(cardNumber)
      val dm = StringBuffer(dueMonth)
      val dy = StringBuffer(dueYear)
      val cv = StringBuffer(ccv)
      val card = TPDCard(context, cn, dm, dy, cv).onSuccessCallback { tpPrime, _, _, _ ->
        prime("{\"status\":\"\", \"message\":\"\", \"prime\":\"$tpPrime\"}")
      }.onFailureCallback { status, message ->
        failCallBack("{\"status\":\"$status\", \"message\":\"$message\", \"prime\":\"\"}")
      }
      card.createToken("Unknown")
    }

  }

  //檢查是否有安裝Easy wallet
  private fun isEasyWalletAvailable(): Boolean {
    return TPDEasyWallet.isAvailable(context)
  }

  //取得Easy wallet prime
  private fun getEasyWalletPrime(universalLink: String?, prime: (String) -> (Unit), failCallBack: (String) -> (Unit)) {

    if (universalLink == null) {
      failCallBack("{\"status\":\"\", \"message\":\"universalLink is null\", \"prime\":\"\"}")
    }else{
      val easyWallet = TPDEasyWallet(context, universalLink)
      easyWallet.getPrime({ tpPrime -> prime("{\"status\":\"\", \"message\":\"\", \"prime\":\"$tpPrime\"}") }, { status, message -> failCallBack("{\"status\":\"$status\", \"message\":\"$message\", \"prime\":\"\"}") })
    }
  }

  //重導向至Easy wallet
  private fun redirectToEasyWallet(universalLink: String?, paymentUrl: String?, callBack: (String) -> (Unit)) {

    if (universalLink == null || paymentUrl == null) {
      callBack("{\"status\":\"something is null\", \"recTradeId\":\"\", \"orderNumber\":\"\", \"bankTransactionId\":\"\"}")
    }else{
      val easyWallet = TPDEasyWallet(context, universalLink)
      easyWallet.redirectWithUrl(paymentUrl)
      callBack("{\"status\":\"redirect successfully\", \"recTradeId\":\"\", \"orderNumber\":\"\", \"bankTransactionId\":\"\"}")
    }
  }

  //解析East wallet result
  private fun parseToEasyWalletResult(universalLink: String?, uri: String?, failCallBack: (String) -> (Unit), successCallBack: (String) -> (Unit)) {

    if (universalLink == null || uri == null) {
      failCallBack("{\"message\":\"universalLink or uri is null\"}")
    }else{
      val easyWallet = TPDEasyWallet(context, universalLink)
      val parsedUri = Uri.parse(uri)
      easyWallet.parseToEasyWalletResult(context, parsedUri, this.tpdEasyWalletResultListenerInterface)
      successCallBack("Wait for EasyWallet result")
    }
  }

  //取得line pay result
  private fun getEasyWalletResult(result: (String) -> (Unit)) {
    if (tpdEasyWalletResultListenerInterface.successResult == null) {
      tpdEasyWalletResultListenerInterface.failResult?.let { result(it) }
    } else {
      tpdEasyWalletResultListenerInterface.successResult?.let { result(it) }
    }
  }

  //檢查是否有安裝line pay
  private fun isLinePayAvailable(): Boolean {
    return TPDLinePay.isLinePayAvailable(context)
  }

  //取得line pay prime
  private fun getLinePayPrime(universalLink: String?, prime: (String) -> (Unit), failCallBack: (String) -> (Unit)) {

    if (universalLink == null) {
      failCallBack("{\"status\":\"\", \"message\":\"universalLink is null\", \"prime\":\"\"}")
    }else{
      val linePay = TPDLinePay(context, universalLink)
      linePay.getPrime({ tpPrime -> prime("{\"status\":\"\", \"message\":\"\", \"prime\":\"$tpPrime\"}") }, { status, message -> failCallBack("{\"status\":\"$status\", \"message\":\"$message\", \"prime\":\"\"}") })
    }
  }

  //重導向至line pay
  private fun redirectToLinePay(universalLink: String?, paymentUrl: String?, callBack: (String) -> (Unit)) {

    if (universalLink == null || paymentUrl == null) {
      callBack("{\"status\":\"something is null\", \"recTradeId\":\"\", \"orderNumber\":\"\", \"bankTransactionId\":\"\"}")
    }else{
      val linePay = TPDLinePay(context, universalLink)
      linePay.redirectWithUrl(paymentUrl)
      callBack("{\"status\":\"redirect successfully\", \"recTradeId\":\"\", \"orderNumber\":\"\", \"bankTransactionId\":\"\"}")
    }
  }

  //解析line pay result
  private fun parseToLinePayResult(universalLink: String?, uri: String?, failCallBack: (String) -> (Unit), successCallBack: (String) -> (Unit)) {

    if (universalLink == null || uri == null) {
      failCallBack("{\"message\":\"universalLink or uri is null\"}")
    }else{
      val linePay = TPDLinePay(context, universalLink)
      val parsedUri = Uri.parse(uri)
      linePay.parseToLinePayResult(context, parsedUri, this.tpdLinePayResultListenerInterface)
      successCallBack("Wait for LinePay result")
    }
  }

  //取得line pay result
  private fun getLinePayResult(result: (String) -> (Unit)) {
    if (tpdLinePayResultListenerInterface.successResult == null) {
      tpdLinePayResultListenerInterface.failResult?.let { result(it) }
    } else {
      tpdLinePayResultListenerInterface.successResult?.let { result(it) }
    }
  }

  //Google pay
  private fun preparePaymentData(allowedNetworks: Array<TPDCard.CardType>, allowedAuthMethods: Array<TPDCard.AuthMethod>?, merchantName: String?, isPhoneNumberRequired: Boolean?, isShippingAddressRequired: Boolean?, isEmailRequired: Boolean?) {
    tpdMerchant.supportedNetworks = allowedNetworks
    tpdMerchant.supportedAuthMethods = allowedAuthMethods
    tpdMerchant.merchantName = merchantName
    if (isPhoneNumberRequired != null) {
      tpdConsumer.isPhoneNumberRequired = isPhoneNumberRequired
    }
    if (isShippingAddressRequired != null) {
      tpdConsumer.isShippingAddressRequired = isShippingAddressRequired
    }
    if (isEmailRequired != null) {
      tpdConsumer.isEmailRequired = isEmailRequired
    }

    if (this.activity != null) {
      tpdGooglePay = TPDGooglePay(this.activity, tpdMerchant, tpdConsumer)
      tpdGooglePay!!.isGooglePayAvailable { isReadyToPay: Boolean, msg: String ->
        if (isReadyToPay) {
          methodResult?.success(isReadyToPay)
        } else {
          methodResult?.error(ERROR_CODE_GOOGLE_PAY_UNAVAILABLE, "Cannot use Pay with Google", msg)
        }
      }
    } else {
      Log.d("preparePaymentData", "activity is null")
    }
  }

  //request payment data
  private fun requestPaymentData(totalPrice: String?, currencyCode: String?) {
    tpdGooglePay?.requestPayment(TransactionInfo.newBuilder()
            .setTotalPriceStatus(WalletConstants.TOTAL_PRICE_STATUS_FINAL)
            .setTotalPrice(totalPrice!!)
            .setCurrencyCode(currencyCode!!)
            .build(), LOAD_PAYMENT_DATA_REQUEST_CODE);
  }

  //get google pay prime
  private fun getGooglePayPrime() {
    tpdGooglePay?.getPrime(paymentData, { prime: String?, cardInfo: TPDCardInfoDto?, merchantReferenceInfo: TPDMerchantReferenceInfoDto? ->
      if (BuildConfig.DEBUG) {
        Log.d(TAG, "prime = $prime")
        Log.d(TAG, "cardInfo = $cardInfo")
        Log.d(TAG, "merchantReferenceInfo = $merchantReferenceInfo")
      }
      methodResult?.success(prime)
    }, {status: Int, msg: String? ->
      Log.d(TAG, "TapPay getPrime failed : $status, msg : $msg")
      methodResult?.error(ERROR_CODE_GET_GOOGLE_PAY_PRIME_FAILED, "Get google pay prime failed", msg)
    })
  }
}
