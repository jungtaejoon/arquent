import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let channelName = "arquent.runtime.bridge"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
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

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
