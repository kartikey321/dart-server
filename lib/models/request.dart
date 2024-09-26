import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:server/extensions.dart';

import '../services/middleware..dart';

class Session {
  final String id;
  final Map<String, dynamic> data = {};

  Session(this.id);
}

class Request {
  final HttpRequest httpRequest;
  Map<String, dynamic> params = {};
  final Map<String, String> query;
  final Session session;
  final DIContainer container;
  Map<String, dynamic>? _body;
  Map<String, dynamic>? _formData;
  Map<String, List<MultipartFile>>? _files;

  Request(
      this.httpRequest, this.query, this.params, this.session, this.container);

  String get method => httpRequest.method;
  Uri get uri => httpRequest.uri;
  HttpHeaders get headers => httpRequest.headers;

  Future<Map<String, dynamic>> get body async {
    if (_body == null) {
      final contentType = headers.contentType?.mimeType;
      if (contentType == 'application/json') {
        _body = json.decode(await utf8.decoder.bind(httpRequest).join());
      } else if (contentType == 'application/x-www-form-urlencoded') {
        _body = uri.queryParameters;
      }
    }
    return _body ?? {};
  }

  Future<Map<String, dynamic>> get formData async {
    if (_formData == null) {
      final contentType = headers.contentType?.mimeType;
      if (contentType == 'multipart/form-data') {
        final boundary = headers.contentType!.parameters['boundary']!;
        final transformer = MimeMultipartTransformer(boundary);
        final parts = await transformer.bind(httpRequest).toList();

        _formData = {};
        _files = {};

        for (var part in parts) {
          final contentDisposition = part.headers['content-disposition'];
          final name = RegExp(r'name="([^"]*)"')
              .firstMatch(contentDisposition!)!
              .group(1)!;

          if (contentDisposition.contains('filename')) {
            final filename = RegExp(r'filename="([^"]*)"')
                .firstMatch(contentDisposition)!
                .group(1)!;
            final content = await part.toList();
            var length = await part.length;
            final file = MultipartFile(name, part, length, filename: filename);
            _files![name] = (_files![name] ?? [])..add(file);
          } else {
            final value = await utf8.decoder.bind(part).join();
            _formData![name] = value;
          }
        }
      }
    }
    return _formData ?? {};
  }

  static Request from(
    HttpRequest httpRequest, {
    String routePattern = '',
    required DIContainer container,
  }) {
    // Extract query parameters from the URL
    final query = httpRequest.uri.queryParameters;

    // Extract route parameters based on the provided route pattern (e.g., `/user/:id`)
    final params = _extractParams(httpRequest.uri.path, routePattern);

    // Retrieve or generate a session ID
    final sessionId = httpRequest.cookies
            .containsWithCondition(
              (cookie) => cookie.name == 'sessionId',
            )
            ?.value ??
        _generateSessionId();
    final session = Session(sessionId);

    return Request(httpRequest, params, query, session, container);
  }

  static Map<String, String> _extractParams(String path, String routePattern) {
    final patternParts =
        routePattern.split('/').where((part) => part.isNotEmpty).toList();
    final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();

    if (patternParts.length != pathParts.length) {
      return {};
    }

    final params = <String, String>{};
    for (var i = 0; i < patternParts.length; i++) {
      if (patternParts[i].startsWith(':')) {
        final paramName = patternParts[i].substring(1);
        params[paramName] = pathParts[i];
      } else if (patternParts[i] != pathParts[i]) {
        return {};
      }
    }

    return params;
  }

  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<Map<String, List<MultipartFile>>> get files async {
    await formData; // Ensure formData has been processed
    return _files ?? {};
  }
}
