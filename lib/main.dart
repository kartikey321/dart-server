import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:server/models/request.dart';
import 'package:server/models/response.dart';
import 'package:server/models/static_file_middleware.dart';
import 'package:server/services/controller.dart';
import 'package:server/services/dart_express.dart';

void main() {
  final app = DartExpress();

  // Register a dependency
  app.inject(DatabaseService());

  // Serve static files from the "public" directory
  app.use(staticFileMiddleware('public'));

  // Use CORS middleware
  app.use(
    app.cors(
      allowedOrigins: ['*'],
      allowedMethods: [...RequestTypes.allTypes],
      allowCredentials: true,
    ),
  );

  //rate-limiter
  app.use(
    app.rateLimiter(
      maxRequests: 200,
      // maxRequests: 100,
      window: Duration(minutes: 5),
    ),
  );

  // Optional: Add a route to list available files (for debugging)
  app.get('/files', (request, response) async {
    final publicDir = Directory('public');
    final files = publicDir
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => {
              'path': file.path.replaceFirst('${publicDir.path}/', ''),
              'absolutePath': file.path,
              'size': file.lengthSync(),
              'modified': file.lastModifiedSync().toIso8601String(),
            })
        .toList();
    print('Files in public directory: $files');
    response.json({'files': files});
  });

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

  Future<String> handleMultipartFile(http.MultipartFile multipartFile) async {
    // Convert MultipartFile to Uint8List
    Uint8List fileBytes = await multipartFile
        .finalize()
        .fold<BytesBuilder>(
            BytesBuilder(), (builder, bytes) => builder..add(bytes))
        .then((b) => b.takeBytes());

    // Convert Uint8List to base64
    String base64String = base64Encode(fileBytes);

    // Generate the HTML string
    String htmlString = '''
  <!DOCTYPE html>
  <html>
  <head>
    <title>Image Preview</title>
  </head>
  <body>
    <h1>Image Preview</h1>
    <img src="data:image/png;base64,$base64String" alt="Uploaded Image" />
  </body>
  </html>
  ''';

    // Use the generated HTML as a response
    return htmlString; // Or pass it as needed to your response
  }

  app.post('/api/form', (request, response) async {
    final formData = await request.formData;
    // Process the form data
    if (formData.values.first is List<http.MultipartFile>) {
      var file = formData.values.first.first as http.MultipartFile;

      response.html(await handleMultipartFile(file));
    } else {
      response.json({'success': true, 'data': formData});
    }
  });

  // app.listen(int.parse(Platform.environment['PORT'] ?? '8080'));

  int port = int.parse(Platform.environment['PORT'] ?? '8080');
  app.listen(port);
}

class DatabaseService {
  final List<Map<String, dynamic>> _data = [];

  void create(Map<String, dynamic> record) {
    _data.add(record);
    print('Record added: $record');
  }

  List<Map<String, dynamic>> readAll() {
    print('Reading all records...');
    return _data;
  }

  void update(int index, Map<String, dynamic> newRecord) {
    if (index >= 0 && index < _data.length) {
      _data[index] = newRecord;
      print('Record at index $index updated to: $newRecord');
    } else {
      print('Record at index $index not found');
    }
  }

  void delete(int index) {
    if (index >= 0 && index < _data.length) {
      print('Deleting record at index $index: ${_data[index]}');
      _data.removeAt(index);
    } else {
      print('Record at index $index not found');
    }
  }
}

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
    options.get('/post', addRecords);
    options.get('/get-posts', getRecords);
    // options.get('/:id', getUserById);
    options.post('/users', createUser);
    options.get('/image', getImage);
    options.get('/put-image', showImage);
  }

  void getRecords(Request request, Response response) async {
    final dbService = request.container.get<DatabaseService>();

    final records = dbService.readAll();
    response.json({'records': records});
  }

  void addRecords(Request request, Response response) async {
    final dbService = request.container.get<DatabaseService>();

    final newRecord = {'id': 3, 'name': 'New User'};
    dbService.create(newRecord);
    response.json({'message': 'Record added', 'record': newRecord});
  }

  void showImage(Request request, Response response) async {
    var files = await request.files;
    if (files.isNotEmpty) {
      var data = files.entries.first.value.first;
      // Read the stream once and convert it to a List<int>
      var bytes = await data.finalize().toList();
      // Flatten the list of lists to a single list of bytes
      var flattenedBytes = bytes.expand((e) => e).toList();
      var base64Image = base64Encode(flattenedBytes);

      response.html(
        '<img src="data:${data.contentType};base64,$base64Image"/>',
      );
    }
  }

  void getImage(Request request, Response response) {
    response.html(
        '<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRE54fv4jfGnS39pFjOCJo5qEE3qh86HIst3w&s"/>');
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
