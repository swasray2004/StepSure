Completed ML Work
Bug Fixes
## 1. Step detection — gait_analysis_service.dart

Replaced the naive if (lk > 160 || rk > 160) with a per-leg rising-edge state machine using 20° hysteresis (arm at <140°, fire at >160°). Cadence is now medically realistic instead of 10–30× inflated.
## 2. Camera input format — recording_screen.dart

Detects platform: Android concatenates all YUV planes for NV21; iOS uses single-plane BGRA8888
Reads actual sensor orientation from _cameraController.description.sensorOrientation instead of hardcoding 90°
## 3. Skeleton coordinate transform — skeleton_painter.dart

Accepts InputImageRotation rotation parameter
Applies correct axis-swap transform per rotation (90°/270°/180°/0°) so the skeleton aligns with the body on screen instead of rendering in the wrong quadrant
New Implementations
## 4. PDF Generator — pdf_generator.dart

Full A4 report: header bar, score/risk banner, 6-row metrics table (colour-coded Normal/Good/Poor), AI summary, abnormalities list, exercise suggestions, risk assessment, medical disclaimer footer
generateSessionReport(session, report) → Uint8List; sharePdf() opens the system share sheet
## 5. Video Analysis Service — video_analysis_service.dart

Extracts frames at 5 fps by seeking a VideoPlayerController and capturing via RenderRepaintBoundary.toImage()
Uses PoseDetectionMode.single (correct for non-sequential frames)
Feeds each frame through GaitAnalysisService.processFrame() then returns computeSessionMetrics()
Throws descriptive exceptions for short videos or insufficient pose detections (<5)
## 6. Upload Screen — upload_screen.dart

Hidden VideoPlayer + RepaintBoundary off-screen (left: -4000) keeps the key valid during analysis without being visible
_analyzeVideo() runs the full ML pipeline → saves session + video to Supabase → generates report → navigates to ResultsScreen
Live progress percentage shown during analysis; error display with retry on failure
## 7. PDF button wiring — results_screen.dart

"Export PDF Report" button calls _exportPdf() which generates and shares the PDF; shows loading state during generation
