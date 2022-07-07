import 'package:flutter/foundation.dart';

class Log {
  static void d(dynamic msg) {
    if (kDebugMode) {
      print("$msg");
    }
  }
}
