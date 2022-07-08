import 'package:flutter/material.dart';
import 'package:tappayflutterplugin/tappayflutterplugin.dart';

import 'constant.dart';

class GooglePayScreen extends StatefulWidget {
  @override
  _GooglePayScreenState createState() => _GooglePayScreenState();
}

class _GooglePayScreenState extends State<GooglePayScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GooglePay'),
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
              onPressed: () async {
                bool isPrepared = await Tappayflutterplugin.preparePaymentData(
                  allowedNetworks: [
                    TPDCardType.masterCard,
                    TPDCardType.jcb,
                    TPDCardType.visa,
                  ],
                  allowedAuthMethods: [
                    TPDCardAuthMethod.panOnly,
                    TPDCardAuthMethod.cryptogram3ds,
                  ],
                  merchantName: 'TEST MERCHANT',
                  isShippingAddressRequired: false,
                  isEmailRequired: false,
                  isPhoneNumberRequired: false,
                );
                print("preparePaymentData: $isPrepared");
              },
              child: Text('Prepare google pay'),
            ),
          ),
          Container(
            color: Colors.blue,
            child: FlatButton(
              onPressed: () async {
                await Tappayflutterplugin.requestPaymentData(
                  totalPrice: '1',
                  currencyCode: 'TWD',
                  onSuccess: (result) {
                    print('requestPaymentData is success, now you can get google pay prime');
                    print('result: $result');
                  },
                  onError: (message) {
                    print('requestPaymentData is error');
                    print('message: $message');
                  },
                );
              },
              child: Text('Request payment data'),
            ),
          ),
          Container(
            color: Colors.blue,
            child: FlatButton(
              onPressed: () async {
                await Tappayflutterplugin.getGooglePayPrime(
                  onSuccess: (prime) {
                    print('getGooglePayPrime is success, prime: $prime');
                  },
                  onError: (message) {
                    print('getGooglePayPrime is error, message: $message');
                  },
                );
              },
              child: Text('Get google pay prime'),
            ),
          ),
        ],
      ),
    );
  }
}
