import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Thrown when the server returns a non-2xx response or a network error occurs.
/// Callers should treat this as "server unavailable" and fall back to
/// local-only behavior.
class RemoteApiException implements Exception {
  final String message;
  final int? statusCode;

  const RemoteApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'RemoteApiException($statusCode): $message'
      : 'RemoteApiException: $message';
}

/// Thin, typed wrapper around [http.Client] that adds:
/// - Bearer token authentication on every request
/// - JSON encode/decode
/// - Uniform [RemoteApiException] for all error cases
///
/// All HTTP knowledge is confined to this class. Sync services call the typed
/// methods and never touch [http] directly.
class RemoteApiClient {
  final String baseUrl;
  final String? authToken;
  final http.Client _client;

  RemoteApiClient({required this.baseUrl, this.authToken})
      : _client = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// GET [path] and return the decoded JSON body as a [Map].
  Future<Map<String, dynamic>> get(String path) async {
    final response = await _send(() => _client.get(
          _uri(path),
          headers: _headers,
        ));
    return _decode(response);
  }

  /// GET [path] and return the decoded JSON body as a [List].
  Future<List<dynamic>> getList(String path) async {
    final response = await _send(() => _client.get(
          _uri(path),
          headers: _headers,
        ));
    return _decodeList(response);
  }

  /// PUT [path] with [body] as JSON. Returns the decoded response body.
  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final response = await _send(() => _client.put(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body),
        ));
    return _decode(response);
  }

  /// DELETE [path]. Returns the decoded response body.
  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _send(() => _client.delete(
          _uri(path),
          headers: _headers,
        ));
    return _decode(response);
  }

  /// Releases the underlying [http.Client]. Call when the client is no longer
  /// needed (e.g. in a Riverpod [ref.onDispose] callback).
  void dispose() => _client.close();

  // ── Private helpers ────────────────────────────────────────────────────────

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base$relative');
  }

  /// Executes [request] and maps common exceptions to [RemoteApiException].
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on SocketException catch (e) {
      throw RemoteApiException('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw RemoteApiException('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      throw RemoteApiException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is RemoteApiException) rethrow;
      throw RemoteApiException('Unexpected error: $e');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    _assertSuccess(response);
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw RemoteApiException(
        'Response is not valid JSON (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  List<dynamic> _decodeList(http.Response response) {
    _assertSuccess(response);
    try {
      return jsonDecode(response.body) as List<dynamic>;
    } on FormatException {
      throw RemoteApiException(
        'Response is not valid JSON array (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  void _assertSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String detail = '';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = body['message'] as String? ??
          body['error'] as String? ??
          '';
    } catch (_) {
      detail = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
    }
    throw RemoteApiException(
      detail.isNotEmpty ? detail : 'Server returned ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}
