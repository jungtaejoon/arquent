import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "arquent.runtime.bridge"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { call, result in
      if call.method == "capturePhoto" {
        result("ios://camera/capture/\(Int(Date().timeIntervalSince1970 * 1000)).jpg")
        return
      }

      if call.method == "recordAudio" {
        result("ios://microphone/record/\(Int(Date().timeIntervalSince1970 * 1000)).m4a")
        return
      }

      if call.method == "readHealthDailySummary" {
        result([
          "date": "2026-02-20",
          "sleep_hours": 6.5,
          "steps": 8765
        ])
        return
      }

      guard call.method == "submitSensitiveRuntimeProof" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let payload = call.arguments as? String,
            let data = payload.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let token = json["token"] as? [String: Any] else {
        result(FlutterError(code: "INVALID_PAYLOAD", message: "payload is required", details: nil))
        return
      }

      let visibleCaptureUi = token["visible_capture_ui"] as? Bool ?? false
      if !visibleCaptureUi {
        result(
          FlutterError(
            code: "VISIBLE_UI_REQUIRED",
            message: "visible_capture_ui must be true for sensitive capture",
            details: nil
          )
        )
        return
      }

      result("ok")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
