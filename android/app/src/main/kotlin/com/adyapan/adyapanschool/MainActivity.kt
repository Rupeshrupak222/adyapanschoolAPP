package com.adyapan.adyapanschool

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.adyapan.school/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            when (call.method) {
                "isNotificationPolicyAccessGranted" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        notificationManager.isNotificationPolicyAccessGranted
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "gotoPolicySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    } else {
                        result.success(null)
                    }
                }
                "setInterruptionFilter" -> {
                    val filterVal = call.argument<String>("filter")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (notificationManager.isNotificationPolicyAccessGranted) {
                            val filter = if (filterVal == "NONE") {
                                NotificationManager.INTERRUPTION_FILTER_NONE
                            } else {
                                NotificationManager.INTERRUPTION_FILTER_ALL
                            }
                            notificationManager.setInterruptionFilter(filter)
                            result.success(null)
                        } else {
                            result.error("PERMISSION_DENIED", "Notification policy access not granted", null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
