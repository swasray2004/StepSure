package com.example.stepsure


import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
	private val CHANNEL = "video_frame_extractor"

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "extractFrames") {
				val videoPath = call.argument<String>("videoPath")
				val fps = call.argument<Int>("fps") ?: 5
				val width = call.argument<Int>("width") ?: 720
				val height = call.argument<Int>("height") ?: 405
				val count = call.argument<Int>("count") ?: 50
				try {
					val retriever = MediaMetadataRetriever()
					retriever.setDataSource(videoPath)
					val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0L
					val interval = durationMs / count
					val frames = mutableListOf<ByteArray>()
					for (i in 0 until count) {
						val timeMs = i * interval
						val bitmap = retriever.getFrameAtTime(timeMs * 1000, MediaMetadataRetriever.OPTION_CLOSEST)
						if (bitmap != null) {
							val scaled = Bitmap.createScaledBitmap(bitmap, width, height, true)
							val stream = ByteArrayOutputStream()
							scaled.compress(Bitmap.CompressFormat.JPEG, 90, stream)
							frames.add(stream.toByteArray())
							stream.close()
						}
					}
					retriever.release()
					result.success(frames)
				} catch (e: Exception) {
					result.error("frame_extraction_failed", e.message, null)
				}
			} else {
				result.notImplemented()
			}
		}
	}
}
