import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'log_util.dart';

enum TappayServerType {
  sandBox,
  production,
}

enum TPDCardType { unknown, visa, masterCard, jcb, americanExpress, unionPay }

enum TPDCardAuthMethod { panOnly, cryptogram3ds }

/// For Apple Pay, mapping to frameworks PassKit/PKMerchantCapability
enum TPDApplePayMerchantCapability {
  capability3DS,
  capabilityEMV,
  capabilityCredit,
  capabilityDebit
}

class PrimeModel {
  String? status;
  String? message;
  String? prime;

  PrimeModel({this.status, this.message, this.prime});

  PrimeModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    prime = json['prime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['prime'] = this.prime;
    return data;
  }
}

class TPDEasyWalletResult {
  String? status;
  String? recTradeId;
  String? orderNumber;
  String? bankTransactionId;

  TPDEasyWalletResult(
      {this.status, this.recTradeId, this.orderNumber, this.bankTransactionId});

  TPDEasyWalletResult.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    recTradeId = json['recTradeId'];
    orderNumber = json['orderNumber'];
    bankTransactionId = json['bankTransactionId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['recTradeId'] = this.recTradeId;
    data['orderNumber'] = this.orderNumber;
    data['bankTransactionId'] = this.bankTransactionId;
    return data;
  }
}

class TPDLinePayResult {
  String? status;
  String? recTradeId;
  String? orderNumber;
  String? bankTransactionId;

  TPDLinePayResult(
      {this.status, this.recTradeId, this.orderNumber, this.bankTransactionId});

  TPDLinePayResult.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    recTradeId = json['recTradeId'];
    orderNumber = json['orderNumber'];
    bankTransactionId = json['bankTransactionId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['recTradeId'] = this.recTradeId;
    data['orderNumber'] = this.orderNumber;
    data['bankTransactionId'] = this.bankTransactionId;
    return data;
  }
}

