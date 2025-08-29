// lib/features/home/widget/study_time/time_format.dart
// 역할: HH:MM:SS 포맷 유틸

String pad2(int n) => n.toString().padLeft(2, '0');

/// Duration → "HH:MM:SS" 문자열
String formatHms(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return '${pad2(h)}:${pad2(m)}:${pad2(s)}';
}