import 'scenario_session.dart';
import '../scenario/scenario.dart' show ScenarioSource;

class CustomerProfile {
  final String id;
  final String name;
  final String notes;
  final List<String> attachmentPaths;
  final List<ScenarioSession> sessions;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Origin of this profile. Defaults to [ScenarioSource.local] for all
  /// existing files (backward-compatible — missing key → 'local').
  /// Reuses [ScenarioSource] since the semantics are identical.
  final ScenarioSource source;

  const CustomerProfile({
    required this.id,
    required this.name,
    this.notes = '',
    this.attachmentPaths = const [],
    this.sessions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.source = ScenarioSource.local,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      CustomerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String? ?? '',
        attachmentPaths:
            (json['attachmentPaths'] as List<dynamic>? ?? []).cast<String>(),
        sessions: (json['sessions'] as List<dynamic>? ?? [])
            .map((e) =>
                ScenarioSession.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        source: ScenarioSource.values.byName(
          json['source'] as String? ?? ScenarioSource.local.name,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notes': notes,
        'attachmentPaths': attachmentPaths,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'source': source.name,
      };

  CustomerProfile copyWith({
    String? id,
    String? name,
    String? notes,
    List<String>? attachmentPaths,
    List<ScenarioSession>? sessions,
    DateTime? createdAt,
    DateTime? updatedAt,
    ScenarioSource? source,
  }) =>
      CustomerProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
        attachmentPaths: attachmentPaths ?? this.attachmentPaths,
        sessions: sessions ?? this.sessions,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        source: source ?? this.source,
      );

  ScenarioSession? sessionById(String sessionId) {
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }
}
