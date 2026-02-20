package com.example.flutter_client

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
	private val channelName = "arquent.runtime.bridge"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
					if (call.method == "capturePhoto") {
						result.success("android://camera/capture/${System.currentTimeMillis()}.jpg")
						return@setMethodCallHandler
					}

					if (call.method == "recordAudio") {
						result.success("android://microphone/record/${System.currentTimeMillis()}.m4a")
						return@setMethodCallHandler
					}

					if (call.method == "readHealthDailySummary") {
						result.success(
							hashMapOf(
								"date" to "2026-02-20",
								"sleep_hours" to 6.7,
								"steps" to 9012
							)
						)
						return@setMethodCallHandler
					}

					if (call.method != "submitSensitiveRuntimeProof") {
						result.notImplemented()
						return@setMethodCallHandler
					}

				val payload = call.arguments as? String
				if (payload.isNullOrBlank()) {
					result.error("INVALID_PAYLOAD", "payload is required", null)
					return@setMethodCallHandler
				}

				try {
					val json = JSONObject(payload)
					val token = json.getJSONObject("token")
					val visibleCaptureUi = token.optBoolean("visible_capture_ui", false)
					if (!visibleCaptureUi) {
						result.error(
							"VISIBLE_UI_REQUIRED",
							"visible_capture_ui must be true for sensitive capture",
							null
						)
						return@setMethodCallHandler
					}

					result.success("ok")
				} catch (error: Exception) {
					result.error("INVALID_PAYLOAD", error.message, null)
				}
			}
	}
}
