import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

// Server State
class ServerState {
  final Map<String, dynamic> cache = {};
  final Map<String, Session> sessions = {};
}

// Session Management
class Session {
  final String id;
  final Map<String, dynamic> data = {};
  final DateTime createdAt;

  Session(this.id) : createdAt = DateTime.now();
}

// Request class
class Request {
  final HttpRequest httpRequest;
  final Map<String, String> params;
  final Map<String, String> query;
  final Session session;

  Request(this.httpRequest, this.params, this.query, this.session);

  Future<dynamic> body() async {
    final contentType = httpRequest.headers.contentType;
    final body = await utf8.decoder.bind(httpRequest).join();

    if (contentType?.mimeType == 'application/json') {
      return jsonDecode(body);
    } else if (contentType?.mimeType == 'application/xml') {
      return XmlDocument.parse(body);
    } else if (contentType?.mimeType == 'text/html') {
      return body;
    } else {
      return body;
    }
  }
}

// Response class
class Response {
  int statusCode = 200;
  String body = '';
  Map<String, String> headers = {};

  void json(dynamic data) {
    body = jsonEncode(data);
    headers['Content-Type'] = 'application/json';
  }

  void text(String data) {
    body = data;
    headers['Content-Type'] = 'text/plain';
  }

  void html(String data) {
    body = data;
    headers['Content-Type'] = 'text/html';
  }

  void xml(XmlDocument data) {
    body = data.toString();
    headers['Content-Type'] = 'application/xml';
  }
}

// Router class
class Router {
  final Map<String, Map<String, Function(Request, Response)>> routes = {
    'GET': {},
    'POST': {},
    'PUT': {},
    'DELETE': {},
    'PATCH': {},
  };

  void addRoute(String method, String path, Function(Request, Response) handler) {
    routes[method]![path] = handler;
  }

  Function(Request, Response)? matchRoute(String method, String path) {
    final methodRoutes = routes[method];
    if (methodRoutes == null) return null;

    for (var routePath in methodRoutes.keys) {
      final pattern = RegExp('^${routePath.replaceAllMapped(RegExp(r':(\w+)'), (match) => '(?<${match[1]}>[^/]+)')}$');
      final match = pattern.firstMatch(path);
      if (match != null) {
        return (req, res) {
          req.params.addAll(match.namedGroups);
          return methodRoutes[routePath]!(req, res);
        };
      }
    }

    return null;
  }
}

// Middleware type
typedef Middleware = FutureOr<void> Function(Request, Response, Function() next);

// Server class
class Server {
  final ServerState state = ServerState();
  final Router router = Router();
  final List<Middleware> middleware = [];

  void use(Middleware mw) {
    middleware.add(mw);
  }

  void get(String path, Function(Request, Response) handler) {
    router.addRoute('GET', path, handler);
  }

  void post(String path, Function(Request, Response) handler) {
    router.addRoute('POST', path, handler);
  }

  void put(String path, Function(Request, Response) handler) {
    router.addRoute('PUT', path, handler);
  }

  void delete(String path, Function(Request, Response) handler) {
    router.addRoute('DELETE', path, handler);
  }

  void patch(String path, Function(Request, Response) handler) {
    router.addRoute('PATCH', path, handler);
  }

  Future<void> start(String host, int port) async {
    final server = await HttpServer.bind(host, port);
    print('Server listening on $host:$port');

    await for (HttpRequest req in server) {
      handleRequest(req);
    }
  }

  Future<void> handleRequest(HttpRequest httpRequest) async {
    final uri = httpRequest.uri;
    final sessionId = httpRequest.cookies
        .firstWhere((cookie) => cookie.name == 'sessionId',
            orElse: () => Cookie('sessionId', _generateSessionId()))
        .value;

    final session = state.sessions.putIfAbsent(sessionId, () => Session(sessionId));
    final response = Response();

    final request = Request(
      httpRequest,
      {},
      uri.queryParameters,
      session,
    );

    final handler = router.matchRoute(httpRequest.method, uri.path);

    if (handler != null) {
      try {
        await _runMiddleware(request, response, () async {
          await handler(request, response);
        });

        _writeResponse(httpRequest, response);
      } catch (e, stackTrace) {
        print('Error handling request: $e\n$stackTrace');
        httpRequest.response.statusCode = HttpStatus.internalServerError;
        httpRequest.response.write('Internal Server Error');
        await httpRequest.response.close();
      }
    } else {
      httpRequest.response.statusCode = HttpStatus.notFound;
      httpRequest.response.write('Not Found');
      await httpRequest.response.close();
    }
  }

  Future<void> _runMiddleware(Request req, Response res, Function() handler) async {
    var index = 0;

    Future<void> next() async {
      if (index < middleware.length) {
        var mw = middleware[index++];
        await mw(req, res, next);
      } else {
        await handler();
      }
    }

    await next();
  }

  void _writeResponse(HttpRequest httpRequest, Response response) {
    final httpResponse = httpRequest.response;
    httpResponse.statusCode = response.statusCode;
    response.headers.forEach((name, value) {
      httpResponse.headers.set(name, value);
    });
    httpResponse.write(response.body);
    httpResponse.close();
  }

  String _generateSessionId() {
    var random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString();
  }
}

// Example usage
void main() async {
  final server = Server();

  // Middleware for logging
  server.use((req, res, next) async {
    print('${req.httpRequest.method} ${req.httpRequest.uri}');
    await next();
  });

  // Route handlers
  server.get('/', (req, res) {
    res.html('<h1>Welcome to the Advanced Stateful Dart Server!</h1>');
  });

  server.get('/api/data', (req, res) {
    res.json({'message': 'This is JSON data'});
  });

  server.post('/api/echo', (req, res) async {
    final body = await req.body();
    res.json({'echoed': body});
  });

  server.get('/session', (req, res) {
    req.session.data['visits'] = (req.session.data['visits'] ?? 0) + 1;
    res.json({'sessionId': req.session.id, 'visits': req.session.data['visits']});
  });

  // Start the server
  await server.start('localhost', 8080);
}