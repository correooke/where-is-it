package com.example.parking_detector_plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.content.Context
import android.content.Intent
import android.app.Activity
import com.example.parking_detector_plugin.service.ParkingDetectionService
import com.example.parking_detector_plugin.detector.ParkingState
import android.util.Log
import org.koin.core.context.GlobalContext
import org.koin.core.context.startKoin
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import com.example.parking_detector_plugin.di.appModule

class ParkingDetectorPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var eventSink: EventChannel.EventSink? = null
  private val pendingEvents: ArrayDeque<Map<String, Any>> = ArrayDeque()

  // Static singleton para acceder desde el servicio
  companion object {
    private var instance: ParkingDetectorPlugin? = null

    fun getInstance(): ParkingDetectorPlugin? {
      return instance
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Log.d("ParkingDetectorPlugin", "onAttachedToEngine called")
    instance = this
    context = flutterPluginBinding.applicationContext
    
    // Inicializar Koin solo si aún no está inicializado
    if (GlobalContext.getOrNull() == null) {
        startKoin {
            androidLogger()
            androidContext(context)
            modules(appModule)
        }
        Log.d("ParkingDetectorPlugin", "Koin inicializado desde el plugin")
    } else {
        Log.d("ParkingDetectorPlugin", "Koin ya estaba inicializado")
    }
    
    // Canal para métodos (comandos desde Flutter a nativo)
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.parking_detector_plugin/parking_detection")
    methodChannel.setMethodCallHandler(this)
    
    // Canal para eventos (eventos desde nativo a Flutter)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.example.parking_detector_plugin/parking_events")
    eventChannel.setStreamHandler(this)

    // Emitir estado actual si existe (sticky) para suscriptores tardíos
    try {
      val current = com.example.parking_detector_plugin.service.ParkingDetectionService.getCurrentState()?.name
      if (current != null) {
        pendingEvents.add(mapOf("state" to current, "timestamp" to System.currentTimeMillis()))
      }
    } catch (e: Exception) {
      Log.e("ParkingDetectorPlugin", "Error queuing sticky state", e)
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    Log.d("ParkingDetectorPlugin", "onMethodCall: ${call.method}")
    when (call.method) {
      "startParkingDetection" -> {
        Log.d("ParkingDetectorPlugin", "startParkingDetection called")
        val intent = Intent(context, ParkingDetectionService::class.java)
        context.startForegroundService(intent)
        result.success(true)
      }
      "stopParkingDetection" -> {
        Log.d("ParkingDetectorPlugin", "stopParkingDetection called")
        val intent = Intent(context, ParkingDetectionService::class.java)
        context.stopService(intent)
        result.success(true)
      }
      "emitTestEvent" -> {
        Log.d("ParkingDetectorPlugin", "emitTestEvent called")
        // Enviar un evento de prueba con estado CONFIRMED_PARKED
        try {
          sendParkingStateEvent(ParkingState.CONFIRMED_PARKED)
          result.success(true)
        } catch (e: Exception) {
          Log.e("ParkingDetectorPlugin", "Error emitting test event", e)
          result.error("EMIT_ERROR", e.message, null)
        }
      }
      "getCurrentState" -> {
        Log.d("ParkingDetectorPlugin", "getCurrentState called")
        val state = ParkingDetectionService.getCurrentState()?.name ?: "UNKNOWN"
        result.success(state)
      }
      else -> {
        Log.d("ParkingDetectorPlugin", "Method not implemented: ${call.method}")
        result.notImplemented()
      }
    }
  }

  // Método para enviar eventos de cambio de estado desde cualquier parte del código nativo
  fun sendParkingStateEvent(state: ParkingState) {
    Log.d("ParkingDetectorPlugin", "sendParkingStateEvent: ${state.name}")
    val stateMap = mapOf(
      "state" to state.name,
      "timestamp" to System.currentTimeMillis()
    )

    // Enviar evento a Flutter en el hilo principal. Si no hay suscriptores aún, bufferizar.
    val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    mainHandler.post {
      try {
        if (eventSink == null) {
          pendingEvents.add(stateMap)
        } else {
          eventSink?.success(stateMap)
        }
      } catch (e: Exception) {
        Log.e("ParkingDetectorPlugin", "Error sending event to Flutter", e)
      }
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    Log.d("ParkingDetectorPlugin", "onListen called")
    eventSink = events
    // Drenar eventos pendientes
    while (pendingEvents.isNotEmpty()) {
      try {
        eventSink?.success(pendingEvents.removeFirst())
      } catch (e: Exception) {
        Log.e("ParkingDetectorPlugin", "Error draining pending events", e)
        break
      }
    }
  }

  override fun onCancel(arguments: Any?) {
    Log.d("ParkingDetectorPlugin", "onCancel called")
    eventSink = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d("ParkingDetectorPlugin", "onDetachedFromEngine called")
    instance = null
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    Log.d("ParkingDetectorPlugin", "onAttachedToActivity called")
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.d("ParkingDetectorPlugin", "onDetachedFromActivityForConfigChanges called")
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    Log.d("ParkingDetectorPlugin", "onReattachedToActivityForConfigChanges called")
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    Log.d("ParkingDetectorPlugin", "onDetachedFromActivity called")
    activity = null
  }
}