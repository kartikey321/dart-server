import 'dart:io';

import 'package:server/services/router.dart';

import '../models/request.dart';
import '../models/response.dart';
import 'controller.dart';
import 'middleware..dart';

class RequestTypes {
  static const String GET = 'GET';
  static const String POST = 'POST';
  static const String PUT = 'PUT';
  static const String PATCH = 'PATCH';
  static const String DELETE = 'DELETE';
  static const String OPTIONS = 'OPTIONS';

  static const List<String> allTypes = [GET, POST, PUT, PATCH, DELETE, OPTIONS];
}

class DartExpress {
  final Router _router = Router();
  final List<MiddlewareHandler> _globalMiddleware = [];
  final DIContainer _container = DIContainer();

  void useController(String prefix, Controller controller) {
    controller.initialize(this, prefix: prefix);
  }

  void use(MiddlewareHandler middleware) {
    _globalMiddleware.add(middleware);
  }

  void get(String path, RequestHandler handler,
      {List<MiddlewareHandler>? middleware}) {
    _addRoute(RequestTypes.GET, path, handler, middleware: middleware);
  }

  void post(String path, RequestHandler handler,
      {List<MiddlewareHandler>? middleware}) {
    _addRoute(RequestTypes.POST, path, handler, middleware: middleware);
  }

  void put(String path, RequestHandler handler,
      {List<MiddlewareHandler>? middleware}) {
    _addRoute(RequestTypes.PUT, path, handler, middleware: middleware);
  }

  void patch(String path, RequestHandler handler,
      {List<MiddlewareHandler>? middleware}) {
    _addRoute(RequestTypes.PATCH, path, handler, middleware: middleware);
  }

  void delete(String path, RequestHandler handler,
      {List<MiddlewareHandler>? middleware}) {
    _addRoute(RequestTypes.DELETE, path, handler, middleware: middleware);
  }

  void options(String path, RequestHandler handler,
      {List<MiddlewareHandler>? middleware}) {
    _addRoute(RequestTypes.OPTIONS, path, handler, middleware: middleware);
  }

  void _addRoute(String method, String path, RequestHandler handler,
      {List<MiddlewareHandler>? middleware}) {
    final wrappedHandler = _wrapWithMiddleware(handler, middleware ?? []);
    _router.addRoute(method, path, wrappedHandler);
  }

  RequestHandler _wrapWithMiddleware(
      RequestHandler handler, List<MiddlewareHandler> routeMiddleware) {
    return (Request request, Response response) async {
      int globalIndex = 0;
      int routeIndex = 0;

      Future<void> runNextMiddleware() async {
        if (globalIndex < _globalMiddleware.length) {
          await _globalMiddleware[globalIndex++](
              request, response, runNextMiddleware);
        } else if (routeIndex < routeMiddleware.length) {
          await routeMiddleware[routeIndex++](
              request, response, runNextMiddleware);
        } else {
          await handler(request, response);
        }
      }

      await runNextMiddleware();
    };
  }

  void inject<T>(T instance) {
    _container.registerSingleton<T>(instance);
  }

  Future<void> listen(int port) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print('Server listening on port ${server.port}');

    await for (HttpRequest httpRequest in server) {
      await _handleRequest(httpRequest);
    }
  }

  Future<void> _handleRequest(HttpRequest httpRequest) async {
    final request = Request.from(httpRequest, container: _container);
    final response = Response();

    try {
      final handler = _router.findHandler(request.method, request.uri.path);
      if (handler != null) {
        await handler(request, response);
      } else {
        response.setStatus(HttpStatus.notFound);
        response.text('Not Found');
      }
    } catch (e, trace) {
      print('Error handling request: $e, trace:$trace');
      response.setStatus(HttpStatus.internalServerError);
      response.text('Internal Server Error');
    }

    if (!response.isSent) {
      response.send(httpRequest.response);
    }
  }

  MiddlewareHandler cors({
    List<String> allowedOrigins = const ['*'],
    List<String> allowedMethods = RequestTypes.allTypes,
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
}
