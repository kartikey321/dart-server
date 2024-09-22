import 'dart:convert';
import 'dart:io';

import 'package:server/models/request.dart';
import 'package:server/models/response.dart';

void addCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type');
}

void main() async {
  int counter = 0;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('Server listening on localhost:${server.port}');

  await for (HttpRequest request1 in server) {
    addCorsHeaders(request1.response);
    print('Received ${request1.method} request for ${request1.uri.path}');

    // Increment the counter once per request
    counter++;
    print('Counter incremented to $counter');

    if (request1.method == 'GET') {
      // Match the URL against the route pattern
      final request = await Request.from(request1, routePattern: 'users/:id');
      print(request.params);
      print(request1.uri.path);
      print(request.query);

      if (request.params.containsKey('id') &&
          request1.uri.path.startsWith('/users')) {
        final userId = request.params['id'];
        final Response response = Response.json({
          "message": "Hi Dart Devs",
          "counter": counter,
          "id": userId,
        });

        // Write the response
        response.write(request1.response);
      } else if (request1.uri.path == '/') {
        // Handle the default root path
        final Response response = Response.json(
            {"message": "Welcome to the Dart server!", "counter": counter});
        response.write(request1.response);
      } else if (request1.uri.path.startsWith('/search')) {
        // Example query handling
        final queryParam = request.query['q'];
        if (queryParam != null && queryParam.isNotEmpty) {
          final Response response = Response.json({
            "message": "Search results for: $queryParam",
            "counter": counter
          });
          response.write(request1.response);
        } else {
          final Response response = Response.raw(
              statusCode: HttpStatus.badRequest,
              body: 'Query parameter "q" is required')
            ..write(request1.response);
        }
      } else {
        // Respond with 404 if the route pattern doesn't match
        final Response response =
            Response.raw(statusCode: HttpStatus.notFound, body: 'Not Found')
              ..write(request1.response);
      }
    } else {
      // Handle non-GET requests
      final Response response = Response.raw(
          statusCode: HttpStatus.methodNotAllowed, body: 'Method Not Allowed')
        ..write(request1.response);
    }
  }
}