class Tappayflutterplugin {
  static const MethodChannel _channel =
  const MethodChannel('tappayflutterplugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  //設置Tappay環境
  static Future<void> setupTappay({
    required int appId,
    required String appKey,
    required TappayServerType serverType,
    required Function(String) errorMessage,
  }) async {
    String st = '';
    switch (serverType) {
      case TappayServerType.sandBox:
        st = 'sandBox';
        break;
      case TappayServerType.production:
        st = 'production';
        break;
    }

    try {
      await _channel.invokeMethod(
        'setupTappay',
        {
          'appId': appId,
          'appKey': appKey,
          'serverType': st,
        },
      );
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
      errorMessage(error.details ?? "");
    }
  }

  //檢查信用卡的有效性
  static Future<bool> isCardValid({
    required String cardNumber,
    required String dueMonth,
    required String dueYear,
    required String ccv,
  }) async {
    bool isValid = false;
    try {
      isValid = await _channel.invokeMethod(
        'isCardValid',
        {
          'cardNumber': cardNumber,
          'dueMonth': dueMonth,
          'dueYear': dueYear,
          'ccv': ccv,
        },
      );
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
    }
    return isValid;
  }

  //取得Prime
  static Future<PrimeModel> getPrime({
    required String cardNumber,
    required String dueMonth,
    required String dueYear,
    required String ccv,
  }) async {
    try {

    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
    }
    String response = await _channel.invokeMethod(
      'getPrime',
      {
        'cardNumber': cardNumber,
        'dueMonth': dueMonth,
        'dueYear': dueYear,
        'ccv': ccv,
      },
    );

    return PrimeModel.fromJson(json.decode(response));
  }

  //檢查是否有安裝Easy wallet
  static Future<bool> isEasyWalletAvailable() async {
    bool response = await _channel.invokeMethod('isEasyWalletAvailable', {});
    return response;
  }

  //取得Easy wallet prime
  static Future<PrimeModel> getEasyWalletPrime(
      {required String universalLink}) async {
    String response = await _channel.invokeMethod(
      'getEasyWalletPrime',
      {'universalLink': universalLink},
    );
    return PrimeModel.fromJson(json.decode(response));
  }

  //重導向至EasyWallet
  static Future<TPDEasyWalletResult> redirectToEasyWallet(
      {required String universalLink, required String paymentUrl}) async {
    String result = await _channel.invokeMethod(
      'redirectToEasyWallet',
      {
        'universalLink': universalLink,
        'paymentUrl': paymentUrl,
      },
    );
    return TPDEasyWalletResult.fromJson(json.decode(result));
  }

  //解析Easy wallet result
  static Future<void> parseToEasyWalletResult(
      {required String universalLink, required String uri}) async {
    await _channel.invokeMethod(
      'parseToEasyWalletResult',
      {
        'universalLink': universalLink,
        'uri': uri,
      },
    );
    return;
  }

  //取得Easy wallet result
  static Future<TPDEasyWalletResult?> getEasyWalletResult() async {
    String result = await _channel.invokeMethod(
      'getEasyWalletResult',
    );

    try {
      return TPDEasyWalletResult.fromJson(json.decode(result));
    } catch (e) {
      print(e);
      print(result);
      return null;
    }
  }

  //檢查是否有安裝LinePay
  static Future<bool> isLinePayAvailable() async {
    var response = await _channel.invokeMethod('isLinePayAvailable', {});
    return response;
  }

  //取得Line pay prime
  static Future<PrimeModel> getLinePayPrime(
      {required String universalLink}) async {
    String response = await _channel.invokeMethod(
      'getLinePayPrime',
      {'universalLink': universalLink},
    );
    return PrimeModel.fromJson(json.decode(response));
  }

  //重導向至LinePay
  static Future<TPDLinePayResult> redirectToLinePay(
      {required String universalLink, required String paymentUrl}) async {
    String result = await _channel.invokeMethod(
      'redirectToLinePay',
      {
        'universalLink': universalLink,
        'paymentUrl': paymentUrl,
      },
    );
    return TPDLinePayResult.fromJson(json.decode(result));
  }

  //解析line pay result
  static Future<void> parseToLinePayResult(
      {required String universalLink, required String uri}) async {
    await _channel.invokeMethod(
      'parseToLinePayResult',
      {
        'universalLink': universalLink,
        'uri': uri,
      },
    );
    return;
  }

  //取得line pay result
  static Future<TPDLinePayResult?> getLinePayResult() async {
    String result = await _channel.invokeMethod(
      'getLinePayResult',
    );

    try {
      return TPDLinePayResult.fromJson(json.decode(result));
    } catch (e) {
      print(e);
      print(result);
      return null;
    }
  }

  /// Check device support Apple Pay
  static Future<bool> isApplePayAvailable() async {
    bool available = false;
    try {
      available = await _channel.invokeMethod('isApplePayAvailable', {});
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
    }
    Log.d("isApplePayAvailable: $available");
    return available;
  }

  /// 輸入相關資料進行 ApplePay 付款前的設定
  /// [totalPrice] 總金額
  /// [paymentTitle] 付款項目名稱
  /// [merchantName] 商家名稱
  /// [merchantId] 登記在 apple developer 的 merchant identifier
  /// [countryCode] 國別, 例如 "TW"
  /// [currencyCode] 貨幣別, 例如 "TWD"
  /// [merchantCapabilities] 支援的驗證方式
  /// [allowedNetworks] 支援的信用卡類型, 目前列入常用的信用卡組織, 日後有需要再增加其他
  /// [isAmountPending] 是否延後付款, 預設 false
  /// [isShowPaymentItem] 是否顯示購買品項, 預設 ture
  /// [isShowTotalAmount] 是否顯示總金額, 目前這個設定 false 會無法正常付款, 原因待查
  static Future<bool> prepareApplePay({
    required String totalPrice,
    required String paymentTitle,
    required String merchantName,
    required String merchantId,
    required String countryCode,
    required String currencyCode,
    required List<TPDApplePayMerchantCapability> merchantCapabilities,
    required List<TPDCardType> allowedNetworks,
    bool isAmountPending = false,
    bool isShowPaymentItem = true,
    bool isShowTotalAmount = true,
    required Function(String errorMessage) onError,
  }) async {
    List<int> networks = translateNetworks(allowedNetworks);
    List<int> capabilities = translateCapabilities(merchantCapabilities);

    try {
      bool isPrepared = await _channel.invokeMethod(
        'prepareApplePay',
        {
          'totalPrice': totalPrice,
          'paymentTitle': paymentTitle,
          'merchantName': merchantName,
          'merchantId': merchantId,
          'countryCode': countryCode,
          'currencyCode': currencyCode,
          'allowedNetworks': networks,
          'merchantCapabilities': capabilities,
          'isAmountPending': isAmountPending,
          'isShowPaymentItem': isShowPaymentItem,
          'isShowTotalAmount': isShowTotalAmount,
        },
      );
      Log.d("prepareApplePay, isPrepared? $isPrepared");
      return true;
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
      onError(error.message ?? "");
      return false;
    }
  }

  /// 執行 apple pay 付款
  static Future<void> startApplePay({
    required Function(String prime) onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      String prime = await _channel.invokeMethod('startApplePay', {});
      onSuccess(prime);
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
      onError(error.message ?? "");
    }
  }

  /// 執行完 pay by prime 之後, 將執行成功/失敗的狀態通知 apple pay 視窗更新狀態
  static Future<void> showPaymentResult(bool paymentResult) async {
    try {
      await _channel.invokeMethod('showApplePayPaymentResult', {
        'paymentResult': paymentResult
      });
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
    }
  }

  //GooglePay prepare payment data
  static Future<bool> preparePaymentData({
    required List<TPDCardType> allowedNetworks,
    required List<TPDCardAuthMethod> allowedAuthMethods,
    required String merchantName,
    required bool isPhoneNumberRequired,
    required bool isShippingAddressRequired,
    required bool isEmailRequired,
  }) async {
    List<int> networks = translateNetworks(allowedNetworks);

    List<int> methods = [];
    for (var i in allowedAuthMethods) {
      int value;
      switch (i) {
        case TPDCardAuthMethod.panOnly:
          value = 0;
          break;
        case TPDCardAuthMethod.cryptogram3ds:
          value = 1;
          break;
      }
      methods.add(value);
    }

    bool isPrepared = false;
    try {
      isPrepared = await _channel.invokeMethod(
        'preparePaymentData',
        {
          'allowedNetworks': networks,
          'allowedAuthMethods': methods,
          'merchantName': merchantName,
          'isPhoneNumberRequired': isPhoneNumberRequired,
          'isShippingAddressRequired': isShippingAddressRequired,
          'isEmailRequired': isEmailRequired,
        },
      );
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
    }

    return isPrepared;
  }

  //request google pay payment data
  static Future<void> requestPaymentData({
    required String totalPrice,
    required String currencyCode,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      String result = await _channel.invokeMethod(
        'requestPaymentData',
        {
          'totalPrice': totalPrice,
          'currencyCode': currencyCode,
        },
      );
      onSuccess(result);
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
      onError(error.message ?? "");
    }
  }

  //Get google pay prime
  static Future<void> getGooglePayPrime({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      String result = await _channel.invokeMethod('getGooglePayPrime');
      onSuccess(result);
    } on PlatformException catch (error) {
      Log.d("PlatformException: ${error.message}, ${error.details}");
      onError(error.message ?? "");
    }
  }

  static List<int> translateCapabilities(
      List<TPDApplePayMerchantCapability> merchantCapabilities) {
    List<int> capabilities = [];
    for (var i in merchantCapabilities) {
      int value;
      switch (i) {
        case TPDApplePayMerchantCapability.capability3DS:
          value = 1;
          break;
        case TPDApplePayMerchantCapability.capabilityEMV:
          value = 2;
          break;
        case TPDApplePayMerchantCapability.capabilityCredit:
          value = 3;
          break;
        case TPDApplePayMerchantCapability.capabilityDebit:
          value = 4;
          break;
      }
      capabilities.add(value);
    }
    return capabilities;
  }

  /// 由於 GooglePay 跟 ApplePay 暫時共用 networks 的選項
  /// 故把判斷與重新組裝的流程拉出來一個 function
  static List<int> translateNetworks(List<TPDCardType> allowedNetworks) {
    List<int> networks = [];
    for (var i in allowedNetworks) {
      int value;
      switch (i) {
        case TPDCardType.unknown:
          value = 0;
          break;
        case TPDCardType.visa:
          value = 2;
          break;
        case TPDCardType.masterCard:
          value = 3;
          break;
        case TPDCardType.jcb:
          value = 1;
          break;
        case TPDCardType.americanExpress:
          value = 4;
          break;
        case TPDCardType.unionPay:
          value = 5;
          break;
      }
      networks.add(value);
    }
    return networks;
  }
}
