import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tappayflutterplugin/tappayflutterplugin.dart';

import 'constant.dart';

class ApplePayScreen extends StatefulWidget {
  @override
  _ApplePayScreenState createState() => _ApplePayScreenState();
}

class _ApplePayScreenState extends State<ApplePayScreen> {
  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return Center(
        child: Text('Apple pay only support iOS Device'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ApplePay'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'appId: ${appId.toString()}',
            textAlign: TextAlign.center,
          ),
          Text(
            'appKey: $appKey',
            textAlign: TextAlign.center,
          ),
          Text(
            'serverType: ${serverType == TappayServerType.sandBox ? 'sandBox' : 'production'}',
            textAlign: TextAlign.center,
          ),
          Container(
            color: Colors.blue,
            child: FlatButton(
              onPressed: () {
                Tappayflutterplugin.setupTappay(
                    appId: appId,
                    appKey: appKey,
                    serverType: TappayServerType.sandBox,
                    errorMessage: (error) {
                      print(error);
                    });
              },
              child: Text('Setup Tappay'),
            ),
          ),
          Container(
            color: Colors.blue,
            child: FlatButton(
              onPressed: () {
                Tappayflutterplugin.isApplePayAvailable();
              },
              child: Text('isApplePayAvailable'),
            ),
          ),
          Container(
            color: Colors.blue,
            child: FlatButton(
              onPressed: () async {
                await Tappayflutterplugin.prepareApplePay(
                  totalPrice: "12",
                  paymentTitle: 'TEST PAYMENT',
                  merchantName: 'TEST MERCHANT',
                  merchantId: "merchant.id",
                  currencyCode: 'TWD',
                  countryCode: 'TW',
                  merchantCapabilities: [
                    TPDApplePayMerchantCapability.capability3DS,
                  ],
                  allowedNetworks: [
                    TPDCardType.visa,
                    TPDCardType.masterCard,
                    TPDCardType.jcb,
                    TPDCardType.americanExpress,
                  ],
                  onError: (String errorMessage) {},
                );
              },
              child: Text('Prepare Apple pay'),
            ),
          ),
          Container(
            color: Colors.blue,
            child: FlatButton(
              onPressed: () async {
                // start pay
                await Tappayflutterplugin.startApplePay(
                  onSuccess: (prime) {
                    print("Get prime success: $prime");

                    // here need to request pay-by-prime api, usually by backend side
                    // and check the responce is successful or not
                    print("Do request pay-by-prime in some way");

                    bool isSuccessful = true;
                    print("The response is $isSuccessful");
                    // you can change isSuccessful true/false to simulate payment successful or failure
                    // it will show the state on apple pay dialog
                    print("Show the response $isSuccessful on apple pay dialog");
                    Tappayflutterplugin.showPaymentResult(isSuccessful);
                  },
                  onError: (errorMessage) {
                    print("errorMessage: $errorMessage");
                  },
                );
              },
              child: Text('Start Apple Pay'),
            ),
          ),
        ],
      ),
    );
  }
}
