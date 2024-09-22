import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:server/extensions.dart';

class Session {
  final String id;
  final Map<String, dynamic> data = {};

  Session(this.id);
}

class Request {
  final HttpRequest httpRequest;
  final Map<String, String> params;
  final Map<String, String> query;
  final Session session;

  Request(this.httpRequest, this.params, this.query, this.session);

  String get method => httpRequest.method;
  Uri get uri => httpRequest.uri;
  HttpHeaders get headers => httpRequest.headers;

  // Lazy-loaded body
  String? _body;
  dynamic _jsonBody;

  Future<String> get body async {
    _body ??= await utf8.decoder.bind(httpRequest).join();
    return _body!;
  }

  Future<dynamic> get jsonBody async {
    if (_jsonBody == null) {
      final bodyStr = await body;
      try {
        _jsonBody = json.decode(bodyStr);
      } catch (e) {
        throw FormatException('Invalid JSON in request body');
      }
    }
    return _jsonBody;
  }

  Future<Map<String, dynamic>> get formData async {
    final contentType = headers.contentType;
    if (contentType?.mimeType == 'application/x-www-form-urlencoded') {
      return Uri.splitQueryString(await body);
    } else {
      throw UnsupportedError('Content-Type is not application/x-www-form-urlencoded');
    }
  }

  bool accepts(String mimeType) {
    final acceptHeader = headers.value('accept');
    if (acceptHeader == null) return false;
    return acceptHeader.split(',').any((e) => e.trim().toLowerCase() == mimeType.toLowerCase());
  }

  String? cookie(String name) {
    return httpRequest.cookies.containsWithCondition((cookie) => cookie.name == name,)?.value;
  }

  bool get isAjax => headers.value('X-Requested-With')?.toLowerCase() == 'xmlhttprequest';

  String? header(String name) => headers.value(name);

  /// Creates a `Request` object from the `HttpRequest`, extracting route and query parameters.
  static Future<Request> from(
    HttpRequest httpRequest, {
    String routePattern = '',
  }) async {
    // Extract query parameters from the URL
    final query = httpRequest.uri.queryParameters;

    // Extract route parameters based on the provided route pattern (e.g., `/user/:id`)
    final params = _extractParams(httpRequest.uri.path, routePattern);

    // Retrieve or generate a session ID
    final sessionId = httpRequest.cookies
        .containsWithCondition((cookie) => cookie.name == 'sessionId', )
        ?.value ?? _generateSessionId();
    final session = Session(sessionId);

    return Request(httpRequest, params, query, session);
  }

  /// Extracts route parameters (e.g., `:id`) based on the route pattern.
   /// Extracts route parameters based on the route pattern.
/// Extracts route parameters based on the route pattern.
static Map<String, String> _extractParams(String path, String routePattern) {
  // Split the path and pattern, trimming leading/trailing slashes and empty strings.
  final patternParts = routePattern.split('/').where((part) => part.isNotEmpty).toList();
  final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();

  // Ensure the number of parts matches between the path and pattern.
  if (patternParts.length != pathParts.length) {
    return {};
  }

  final params = <String, String>{};
  for (var i = 0; i < patternParts.length; i++) {
    if (patternParts[i].startsWith(':')) {
      // Extract the parameter name from the pattern and assign the corresponding path part.
      final paramName = patternParts[i].substring(1);
      params[paramName] = pathParts[i];
    } else if (patternParts[i] != pathParts[i]) {
      // If the static part of the pattern does not match the path, return empty.
      return {};
    }
  }

  return params;
}

  /// Generates a random session ID
  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }
}
