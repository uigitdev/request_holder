import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

typedef JSONMapParser<T> = T Function(Map<String, dynamic>);

typedef JSONListParser<T> = T Function(List<dynamic>);

// ignore: constant_identifier_names
enum JSONParserType { LIST, MAP }

// ignore: constant_identifier_names
enum HTTPRequestProtocol { HTTP, HTTPS }

// ignore: constant_identifier_names
enum HTTPRequestMethod { GET, POST, PUT, PATCH, DELETE }

// ignore: constant_identifier_names
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
  Map<String, dynamic> get requestBody => {};

  /// You can turn of [debugPrint] and test the responses with dummy data if you know the JSON structure.
  HTTPRequestHolderSettings get settings => HTTPRequestHolderSettings();

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
      if (settings.dummyResponse != null &&
          settings.dummyResponse!.isDummyResponse) {
        return await _dummyResponseProcessing();
      } else {
        final clientRequest = await _requestByMethod(method, _createUri());
        _setClientRequestSettings(clientRequest);
        _setHeaders(clientRequest);
        _setRequestBody(clientRequest);

        final HttpClientRequest request = await clientRequest.flush();
        return await _responseProcessing(await request.close());
      }
    } else {
      if (settings.isDebugPrint) {
        debugPrint(
            '⚠️ ${_HTTPRequestResponseType.NO_HTTP_RESPONSE_PARSER.name}($T): Missing "${parserType.name.toLowerCase()}Parser" method in "$T" class.');
      }
      return Future.error(
          ErrorHint(_HTTPRequestResponseType.NO_HTTP_RESPONSE_PARSER.name));
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
    await Future.delayed(settings.dummyResponse!.duration);

    if (settings.dummyResponse!.dummyErrorResponse != null &&
        settings.dummyResponse!.dummyErrorResponse!.isDummyErrorResponse) {
      if (settings.isDebugPrint) {
        debugPrint(
            '⛔ ${_HTTPRequestResponseType.DUMMY_HTTP_REQUEST_ERROR_RESPONSE.name}($T):\n${settings.dummyResponse!.dummyErrorResponse!.error}');
      }
      return Future.error(settings.dummyResponse!.dummyErrorResponse!.error);
    } else {
      if (settings.isDebugPrint) {
        debugPrint(
            '⚠️ ${_HTTPRequestResponseType.DUMMY_HTTP_REQUEST_RESPONSE.name}($T):\n${settings.dummyResponse!.json}');
      }
      return _responseParser(settings.dummyResponse!.json);
    }
  }

  Future<T?> _responseProcessing(HttpClientResponse response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final content = StringBuffer();

      await for (var data in response.transform(utf8.decoder)) {
        content.write(data);
      }

      if (settings.isDebugPrint) {
        debugPrint(
            '✅ ${_HTTPRequestResponseType.REAL_HTTP_REQUEST_RESPONSE.name}($T):\n$content');
      }

      final json = await jsonDecode(content.toString());
      return _responseParser(json);
    }
    return null;
  }

  T? _responseParser(dynamic json) {
    switch (parserType) {
      case JSONParserType.LIST:
        return listParser!(json);
      case JSONParserType.MAP:
        return mapParser!(json);
    }
  }

  void _setClientRequestSettings(HttpClientRequest clientRequest) {
    clientRequest.headers.contentType = ContentType.json;
  }

  void _setRequestBody(HttpClientRequest clientRequest) {
    final requestBodyString = jsonEncode(requestBody);
    clientRequest.headers.contentLength = requestBodyString.length;
    clientRequest.write(requestBodyString);
  }

  void _setHeaders(HttpClientRequest clientRequest) {
    headers.forEach((key, value) {
      clientRequest.headers.set(key, value);
    });
  }

  Uri _createUri() {
    return Uri(
      scheme: protocol.name.toLowerCase(),
      host: host,
      path: path,
      queryParameters: queryParams,
    );
  }

  Future<HttpClientRequest> _requestByMethod(
      HTTPRequestMethod method, Uri uri) async {
    switch (method) {
      case HTTPRequestMethod.GET:
        return await HttpClient().getUrl(uri);
      case HTTPRequestMethod.POST:
        return await HttpClient().postUrl(uri);
      case HTTPRequestMethod.PUT:
        return await HttpClient().putUrl(uri);
      case HTTPRequestMethod.PATCH:
        return await HttpClient().patchUrl(uri);
      case HTTPRequestMethod.DELETE:
        return await HttpClient().deleteUrl(uri);
    }
  }
}

class HTTPRequestHolderSettings {
  final bool isDebugPrint;
  final HTTPRequestHolderDummyResponse? dummyResponse;

  HTTPRequestHolderSettings({
    this.isDebugPrint = true,
    this.dummyResponse,
  });
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
