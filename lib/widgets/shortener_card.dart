import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share/share.dart';
import 'package:shlink_app/common.dart';
import 'package:shlink_app/controllers/AppController.dart';
import 'package:shlink_app/widgets/service_chooser.dart';
import 'package:shlink_app/widgets/shorten_button.dart';

/// A Card for shortning URLS
class ShortenerCard extends StatefulWidget {
  ShortenerCard({Key key}) : super(key: key);

  @override
  _ShortenerCardState createState() => _ShortenerCardState();
}

class _ShortenerCardState extends State<ShortenerCard> {
  final AppController controller = Get.find();
  final _formKey = GlobalKey<FormState>();
  var _longURLControll = new TextEditingController();
  var _longURLFocus = new FocusNode();
  bool isLoading = false;
  String shortURL = "";

  var _urlProtocall = "";

  /// Gets the clipboard data from the
  /// [onlyValid] if set to true it will only paste if the URL is valid
  ///
  void pasteClipboardURL({bool onlyValid}) {
    Clipboard.getData('text/plain').then((clipboard) {
      var res = validateURL(clipboard.text);
      if (onlyValid != null && onlyValid) {
        if (res == null) {
          _longURLControll.text = clipboard.text;
          setState(() {});
        }
      } else {
        _longURLControll.text = clipboard.text;
        setState(() {});
      }
    });
  }

  String validateURL(value) {
    if (!value.isEmpty) {
      var url = Uri.parse(value);
      var host = (url.host.isEmpty)
          ? value
          : url
              .host; // The parser puts the host in the scheme if no scheme is found. But we need the host all the time
      if (!GetUtils.isURL(host)) {
        _urlProtocall = "";
        return "Invalid URL";
      } else {
        //If the url is valid, but has no protocall then add it to the prefix
        if (!url.hasScheme) {
          _urlProtocall = "http://";
        } else {
          _urlProtocall = "";
        }
      }
      return null;
    }
    return "URL cannot be empty";
  }

  _ShortenerCardState() {
    pasteClipboardURL(onlyValid: true);
    _longURLFocus.addListener(() {
      // Detect focus change for Long URL Textbox
      if (!_longURLFocus.hasFocus) {
        setState(() {}); // update widget state for HTTP
      }
    });
  }

  void submit() {
    if (_formKey.currentState.validate()) {
      if (controller.serviceList.elementAt(controller.selectedService.value) !=
          null) {
        showSnackBar(text: "Shortening");
        setState(() {
          isLoading = true;
        });
        
        controller.serviceList
          .elementAt(controller.selectedService.value)
          .shorten(Uri.parse(_longURLControll.text))
          .then((value) {
            setState(() {
              isLoading = false;
            });
            print(value.shortUrl);
            shortURL = value.shortUrl.toString();
            Share.share(shortURL);

          })
          .catchError((err) {
            showSnackBar(text: "There was an error");
            setState(() {
              isLoading = false;
            });
            throw err;
          });
        
      } else {
        print("Service list empty");
        
      }
    } else {
      print("INVALID FORM");
      
    }
    
  }

  @override
  void dispose() {
    _longURLFocus.dispose();
    _longURLControll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(
          color: Theme.of(context).accentColor,
          width: 2,
        ),
      ),
      child: Form(
          key: _formKey,
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        /*** LONG URL  */

                        new TextFormField(
                          validator: (v) => validateURL(v),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            prefix: new GestureDetector(
                              // Protocall prefix.  Tap to remove
                              child: new Text(_urlProtocall),
                              onTap: () {
                                setState(() {
                                  _urlProtocall = "";
                                });
                              },
                            ),
                            icon: Icon(Icons.link),
                            suffixIcon: new Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // add buttons to input
                                  new IconButton(
                                      icon: Icon(Icons.paste),
                                      onPressed: () => pasteClipboardURL()),
                                  new IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        _urlProtocall = "";
                                        _longURLControll.clear();
                                        setState(() {});
                                      }), // clear
                                ]),
                            labelText: 'Long URL',
                          ),
                          onChanged: (val) {},
                          //autofocus: true,
                          autocorrect: false,
                          controller: _longURLControll,
                          autovalidate: true,
                          focusNode: _longURLFocus,
                          //onFieldSubmitted: (v) { setState((){});}
                        ),

                        /** SERVICE AND CUSTOM PATH  */

                        new Row(
                          children: [
                            // Service picker and custom route textbox
                            new Flexible(child: new ServiceChooser()),
                            new SizedBox(width: 5),
                            new Flexible(
                                child: new TextFormField(
                                    // Custom Path
                                    decoration: InputDecoration(
                              prefix: new Text("/"),
                              labelText: 'Custom Path (Optional)',
                              //suffixIcon:
                            )))
                          ],
                        ),

                        /** ADVANCED OPTIONS */

                        /** SUBMIT AND GET LINK */
                        new SizedBox(height: 10),
                        new ShortenButton(onPressed: submit, loading: isLoading),
                        new SizedBox(height: 10),
                        new Text("Short URL: " + shortURL)

                      ])))),
    );
  }
}
