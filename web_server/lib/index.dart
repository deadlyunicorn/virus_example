import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final Handler handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);
  final HttpServer server = await shelf_io.serve(handler, 'localhost', 8080);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}

Response _echoRequest(Request request) {
  if (request.url.path == "api/command") {
    print("SUCCESS");
    return Response.ok(jsonEncode(
      {
        0: 5,
        1: 10,
      },
    ));
  } else {
    return Response.notFound("Resource not found.");
  }
}
