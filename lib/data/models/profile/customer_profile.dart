import 'scenario_session.dart';

class CustomerProfile {
  final String id;
  final String name;
  final String notes;
  final List<String> attachmentPaths;
  final List<ScenarioSession> sessions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerProfile({
    required this.id,
    required this.name,
    this.notes = '',
    this.attachmentPaths = const [],
    this.sessions = const [],
    required this.createdAt,
    required this.updatedAt,
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notes': notes,
        'attachmentPaths': attachmentPaths,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  CustomerProfile copyWith({
    String? id,
    String? name,
    String? notes,
    List<String>? attachmentPaths,
    List<ScenarioSession>? sessions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CustomerProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
        attachmentPaths: attachmentPaths ?? this.attachmentPaths,
        sessions: sessions ?? this.sessions,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  ScenarioSession? sessionById(String sessionId) {
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }
}
