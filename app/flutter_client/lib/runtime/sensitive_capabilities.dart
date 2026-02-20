import 'sensitive_capabilities_stub.dart'
    if (dart.library.html) 'sensitive_capabilities_web.dart';

abstract class SensitiveCapabilities {
  Future<String> capturePhoto();
  Future<String> recordAudio({required int maxSeconds});
  Future<Map<String, dynamic>> readHealthDailySummary();
}

SensitiveCapabilities createSensitiveCapabilities() => createSensitiveCapabilitiesImpl();
