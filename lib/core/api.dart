import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'env.dart';

class Api {
  static Future<Map<String, dynamic>> getJson(String path, [Map<String, String>? q]) async {
    final uri = Uri.parse('${Env.baseUrl}/$path').replace(queryParameters: q);
    final res = await http.get(uri);
    final txt = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(txt) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${res.statusCode}: $txt');
  }


// مثال سريع داخل Api:
static Future<Map<String, dynamic>> postMultipart(
  String path, {
  Map<String, String>? fields,
  Map<String, File>? files,
}) async {
  final uri = Uri.parse('${Env.baseUrl}/$path'); // عدّل baseUrl
  final req = http.MultipartRequest('POST', uri);
  fields?.forEach((k, v) => req.fields[k] = v);
  if (files != null) {
    for (final e in files.entries) {
      req.files.add(await http.MultipartFile.fromPath(e.key, e.value.path));
    }
  }
  final resp = await req.send();
  final body = await resp.stream.bytesToString();
  return jsonDecode(body) as Map<String, dynamic>;
}
  static Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('${Env.baseUrl}/$path');
    final res = await http.post(uri, body: data);
    final txt = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(txt) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${res.statusCode}: $txt');
  }

}
