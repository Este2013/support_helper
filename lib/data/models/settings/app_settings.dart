/// Role decoded from the server's /api/me response.
/// Controls whether the app can push changes back to the server.
enum SyncRole { viewer, editor }

/// Application-level settings stored in `{appSupportDir}/support_helper/settings.json`.
///
/// All fields are optional so the app works fully offline when no server is
/// configured. Missing keys in the JSON file default gracefully.
///
/// **Security note:** [authToken] is NOT serialised to `settings.json`.
/// It is stored separately in the platform secure store
/// (`flutter_secure_storage` → Windows Credential Manager on desktop)
/// and merged back by [SettingsRepository.load].
class AppSettings {
  /// Base URL of the sync server, e.g. `https://support.mycompany.com`.
  /// Null or empty string means no server is configured.
  final String? serverUrl;

  /// Bearer token issued by the server admin and pasted by the user.
  /// Sent as `Authorization: Bearer <token>` on every API request.
  final String? authToken;

  /// Role decoded from [GET /api/me] after a successful Test Connection.
  /// Defaults to [SyncRole.viewer] until verified.
  final SyncRole role;

  /// Whether profile sync is enabled (opt-in, default false).
  /// Scenarios are always synced when a server is configured.
  final bool syncProfilesEnabled;

  /// Timestamp of the last successful full sync. Informational only.
  final DateTime? lastSyncedAt;

  const AppSettings({
    this.serverUrl,
    this.authToken,
    this.role = SyncRole.viewer,
    this.syncProfilesEnabled = false,
    this.lastSyncedAt,
  });

  /// True when a server URL has been configured.
  bool get hasServer =>
      serverUrl != null && serverUrl!.trim().isNotEmpty;

  /// True when the current role allows pushing changes to the server.
  bool get canPush => role == SyncRole.editor;

  /// Deserialises from `settings.json`. [authToken] is intentionally ignored
  /// here — it lives in the platform secure store and is merged in by
  /// [SettingsRepository.load].
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        serverUrl: json['serverUrl'] as String?,
        // authToken: NOT read from JSON — stored in platform secure storage.
        role: SyncRole.values.byName(
          json['role'] as String? ?? SyncRole.viewer.name,
        ),
        syncProfilesEnabled:
            json['syncProfilesEnabled'] as bool? ?? false,
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.parse(json['lastSyncedAt'] as String)
            : null,
      );

  /// Serialises to `settings.json`. [authToken] is intentionally omitted —
  /// it is written to the platform secure store by [SettingsRepository.save].
  Map<String, dynamic> toJson() => {
        if (serverUrl != null) 'serverUrl': serverUrl,
        // authToken: NOT written to JSON — stored in platform secure storage.
        'role': role.name,
        'syncProfilesEnabled': syncProfilesEnabled,
        if (lastSyncedAt != null)
          'lastSyncedAt': lastSyncedAt!.toIso8601String(),
      };

  AppSettings copyWith({
    String? serverUrl,
    bool clearServerUrl = false,
    String? authToken,
    bool clearAuthToken = false,
    SyncRole? role,
    bool? syncProfilesEnabled,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
  }) =>
      AppSettings(
        serverUrl:
            clearServerUrl ? null : (serverUrl ?? this.serverUrl),
        authToken:
            clearAuthToken ? null : (authToken ?? this.authToken),
        role: role ?? this.role,
        syncProfilesEnabled:
            syncProfilesEnabled ?? this.syncProfilesEnabled,
        lastSyncedAt: clearLastSyncedAt
            ? null
            : (lastSyncedAt ?? this.lastSyncedAt),
      );
}
