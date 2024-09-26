import 'package:server/services/dart_express.dart';

void main() {
  final app = DartExpress();

  // Register a dependency
  app.inject(DatabaseService());

  // Use CORS middleware
  app.use(app.cors(
      allowedOrigins: ['https://example.com'],
      allowedMethods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowCredentials: true));
  // Add a route
  app.post('/api/data', (request, response) async {
    final data = await request.body;

    // Process the data
    response.json({'success': true, 'data': data});
  });

  // Handle form data
  app.post('/api/form', (request, response) async {
    final formData = await request.formData;
    // Process the form data
    response.json({'success': true, 'data': formData});
  });

  app.listen(3000);
}

class DatabaseService {}
