import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';

class ConstantWidget {
  static String format="FORMAT";
  static String height="Height";
  static String width="width";
  static Widget NotFoundWidget(BuildContext context, title) {
    return Center(
      child: Container(
        child: Column(
          children: [
            Lottie.asset(kIsWeb ? 'not_found.json' : 'assets/not_found.json'),
             Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
  static Widget SmallWarningWidget(BuildContext context) {
    return Center(
      child: Container(
        child: Column(
          children: [
            Lottie.asset(kIsWeb ? 'warning.json' : 'assets/warning.json',width: 85,height: 85),
          ],
        ),
      ),
    );
  }
  static Widget SmallNoInternetWidget(BuildContext context) {
    return Center(
      child: Container(
        child: Column(
          children: [
            Lottie.asset(kIsWeb ? 'no_internet.json' : 'assets/no_internet.json',width: 85,height: 85),
          ],
        ),
      ),
    );
  }


}
