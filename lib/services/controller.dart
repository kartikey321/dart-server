import 'dart_express.dart';

abstract class Controller {
  void registerRoutes(DartExpress app, {String prefix = ''});
}
