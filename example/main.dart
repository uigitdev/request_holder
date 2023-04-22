import 'package:flutter/material.dart';
import 'package:uigitdev_request_holder/src/http_request_holder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _postDataBuilder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _postDataBuilder() {
    return FutureBuilder<PostModel?>(
      future: PostRequest(id: 1).send(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return Text(snapshot.data!.title.toString());
          } else {
            if (snapshot.hasError) {
              if (snapshot.error is HTTPRequestHolderErrorResponse) {
                final error = snapshot.error as HTTPRequestHolderErrorResponse;
                return Text('statusCode: ${error.statusCode}\nbody: ${error.body}');
              }
              return Text('Error: ${snapshot.error}');
            } else {
              return const Text('No data');
            }
          }
        } else {
          return const Text('Loading');
        }
      },
    );
  }
}

class PostModel {
  int? userId;
  int? id;
  String? title;
  String? body;

  PostModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    id = json['id'];
    title = json['title'];
    body = json['body'];
  }
}

class PostRequest extends HTTPRequestHolder<PostModel> {
  final int id;

  PostRequest({required this.id});

  @override
  HTTPRequestProtocol get protocol => HTTPRequestProtocol.HTTP;

  @override
  String get host => 'jsonplaceholder.typicode.com';

  @override
  String get path => '/posts/$id';

  @override
  HTTPRequestMethod get method => HTTPRequestMethod.GET;

  @override
  JSONParserType get parserType => JSONParserType.MAP;

  @override
  JSONMapParser<PostModel>? get mapParser => PostModel.fromJson;

  @override
  HTTPRequestHolderSettings get settings {
    return HTTPRequestHolderSettings(
      isDebugPrint: true,
    );
  }

  @override
  HTTPRequestHolderDummyResponse? get dummyResponse {
    return HTTPRequestHolderDummyResponse(
      isDummyResponse: false,
      duration: const Duration(seconds: 2),
      json: {
        "userId": 1,
        "id": 1,
        "title": "Dummy title response",
        "body": "Use this function if you want to see dummy data.",
      },
      dummyErrorResponse: HTTPRequestHolderDummyErrorResponse(
        isDummyErrorResponse: false,
        error: HTTPRequestHolderErrorResponse(
          statusCode: 404,
          body: {
            'error': 'Dummy error response',
          },
        ),
      ),
    );
  }
}
