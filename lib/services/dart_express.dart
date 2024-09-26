import 'dart:io';

import 'package:server/services/router.dart';

import '../models/request.dart';
import '../models/response.dart';
import 'middleware..dart';

class DartExpress {
  final Router _router = Router();
  final List<Middleware> _middleware = [];
  final DIContainer _container = DIContainer();

  void use(Middleware middleware) {
    _middleware.add(middleware);
  }

  void get(String path, RequestHandler handler) {
    _router.addRoute('GET', path, handler);
  }

  void post(String path, RequestHandler handler) {
    _router.addRoute('POST', path, handler);
  }

  // Add other HTTP methods as needed

  void inject<T>(T instance) {
    _container.register<T>(instance);
  }

  Future<void> _applyMiddleware(Request request, Response response,
      List<Middleware> middlewares, int index) async {
    if (index >= middlewares.length && response.isSent) return;

    await middlewares[index](request, response, () async {
      await _applyMiddleware(request, response, middlewares, index + 1);
    });
  }

  Future<void> listen(int port) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print('Server listening on port ${server.port}');

    await for (HttpRequest httpRequest in server) {
      await _handleRequest(httpRequest);
    }
  }

  Middleware cors({
    List<String> allowedOrigins = const ['*'],
    List<String> allowedMethods = const [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'OPTIONS'
    ],
    List<String> allowedHeaders = const ['Content-Type', 'Authorization'],
    bool allowCredentials = false,
    int maxAge = 86400,
  }) {
    return (request, response, next) async {
      final origin = request.headers.value('Origin');
      if (origin != null &&
          (allowedOrigins.contains('*') || allowedOrigins.contains(origin))) {
        response.setHeader('Access-Control-Allow-Origin', origin);
        response.setHeader(
            'Access-Control-Allow-Methods', allowedMethods.join(', '));
        response.setHeader(
            'Access-Control-Allow-Headers', allowedHeaders.join(', '));
        response.setHeader('Access-Control-Max-Age', maxAge.toString());

        if (allowCredentials) {
          response.setHeader('Access-Control-Allow-Credentials', 'true');
        }

        if (request.method == 'OPTIONS') {
          response.setStatus(204);
          response.send(request.httpRequest.response);
          return;
        }
      }
      await next();
    };
  }

  Future<void> _handleRequest(HttpRequest httpRequest) async {
    final request = Request.from(httpRequest, container: _container);
    final response = Response();

    try {
      // Apply middleware
      await _applyMiddleware(request, response, _middleware, 0);

      // If response hasn't been sent by middleware, try to route the request
      if (!response.isSent) {
        final handler = _router.findHandler(request.method, request.uri.path);
        if (handler != null) {
          await handler(request, response);
        } else {
          response.setStatus(HttpStatus.notFound);
          response.text('Not Found');
        }
      }
    } catch (e) {
      print('Error handling request: $e');
      response.setStatus(HttpStatus.internalServerError);
      response.text('Internal Server Error');
    }

    // Send the response if it hasn't been sent yet
    if (!response.isSent) {
      response.send(httpRequest.response);
    }
  }

  Future<void> _sendResponse(HttpRequest httpRequest, Response response) async {
    response.send(httpRequest.response);
  }
}
