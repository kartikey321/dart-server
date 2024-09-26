import 'package:server/services/middleware..dart';

class Router {
  final Map<String, Map<String, RequestHandler>> _routes = {};

  void addRoute(String method, String path, RequestHandler handler) {
    _routes.putIfAbsent(method, () => {})[path] = handler;
  }

  RequestHandler? findHandler(String method, String path) {
    return _routes[method]?[path];
  }
}
