import 'package:server/models/request.dart';
import 'package:server/models/response.dart';
import 'package:server/services/controller.dart';
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

  // Add a route with path parameter
  app.get('/api/data', (request, response) async {
    final data = await request.body;

    // Process the data
    response.json({
      'success': true,
      'data': data,
      'params': request.params,
      'query': request.query
    });
  });
  app.useController('/users', UsersController());
  app.useController('/posts', PostsController());
  // Handle form data
  app.post('/api/form', (request, response) async {
    final formData = await request.formData;
    // Process the form data
    response.json({'success': true, 'data': formData});
  });

  app.listen(3000);
}

class DatabaseService {}

class UsersController extends Controller {
  @override
  void initialize(DartExpress app, {String prefix = ''}) {
    super.initialize(app, prefix: prefix);
    print("hi");
    // TODO: implement initialize
  }

  @override
  void registerRoutes(options) {
    options.get('/', getUsers);
    options.get('/:id', getUserById);
    options.post('/users', createUser);
  }

  void getUsers(Request request, Response response) {
    // Implementation
  }

  void getUserById(Request request, Response response) {
    final userId = request.params['id'];
    response.html('<h1>hi $userId</h1>');
    // Implementation using userId
  }

  void createUser(Request request, Response response) {
    // Implementation
  }
}

class PostsController extends Controller {
  @override
  void registerRoutes(options) {
    options.get('/get', getPosts);
  }

  getPosts(Request req, Response resp) {
    resp.json({"data": "hi"});
  }
}
