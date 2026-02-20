import 'dart:async';
import 'dart:html' as html;

import 'sensitive_capabilities.dart';

class _WebSensitiveCapabilities implements SensitiveCapabilities {
  @override
  Future<String> capturePhoto() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw Exception('Browser does not support media devices.');
    }

    final stream = await mediaDevices.getUserMedia({'video': true});
    await Future<void>.delayed(const Duration(milliseconds: 700));
    for (final track in stream.getTracks()) {
      track.stop();
    }

    return 'webcam://capture/${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<String> recordAudio({required int maxSeconds}) async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw Exception('Browser does not support media devices.');
    }

    final stream = await mediaDevices.getUserMedia({'audio': true});
    final wait = Duration(seconds: maxSeconds.clamp(1, 3));
    await Future<void>.delayed(wait);
    for (final track in stream.getTracks()) {
      track.stop();
    }

    return 'microphone://record/${DateTime.now().millisecondsSinceEpoch}.webm';
  }

  @override
  Future<Map<String, dynamic>> readHealthDailySummary() {
    throw Exception('Health connector is unavailable in web runtime. Use iOS/Android build.');
  }
}

SensitiveCapabilities createSensitiveCapabilitiesImpl() => _WebSensitiveCapabilities();
