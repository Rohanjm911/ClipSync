import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'lan_server_interface.dart';

class LanServerImpl implements LanServer {
  HttpServer? _server;
  String? _cachedLocalIp;
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  String? get localIp => _cachedLocalIp;

  @override
  Future<void> start(
    int port,
    void Function(String text, String originName) onReceived,
  ) async {
    await stop();
    await _detectLocalIp();

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      _running = true;
      debugPrint(
        '[ClipSync LAN Server] Listening on http://${_cachedLocalIp ?? "0.0.0.0"}:$port',
      );

      _server!.listen((HttpRequest request) async {
        // Add CORS headers for web/cross-origin clients
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add(
          'Access-Control-Allow-Methods',
          'POST, GET, OPTIONS',
        );
        request.response.headers.add(
          'Access-Control-Allow-Headers',
          'Content-Type',
        );

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        final path = request.uri.path;

        if (path == '/api/sync' && request.method == 'POST') {
          try {
            final body = await utf8.decoder.bind(request).join();
            final json = jsonDecode(body) as Map<String, dynamic>;
            final text = (json['text'] as String?) ?? '';
            final origin = (json['origin'] as String?) ?? 'Companion Device';

            if (text.trim().isNotEmpty) {
              onReceived(text.trim(), origin);
            }

            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({'status': 'ok', 'received': text.length}),
            );
          } catch (e) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'error': e.toString()}));
          }
          await request.response.close();
          return;
        }

        if (path == '/api/ping') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'status': 'alive',
              'ip': _cachedLocalIp,
              'port': port,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          );
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        request.response.write('ClipSync Node Active');
        await request.response.close();
      });
    } catch (e) {
      debugPrint('[ClipSync LAN Server] Bind error on port $port: $e');
      _running = false;
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            _cachedLocalIp = ip;
            return;
          }
        }
      }

      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        _cachedLocalIp = interfaces.first.addresses.first.address;
      }
    } catch (e) {
      debugPrint('Failed to detect local IP: $e');
    }
  }
}

LanServer createLanServer() => LanServerImpl();
