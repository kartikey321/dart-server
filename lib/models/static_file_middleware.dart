import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
// import 'package:server/services/dart_express.dart';
import '../models/middleware.dart';

// class StaticFileMiddleware {
//   final String rootDirectory;
//   final List<String> allowedExtensions;
//   final int maxFileSize;
//   final String cacheControl;

//   StaticFileMiddleware({
//     required this.rootDirectory,
//     this.allowedExtensions = const [
//       '.png',
//       '.jpg',
//       '.jpeg',
//       '.gif',
//       '.webp',
//       '.svg',
//       '.html',
//       '.css',
//       '.js'
//     ],
//     this.maxFileSize = 10 * 1024 * 1024, // 10 MB
//     this.cacheControl = 'public, max-age=3600', // Cache for 1 hour
//   });

//   MiddlewareHandler createMiddleware() {
//     return (request, response, next) async {
//       try {
//         String requestPath = request.uri.path;

//         print('Incoming request path: $requestPath');

//         // Sanitize the path
//         String sanitizedPath = _sanitizePath(requestPath);
//         print('Sanitized request path: $sanitizedPath');

//         // Resolve file path
//         File file = File(path.join(rootDirectory, sanitizedPath));
//         print('Resolved file path: ${file.path}');

//         // Check if file exists
//         if (!file.existsSync()) {
//           print('File not found: ${file.path}');
//           await next(); // Pass to next middleware/handler
//           return;
//         }

//         // Validate extension
//         String fileExtension = path.extension(file.path).toLowerCase();
//         if (!allowedExtensions.contains(fileExtension)) {
//           print('Invalid file extension: $fileExtension');
//           await next();
//           return;
//         }

//         // Determine MIME type
//         String? mimeType =
//             lookupMimeType(file.path) ?? 'application/octet-stream';
//         print('MIME Type: $mimeType');

//         // Serve the file
//         response.setHeader('Content-Type', mimeType);
//         await response.file(file);
//         print('File served: ${file.path}');
//       } catch (e) {
//         print('Error in static file middleware: $e');
//         await next();
//       }
//     };
//   }

//   String _sanitizePath(String requestPath) {
//     // Decode URL and normalize path
//     String sanitized =
//         Uri.decodeComponent(requestPath.replaceFirst(RegExp(r'^/'), ''));
//     sanitized = path.normalize(sanitized);

//     // Prevent directory traversal
//     List<String> segments = sanitized.split(path.separator);
//     segments =
//         segments.where((segment) => segment != '..' && segment != '.').toList();

//     return path.joinAll(segments);
//   }
// }

// extension StaticFileExtension on DartExpress {
//   MiddlewareHandler staticFile({
//     required String directory,
//     List<String>? allowedExtensions,
//     int? maxFileSize,
//     String cacheControl = 'public, max-age=3600',
//   }) {
//     return StaticFileMiddleware(
//       rootDirectory: directory,
//       allowedExtensions: allowedExtensions ?? [],
//       maxFileSize: maxFileSize ?? (10 * 1024 * 1024),
//       cacheControl: cacheControl,
//     ).createMiddleware();
//   }
// }

// Middleware to serve static files
MiddlewareHandler staticFileMiddleware(String rootDirectory) {
  return (request, response, next) async {
    try {
      final requestPath = request.uri.path;
      print('Incoming request path: $requestPath');

      final sanitizedPath =
          requestPath.startsWith('/') ? requestPath.substring(1) : requestPath;
      print('Sanitized request path: $sanitizedPath');

      final filePath = path.join(rootDirectory, sanitizedPath);
      final file = File(filePath);
      print('Resolved file path: $filePath');

      if (!file.existsSync()) {
        print('File not found: $filePath');
        await next();
        return;
      }

      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      print('Serving file with MIME type: $mimeType');

      response.setHeader('Content-Type', mimeType);
      await response.file(file);
      print('File served: $filePath');
    } catch (e) {
      print('Error in static file middleware: $e');
      await next();
    }
  };
}
