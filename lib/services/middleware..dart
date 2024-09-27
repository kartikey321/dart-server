import 'dart:async';

import '../models/request.dart';
import '../models/response.dart';

typedef NextFunction = FutureOr<void> Function();
typedef MiddlewareFunction = Future<void> Function(
    Request request, Response response, NextFunction next);
typedef RequestHandler = FutureOr<void> Function(
    Request request, Response response);

class Middleware {
  final String path;
  final MiddlewareFunction handler;

  Middleware(this.path, this.handler);
}

class DIContainer {
  final Map<Type, dynamic> _instances = {};
  final Map<Type, Function> _factories = {};

  void registerSingleton<T>(T instance) {
    _instances[T] = instance;
  }

  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  T get<T>() {
    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }
    if (_factories.containsKey(T)) {
      final instance = _factories[T]!() as T;
      _instances[T] = instance; // Cache the instance
      return instance;
    }
    throw Exception('No instance or factory registered for type $T');
  }
}
