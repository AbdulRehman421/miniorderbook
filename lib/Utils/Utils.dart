import 'package:flutter/foundation.dart';

class Utils {
  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  static void dTPrint(data) {
    if (kDebugMode) {
      print(data);
    }
  }

  static String getTimestamp() {
    var time =
        ((DateTime.now().millisecondsSinceEpoch) / 1000).toStringAsFixed(0);
    return time;
  }

  static String generateInvoiceId(String lastId) {
    DateTime now = DateTime.now();
    var year = now.year.toString().substring(2, 4);
    var month = now.month.toString();

    if (int.parse(month) < 10) {
      month = "0" + month;
    }

    if (int.parse(lastId) < 10) {
      lastId = "000" + lastId;
    } else if (int.parse(lastId) < 100) {
      lastId = "00" + lastId;
    } else if (int.parse(lastId) < 1000) {
      lastId = "0" + lastId;
    }

    return year + month.toString() + (lastId).toString();
  }
}
