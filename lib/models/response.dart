import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Response {
  int statusCode;
  dynamic body;
  Map<String, String> headers = {};
  bool _isBinary = false;

  Response.raw({this.statusCode = 200, this.body = '', Map<String, String>? headers}) {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  Response.json(Map<String, dynamic> jsonData, {this.statusCode = 200})
      : body = jsonEncode(jsonData) {
    headers['Content-Type'] = ContentType.json.toString();
  }

  Response.plainText(String text, {this.statusCode = 200})
      : body = text {
    headers['Content-Type'] = ContentType.text.toString();
  }

  Response.html(String html, {this.statusCode = 200})
      : body = html {
    headers['Content-Type'] = ContentType.html.toString();
  }

  Response.xml(String xml, {this.statusCode = 200})
      : body = xml {
    headers['Content-Type'] = 'application/xml';
  }

  Response.bytes(Uint8List bytes, {this.statusCode = 200, String contentType = 'application/octet-stream'})
      : body = bytes,
        _isBinary = true {
    headers['Content-Type'] = contentType;
    headers['Content-Length'] = bytes.length.toString();
  }

  static Future<Response> file(File file, {int statusCode = 200}) async {
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return Response.bytes(
        bytes,
        statusCode: statusCode,
        contentType: _getContentType(file.path),
      );
    } else {
      return Response.raw(statusCode: HttpStatus.notFound, body: 'File not found');
    }
  }

  static String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'html': return ContentType.html.toString();
      case 'css': return 'text/css';
      case 'js': return 'application/javascript';
      case 'json': return ContentType.json.toString();
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'svg': return 'image/svg+xml';
      case 'xml': return 'application/xml';
      case 'pdf': return 'application/pdf';
  
      default: return ContentType.binary.toString();
    }
  }

void write(HttpResponse httpResponse) {
  httpResponse.statusCode = statusCode;

  // Set headers
  headers.forEach((name, value) {
    httpResponse.headers.set(name, value);
  });

  // Write the body
  if (_isBinary) {
    // Add binary data
    httpResponse.add(body as Uint8List);
  } else {
    // Write text data
    httpResponse.write(body);
  }

  // Close the response
  httpResponse.close();
}

}