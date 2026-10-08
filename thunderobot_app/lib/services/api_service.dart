import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl = 'http://127.0.0.1:18888';
  final HttpClient _client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1500);

  Future<bool> ping() async {
    try {
      final req = await _client.getUrl(Uri.parse('$baseUrl/status')).timeout(const Duration(milliseconds: 1500));
      req.headers.set(HttpHeaders.connectionHeader, 'close');
      final resp = await req.close().timeout(const Duration(milliseconds: 1500));
      await resp.drain();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final req = await _client.getUrl(Uri.parse('$baseUrl/status')).timeout(const Duration(milliseconds: 2000));
      req.headers.set(HttpHeaders.connectionHeader, 'close');
      final resp = await req.close().timeout(const Duration(milliseconds: 2000));
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join().timeout(const Duration(milliseconds: 2000));
        return json.decode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _post(String path, Map<String, dynamic> data) async {
    try {
      final req = await _client.postUrl(Uri.parse('$baseUrl$path')).timeout(const Duration(milliseconds: 2000));
      final bodyBytes = utf8.encode(json.encode(data));
      req.headers.contentType = ContentType.json;
      req.headers.set(HttpHeaders.connectionHeader, 'close');
      req.contentLength = bodyBytes.length;
      req.add(bodyBytes);
      final resp = await req.close().timeout(const Duration(milliseconds: 2000));
      await resp.drain();
    } catch (e) {
      debugPrint('ApiService error on $path: $e');
    }
  }

  Future<void> setEffect({
    required String effect,
    required double speed,
    required int r,
    required int g,
    required int b,
    required int secR,
    required int secG,
    required int secB,
  }) async {
    await _post('/effect', {
      'effect': effect,
      'speed': speed,
      'color': [r, g, b],
      'secondary_color': [secR, secG, secB],
    });
  }

  Future<void> setBrightness(int level) async {
    await _post('/brightness', {'brightness': level});
  }

  Future<void> stop() async {
    await _post('/stop', {});
  }

  Future<void> setPowerProfile(String profile) async {
    await _post('/power', {'profile': profile});
  }

  Future<void> setFnLock(bool enabled) async {
    await _post('/fn_lock', {'enabled': enabled});
  }

  Future<void> setFanBoost(bool enabled) async {
    await _post('/fan_boost', {'enabled': enabled});
  }
}
