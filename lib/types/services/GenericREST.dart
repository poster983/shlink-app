import 'dart:convert';
import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shlink_app/types/JSONTypeConverters.dart';
import 'package:shlink_app/types/SupportedFeatures.dart';
import 'package:shlink_app/types/ShortUrl.dart';
import 'package:shlink_app/types/Domain.dart';
import 'package:shlink_app/types/services/Service.dart';
import 'package:shlink_app/types/services/ServiceType.dart';

part 'GenericREST.g.dart';

enum HTTPMethod { GET, POST }

enum ContentType { FormEncoded, JSON }

@JsonSerializable(nullable: false, anyMap: true)
class GenericREST implements Service {
  ServiceType get type => ServiceType.GenericREST;
  set type(t) => {}; // This is stupid.  Why is this required Json Serializable?

  String name;

  DateTime dayAdded;

  Uri host;

  @JsonKey(nullable: true)
  String customSlugParameter;

  //leave blank for plain text
  @JsonKey(nullable: true)
  String shortenedURLParameter; //in the response

  String longURLParameter;

  SupportedFeatures get features =>
      new SupportedFeatures(slug: (customSlugParameter != null) ? true : false);

  List<ShortUrl> historyCache;

  @JsonKey(nullable: true)
  Map<String, String> headers;

  @JsonKey(nullable: true)
  Map<String, String> reqBody;

  @JsonKey(nullable: true)
  Map<String, String> urlParameters;

  HTTPMethod httpMethod;

  ContentType contentType;

  bool disabled;

  @JsonKey(
      fromJson: JSONTypeConverters.colorFromJSON,
      toJson: JSONTypeConverters.colorToJSON)
  Color color;

  /*int __color;

  Color get color => new Color(__color);
  set color(v) => __color = v.value;

  ///DO NOT USE - FOR CONSTRUCTOR ONLY
  void __setColor(Color c) => color = c;*/

  GenericREST(this.host, this.name, this.longURLParameter, this.color,
      {this.headers,
      this.customSlugParameter,
      this.httpMethod = HTTPMethod.POST,
      this.urlParameters,
      this.reqBody,
      this.contentType = ContentType.JSON}) {
    dayAdded = new DateTime.now();
    historyCache = List<ShortUrl>();
    if (urlParameters == null) {
      urlParameters = Map<String, String>();
    }
    //__setColor(color);
  }

  @override
  String get apiKey => throw UnimplementedError();
  @override
  List<Domain> get domains => throw UnimplementedError();

  @override
  Future<List<ShortUrl>> history() async {
    return historyCache;
  }

  @override
  Future<bool> refreshHistory() async {
    // TODO: implement refreshHistory
    //throw UnimplementedError();
    return false;
  }

  @override
  Future<ShortUrl> shorten(Uri link, {String slug}) async {
    if (slug != null && slug.isNotEmpty && features.slug == false) {
      throw UnsupportedFeatureError("Slug not supported with this service");
    }

    //crewate internal query map
    Map<String, String> queryMap;
    if (urlParameters != null) {
      queryMap = new Map<String, String>.from(urlParameters);
    } else {
      queryMap = new Map<String, String>();
    }

    //Create internal body map
    Map<String, String> bodyMap;
    if (reqBody != null) {
      bodyMap = new Map<String, String>.from(reqBody);
    } else {
      bodyMap = new Map<String, String>();
    }

    if (httpMethod == HTTPMethod.GET) {
      queryMap[longURLParameter] = link.toString();
    } else {
      bodyMap[longURLParameter] = link.toString();
    }

    String queryString = Uri(queryParameters: queryMap).query;
    Uri url = Uri.parse(host.toString() + "?" + queryString);

    Response res;
    try {
      if (httpMethod == HTTPMethod.GET) {
        /* = host;
        url.queryParameters = urlParameters;
        params = params[longURLParameter]
         = */

        res = await http.get(url, headers: headers);
      } else {
        //create headers map
        Map<String, String> headersMap;
        if (headers != null) {
          headersMap = new Map<String, String>.from(headers);
        } else {
          headersMap = new Map<String, String>();
        }

        var body;
        if (contentType == ContentType.JSON) {
          headersMap["Content-Type"] = "application/json";
          body = json.encode(bodyMap);
        } else {
          body = bodyMap;
        }

        res = await http.post(url, headers: headersMap, body: body);
      }

      //check if response was valid
      if (res.statusCode == 201 || res.statusCode == 200) {
        Uri short = _parseShortenBody(res.body);
        ShortUrl shortUrl = new ShortUrl(
            dateCreated: DateTime.now(),
            longUrl: link,
            slug: (slug != null) ? slug : short.path,
            shortUrl: short,
            serviceType: ServiceType.GenericREST,
            serviceName: name);
        print(shortUrl.toJson());
        historyCache.add(shortUrl);
        try {
          var historyBox = Hive.box<ShortUrl>("history");
          historyBox.put(shortUrl.shortUrl.toString(), shortUrl);
        } catch (e) {
          throw e;
        }

        return shortUrl;
      } else {
        throw Exception(res.body);
      }
      print(res);
    } catch (err) {
      print(err);
      throw err;
    }
  }

  Uri _parseShortenBody(String body) {
    //parse plaintext
    if (shortenedURLParameter == null) {
      try {
        return Uri.parse(body);
      } catch (e) {
        throw e;
      }
    } else {
      return null;
    }
  }

  factory GenericREST.fromJson(Map<String, dynamic> json) =>
      _$GenericRESTFromJson(json);
  Map<String, dynamic> toJson() => _$GenericRESTToJson(this);
}
