import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../domain/models/session_model.dart';

class SupabaseService {
    // Update session with video URL
    Future<void> updateSessionVideoUrl(String sessionId, String videoUrl) async {
      await _client
          .from('sessions')
          .update({'video_url': videoUrl})
          .eq('id', sessionId);
    }
  final _client = Supabase.instance.client;

  // Auth
  Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  String? get currentUserId => _client.auth.currentUser?.id;

  // Sessions
  Future<String> saveSession(SessionModel session) async {
    final response = await _client
        .from('sessions')
        .insert(session.toMap())
        .select('id')
        .single();
    return response['id'];
  }

  Future<List<SessionModel>> getUserSessions() async {
    final data = await _client
        .from('sessions')
        .select()
        .eq('user_id', currentUserId!)
        .order('session_date', ascending: false)
        .limit(30);
    return (data as List).map((e) => SessionModel.fromMap(e)).toList();
  }

  Future<SessionModel?> getLastSession() async {
    final data = await _client
        .from('sessions')
        .select()
        .eq('user_id', currentUserId!)
        .order('session_date', ascending: false)
        .limit(2);
    final list = data as List;
    if (list.length < 2) return null;
    return SessionModel.fromMap(list[1]); // second most recent = previous
  }

  // Reports
  Future<void> saveReport({
    required String sessionId,
    required Map<String, dynamic> report,
  }) async {
    await _client.from('reports').insert({
      'session_id': sessionId,
      'user_id': currentUserId,
      'summary': report['summary'],
      'abnormalities': report['abnormalities'],
      'exercise_suggestions': report['exercise_suggestions'],
      'risk_assessment': report['risk_assessment'],
      'improvement_percentage': report['improvement_percentage'],
    });
  }

  Future<List<Map<String, dynamic>>> getUserReports() async {
    return await _client
        .from('reports')
        .select()
        .eq('user_id', currentUserId!)
        .order('generated_at', ascending: false);
  }

  // Video upload
  Future<String?> uploadVideo(String filePath, String sessionId) async {
    final file = File(filePath);
    await _client.storage
        .from('session-videos')
        .upload('$currentUserId/$sessionId.mp4', file);
    return _client.storage
        .from('session-videos')
        .getPublicUrl('$currentUserId/$sessionId.mp4');
  }
}
