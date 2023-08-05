// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:developer';
import 'package:uigitdev_request_holder/src/http_request_holder.dart';

enum _JSONRequestResponseType { JSON_REQUEST_RESPONSE, NO_JSON_RESPONSE_PARSER }

abstract class JSONRequestHolder<T> {
  /// Select [parserType]. [LIST] or [MAP]
  JSONParserType get parserType;

  /// Use it if your [parserType] was [MAP].
  /// If you do not fill it in, you will see a warning on the console.
  JSONMapParser<T>? get mapParser => null;

  /// Use it if your [parserType] was [LIST].
  /// If you do not fill it in, you will see a warning on the console.
  JSONListParser<T>? get listParser => null;

  Future<Object> get jsonResponse;

  /// You can turn of [debugPrint].
  JSONRequestHolderSettings get settings => JSONRequestHolderSettings();

  /// Use it if you want to send your request. [async] method which will return your type [T] if the process was successful.
  /// In case of failure, null or error is returned.
  /// The console indicates the logs.
  Future<T?> send() async {
    if (_isParserExists()) {
      final body = jsonEncode(await jsonResponse);
      final json = await jsonDecode(body);

      if (settings.isDebugPrint) {
        log(
            '✅ ${_JSONRequestResponseType.JSON_REQUEST_RESPONSE.name}($T):\n$json');
      }

      return _responseParser(json);
    } else {
      if (settings.isDebugPrint) {
        log(
            '⚠️ ${_JSONRequestResponseType.NO_JSON_RESPONSE_PARSER.name}($T): Missing "${parserType.name.toLowerCase()}Parser" method.');
      }
      return Future.error(
          Error.safeToString(_JSONRequestResponseType.NO_JSON_RESPONSE_PARSER.name));
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

  T? _responseParser(dynamic json) {
    switch (parserType) {
      case JSONParserType.LIST:
        return listParser!(json);
      case JSONParserType.MAP:
        return mapParser!(json);
    }
  }
}

class JSONRequestHolderSettings extends HTTPRequestHolderSettings {
  JSONRequestHolderSettings({super.isDebugPrint});
}
