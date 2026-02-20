import 'package:flutter/services.dart';

import 'sensitive_capabilities.dart';

class _StubSensitiveCapabilities implements SensitiveCapabilities {
  static const MethodChannel _channel = MethodChannel('arquent.runtime.bridge');

  @override
  Future<String> capturePhoto() async {
    final response = await _channel.invokeMethod<String>('capturePhoto');
    if (response == null || response.isEmpty) {
      throw Exception('Native capturePhoto is unavailable.');
    }
    return response;
  }

  @override
  Future<String> recordAudio({required int maxSeconds}) async {
    final response = await _channel.invokeMethod<String>('recordAudio', {
      'max_seconds': maxSeconds,
    });
    if (response == null || response.isEmpty) {
      throw Exception('Native recordAudio is unavailable.');
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> readHealthDailySummary() async {
    final response = await _channel.invokeMethod<Map<dynamic, dynamic>>('readHealthDailySummary');
    if (response == null) {
      throw Exception('Native health connector is unavailable.');
    }
    return response.map((key, value) => MapEntry('$key', value));
  }
}

SensitiveCapabilities createSensitiveCapabilitiesImpl() => _StubSensitiveCapabilities();
