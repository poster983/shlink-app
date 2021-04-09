import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shlink_app/Services.dart';
import 'package:shlink_app/widgets/history/history_list.dart';
import 'package:shlink_app/widgets/shortish_text_logo.dart';

class HistoryView extends StatelessWidget {
  double maxWidth = 1000;
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    //super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      /*mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,*/
      children: [
        Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.only(top: 35, bottom: 25, left: 50, right: 50),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ShortishTextLogo(
                    style: TextStyle(fontSize: (Get.width > 400)?50:25),
                    after: " /history",
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: new IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        Services.updateHistory();
                      }),
                )
              ],
            )),
        Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.only(left: 25, right: 25),
            child: new HistoryList())
      ],
    );
  }
}
