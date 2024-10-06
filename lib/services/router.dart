import 'middleware..dart';

// Router Class
class Router {
  final List<RouteEntry> _routes = [];

  void addRoute(String method, String path, RequestHandler handler) {
    final segments = _normalizePath(path);
    _routes.add(RouteEntry(method, segments, handler));
  }

  RequestHandler? findHandler(String method, String path) {
    final pathSegments = _normalizePath(path);
    for (var route in _routes) {
      if (route.method == method && route.matches(pathSegments)) {
        return (request, response) {
          request.params = route.extractParams(pathSegments);
          return route.handler(request, response);
        };
      }
    }
    return null;
  }

  List<String> _normalizePath(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty).toList();
  }
}

class RouteEntry {
  final String method;
  final List<String> segments;
  final RequestHandler handler;

  RouteEntry(this.method, this.segments, this.handler);

  bool matches(List<String> pathSegments) {
    if (segments.length != pathSegments.length) return false;
    for (var i = 0; i < segments.length; i++) {
      if (!segments[i].startsWith(':') && segments[i] != pathSegments[i]) {
        return false;
      }
    }
    return true;
  }

  Map<String, String> extractParams(List<String> pathSegments) {
    var params = <String, String>{};
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].startsWith(':')) {
        params[segments[i].substring(1)] = pathSegments[i];
      }
    }
    return params;
  }
}
