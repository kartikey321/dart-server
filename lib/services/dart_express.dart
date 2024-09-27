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
  final List<Middleware> _middleware = [];
  final DIContainer _container = DIContainer();
  void useController(Controller controller) {
    controller.registerRoutes(this);
  }

  void use(String path, MiddlewareFunction middleware) {
    _middleware.add(Middleware(path, middleware));
  }

  void get(String path, RequestHandler handler) {
    _router.addRoute(RequestTypes.GET, path, handler);
  }

  void post(String path, RequestHandler handler) {
    _router.addRoute(RequestTypes.POST, path, handler);
  }

  void put(String path, RequestHandler handler) {
    _router.addRoute(RequestTypes.PUT, path, handler);
  }

  void patch(String path, RequestHandler handler) {
    _router.addRoute(RequestTypes.PATCH, path, handler);
  }

  void delete(String path, RequestHandler handler) {
    _router.addRoute(RequestTypes.DELETE, path, handler);
  }

  void options(String path, RequestHandler handler) {
    _router.addRoute(RequestTypes.OPTIONS, path, handler);
  }

  // Add other HTTP methods as needed

  void inject<T>(T instance) {
    _container.registerSingleton<T>(instance);
  }

  Future<void> _applyMiddleware(Request request, Response response) async {
    for (var middleware in _middleware) {
      if (request.uri.path.startsWith(middleware.path)) {
        bool next = false;
        await middleware.handler(request, response, () => next = true);
        if (!next) break;
      }
    }
  }

  Future<void> listen(int port) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print('Server listening on port ${server.port}');

    await for (HttpRequest httpRequest in server) {
      await _handleRequest(httpRequest);
    }
  }

  MiddlewareFunction cors({
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

  Future<void> _handleRequest(HttpRequest httpRequest) async {
    final request = Request.from(httpRequest, container: _container);
    final response = Response();

    try {
      await _applyMiddleware(request, response);

      if (!response.isSent) {
        final handler = _router.findHandler(request.method, request.uri.path);
        if (handler != null) {
          await handler(request, response);
        } else {
          response.setStatus(HttpStatus.notFound);
          response.text('Not Found');
        }
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
}
