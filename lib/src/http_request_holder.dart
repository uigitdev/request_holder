// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

typedef JSONMapParser<T> = T Function(Map<String, dynamic>);

typedef JSONListParser<T> = T Function(List<dynamic>);

enum JSONParserType { LIST, MAP }

enum HTTPRequestProtocol { HTTP, HTTPS }

enum HTTPRequestMethod { GET, POST, PUT, PATCH, DELETE }

enum _HTTPRequestResponseType {
  REAL_HTTP_REQUEST_RESPONSE,
  DUMMY_HTTP_REQUEST_RESPONSE,
  DUMMY_HTTP_REQUEST_ERROR_RESPONSE,
  NO_HTTP_RESPONSE_PARSER
}

abstract class HTTPRequestHolder<T> {
  /// Add request [host], do not include www and http or https.
  /// Correct: uigitdev.com
  String get host;

  /// Add request [path].
  /// Correct: /posts
  String get path;

  /// Select [protocol]. [HTTP] or [HTTPS]
  HTTPRequestProtocol get protocol;

  /// Select [method]. [GET], [POST], [PUT], [PATCH], [DELETE]
  HTTPRequestMethod get method;

  /// Add [queryParams].
  Map<String, dynamic> get queryParams => {};

  /// Add [headers].
  Map<String, dynamic> get headers => {};

  /// Add [requestBody].
  dynamic get requestBody => {};

  /// You can turn of [debugPrint].
  HTTPRequestHolderSettings get settings => HTTPRequestHolderSettings();

  ///Test the responses with dummy data if you know the JSON structure.
  HTTPRequestHolderDummyResponse? dummyResponse;

  /// Select [parserType]. [LIST] or [MAP]
  JSONParserType get parserType;

  /// Use it if your [parserType] was [MAP].
  /// If you do not fill it in, you will see a warning on the console.
  JSONMapParser<T>? get mapParser => null;

  /// Use it if your [parserType] was [LIST].
  /// If you do not fill it in, you will see a warning on the console.
  JSONListParser<T>? get listParser => null;

  /// Use it if you want to send your request. [async] method which will return your type [T] if the process was successful.
  /// In case of failure, null or error is returned.
  /// The console indicates the logs.
  Future<T?> send() async {
    if (_isParserExists()) {
      if (dummyResponse != null && dummyResponse!.isDummyResponse) {
        return await _dummyResponseProcessing();
      } else {
        final response = await _requestByMethod(
          method: method,
          uri: _createUri(),
          headers: _createStringHeaders(),
          body: jsonEncode(requestBody),
        );
        return await _responseProcessing(response);
      }
    } else {
      if (settings.isDebugPrint) {
        log(
            '⚠️ ${_HTTPRequestResponseType.NO_HTTP_RESPONSE_PARSER.name}($T): Missing "${parserType.name.toLowerCase()}Parser" method.');
      }
      return Future.error(
          Error.safeToString(_HTTPRequestResponseType.NO_HTTP_RESPONSE_PARSER.name));
    }
  }

  bool _isParserExists() {
    switch (parserType) {
      case JSONParserType.LIST:
        return listParser != null;
      case JSONParserType.MAP:
        return mapParser != null;
    }
  }

  Future<T?> _dummyResponseProcessing() async {
    await Future.delayed(dummyResponse!.duration);

    if (dummyResponse!.dummyErrorResponse != null &&
        dummyResponse!.dummyErrorResponse!.isDummyErrorResponse) {
      if (settings.isDebugPrint) {
        log(
            '⛔ ${_HTTPRequestResponseType.DUMMY_HTTP_REQUEST_ERROR_RESPONSE.name}($T):\n${dummyResponse!.dummyErrorResponse!.error}');
      }
      return Future.error(dummyResponse!.dummyErrorResponse!.error);
    } else {
      if (settings.isDebugPrint) {
        log(
            '⚠️ ${_HTTPRequestResponseType.DUMMY_HTTP_REQUEST_RESPONSE.name}($T):\n${dummyResponse!.json}');
      }
      return _responseParser(dummyResponse!.json);
    }
  }

  Future<T?> _responseProcessing(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (settings.isDebugPrint) {
        log(
            '✅ ${_HTTPRequestResponseType.REAL_HTTP_REQUEST_RESPONSE.name}($T):\n${response.body}');
      }

      final json = await jsonDecode(response.body);
      return _responseParser(json);
    } else {
      return Future.error(HTTPRequestHolderErrorResponse(
        statusCode: response.statusCode,
        body: response.body,
      ));
    }
  }

  T? _responseParser(dynamic json) {
    switch (parserType) {
      case JSONParserType.LIST:
        return listParser!(json);
      case JSONParserType.MAP:
        return mapParser!(json);
    }
  }

  Map<String, String> _createStringHeaders() {
    final stringHeaders = <String, String>{};
    stringHeaders['Content-Type'] = 'application/json';

    headers.forEach((key, value) {
      stringHeaders[key] = value;
    });

    return stringHeaders;
  }

  Uri _createUri() {
    return Uri(
      scheme: protocol.name.toLowerCase(),
      host: host,
      path: path,
      queryParameters: queryParams,
    );
  }

  Future<http.Response> _requestByMethod(
      {required HTTPRequestMethod method,
      required Uri uri,
      required Map<String, String> headers,
      required String body}) async {
    switch (method) {
      case HTTPRequestMethod.GET:
        return await http.get(uri, headers: headers);
      case HTTPRequestMethod.POST:
        return await http.post(uri, headers: headers, body: body);
      case HTTPRequestMethod.PUT:
        return await http.put(uri, headers: headers, body: body);
      case HTTPRequestMethod.PATCH:
        return await http.patch(uri, headers: headers, body: body);
      case HTTPRequestMethod.DELETE:
        return await http.delete(uri, headers: headers, body: body);
    }
  }
}

class HTTPRequestHolderSettings {
  final bool isDebugPrint;

  HTTPRequestHolderSettings({this.isDebugPrint = true});
}

class HTTPRequestHolderDummyResponse {
  final bool isDummyResponse;
  final Duration duration;
  final Object json;
  final HTTPRequestHolderDummyErrorResponse? dummyErrorResponse;

  HTTPRequestHolderDummyResponse({
    required this.isDummyResponse,
    required this.duration,
    required this.json,
    this.dummyErrorResponse,
  });
}

class HTTPRequestHolderDummyErrorResponse {
  final bool isDummyErrorResponse;
  final Object error;

  HTTPRequestHolderDummyErrorResponse({
    required this.isDummyErrorResponse,
    required this.error,
  });
}

class HTTPRequestHolderErrorResponse {
  final int statusCode;
  final Object body;

  HTTPRequestHolderErrorResponse({
    required this.statusCode,
    required this.body,
  });
}
