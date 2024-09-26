import 'dart:async';

import '../models/request.dart';
import '../models/response.dart';

typedef NextFunction = FutureOr<void> Function();
typedef Middleware = FutureOr<void> Function(
    Request request, Response response, NextFunction next);
typedef RequestHandler = FutureOr<void> Function(
    Request request, Response response);

// lib/di_container.dart
class DIContainer {
  final Map<Type, dynamic> _instances = {};

  void register<T>(T instance) {
    _instances[T] = instance;
  }

  T get<T>() {
    final instance = _instances[T];
    if (instance == null) {
      throw Exception('No instance registered for type $T');
    }
    return instance as T;
  }
}
