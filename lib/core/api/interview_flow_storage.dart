import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists institute **campus confirmation** and per-job **interview step** state
/// (current step index + candidate rows HR/org advances each round).
///
/// Replace with API calls when backend is ready.
class InterviewFlowStorage {
  InterviewFlowStorage._();

  static const String _prefix = 'interview_flow_v1_';

  static String _key(int jobId) => '$_prefix$jobId';

  /// Canonical step titles (1-based index in UI: Step 1 … Step N).
  static const List<String> stepTitles = [
    'Profile Verification',
    'Screening Round',
    'Technical Interview',
    'Offer Letter',
  ];

  static int get totalSteps => stepTitles.length;

  static Future<void> saveAfterCampusConfirm(
    int jobId,
    String jobTitle,
    List<Map<String, dynamic>> students,
  ) async {
    await init();
    final data = <String, dynamic>{
      'jobTitle': jobTitle,
      'stepIndex': 0,
      'students': students,
      'flowComplete': false,
    };
    await _prefs!.setString(_key(jobId), jsonEncode(data));
  }

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// `true` after campus confirmation was submitted for this job.
  static Future<bool> hasCampusConfirmed(int jobId) async {
    await init();
    return _prefs!.containsKey(_key(jobId));
  }

  /// Show **Interview Steps** on Job Details: campus done and flow not finished.
  static Future<bool> shouldShowInterviewStepsButton(int jobId) async {
    final s = await load(jobId);
    if (s == null) return false;
    return !s.flowComplete;
  }

  /// Latest persisted state, or `null` if none.
  static Future<InterviewFlowSnapshot?> load(int jobId) async {
    await init();
    final raw = _prefs!.getString(_key(jobId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final students = (map['students'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          <Map<String, dynamic>>[];
      return InterviewFlowSnapshot(
        jobId: jobId,
        jobTitle: (map['jobTitle'] ?? '').toString(),
        stepIndex: map['stepIndex'] is int ? map['stepIndex'] as int : int.tryParse('${map['stepIndex']}') ?? 0,
        students: students,
        flowComplete: map['flowComplete'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  /// After HR taps **Done**: advance step and keep only [selectedForNext] for the next round.
  static Future<void> advanceStep(
    int jobId,
    List<Map<String, dynamic>> selectedForNext,
  ) async {
    await init();
    final snap = await load(jobId);
    if (snap == null) return;
    final nextIndex = (snap.stepIndex + 1).clamp(0, totalSteps - 1);
    final data = <String, dynamic>{
      'jobTitle': snap.jobTitle,
      'stepIndex': nextIndex,
      'students': selectedForNext,
      'flowComplete': snap.flowComplete,
    };
    await _prefs!.setString(_key(jobId), jsonEncode(data));
  }

  /// Call when the last interview step is submitted.
  static Future<void> markFlowComplete(int jobId) async {
    await init();
    final snap = await load(jobId);
    if (snap == null) return;
    final data = <String, dynamic>{
      'jobTitle': snap.jobTitle,
      'stepIndex': snap.stepIndex,
      'students': snap.students,
      'flowComplete': true,
    };
    await _prefs!.setString(_key(jobId), jsonEncode(data));
  }

  /// Remove flow data for a job (e.g. after offer closed).
  static Future<void> clear(int jobId) async {
    await init();
    await _prefs!.remove(_key(jobId));
  }
}

class InterviewFlowSnapshot {
  const InterviewFlowSnapshot({
    required this.jobId,
    required this.jobTitle,
    required this.stepIndex,
    required this.students,
    this.flowComplete = false,
  });

  final int jobId;
  final String jobTitle;
  /// 0-based, aligned with [InterviewFlowStorage.stepTitles].
  final int stepIndex;
  final List<Map<String, dynamic>> students;
  final bool flowComplete;
}
