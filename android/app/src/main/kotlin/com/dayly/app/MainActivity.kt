package com.dayly.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Google Assistant (App Actions) and app-icon shortcuts open
 * `dayly://assistant?action=…`; commands queue here until Dart takes them
 * (lib/services/assistant), so a cold start loses nothing.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private val pending = mutableListOf<Map<String, String>>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dayly/assistant").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "take") {
                    result.success(pending.toList())
                    pending.clear()
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) collect(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        collect(intent)
    }

    private fun collect(intent: Intent?) {
        if (intent == null) return
        val uri = intent.data ?: return
        if (uri.scheme != "dayly" || uri.host != "assistant") return
        val action = uri.getQueryParameter("action") ?: return
        val command = mutableMapOf("action" to action)
        uri.getQueryParameter("text")?.let { command["text"] = it }
        // App Actions name a feature (the shortcut id); shortcuts give a route.
        val route = uri.getQueryParameter("route") ?: when (uri.getQueryParameter("feature")) {
            "plan" -> "/plan"
            "focus" -> "/focus"
            "money" -> "/money"
            else -> null
        }
        route?.let { command["route"] = it }
        intent.data = null // not again after a configuration change
        pending.add(command)
        channel?.invokeMethod("ping", null)
    }
}
