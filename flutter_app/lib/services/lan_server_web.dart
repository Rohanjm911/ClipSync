import 'dart:convert';

import 'package:http/http.dart' as http;

import 'lan_server_interface.dart';

class LanServerWebImpl implements LanServer {
  String? _localIp = '127.0.0.1';

  @override
  bool get isRunning => true;

  @override
  String? get localIp => _localIp;

  @override
  Future<void> start(
    int port,
    void Function(String text, String originName) onReceived,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('http://127.0.0.1:$port/api/local-ip'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['ip'] != null && data['ip'].toString().isNotEmpty) {
          _localIp = data['ip'].toString();
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> stop() async {}
}

LanServer createLanServer() => LanServerWebImpl();
