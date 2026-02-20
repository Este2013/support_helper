import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/settings/app_settings.dart';
import '../../data/services/remote_api_client.dart';
import '../../data/services/scenario_sync_service.dart';
import '../../providers/profile_providers.dart';
import '../../providers/scenario_providers.dart';
import '../../providers/settings_provider.dart';

/// Modal dialog for configuring server sync settings.
///
/// Opened from the settings icon at the bottom of the [NavigationRail].
/// Shows server URL, API token, role (read-only, populated by Test Connection),
/// profile sync toggle, and action buttons.
class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _urlCtrl;
  late TextEditingController _tokenCtrl;
  bool _tokenObscured = true;
  bool _syncProfiles = false;

  /// Future that loads the initial settings (URL + encrypted token) once.
  /// The [FutureBuilder] in [build] waits for this before rendering the fields,
  /// guaranteeing controllers are populated before the user sees them.
  late Future<AppSettings> _settingsFuture;

  /// One-shot flag — controllers are populated from [_settingsFuture] exactly
  /// once inside the FutureBuilder builder, then user edits take over.
  bool _settingsInitialised = false;

  /// Inline feedback message shown below the token field.
  String? _testMessage;
  bool _testSuccess = false;
  bool _testLoading = false;
  bool _syncLoading = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    _tokenCtrl = TextEditingController();
    // Load settings (including the token from secure storage) once.
    // FutureBuilder renders the form fields only after this resolves.
    _settingsFuture = ref.read(settingsRepositoryProvider).load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = ref.read(appSettingsNotifierProvider).valueOrNull ??
        const AppSettings();
    final url = _urlCtrl.text.trim();
    final token = _tokenCtrl.text.trim();

    // Case 1: No server URL — disconnect cleanly and reset role to viewer.
    if (url.isEmpty) {
      await ref.read(appSettingsNotifierProvider.notifier).save(
            current.copyWith(
              clearServerUrl: true,
              clearAuthToken: token.isEmpty,
              authToken: token.isEmpty ? null : token,
              syncProfilesEnabled: _syncProfiles,
              role: SyncRole.viewer,
            ),
          );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Case 2: URL and token are unchanged — role already verified, save other prefs.
    final urlUnchanged = url == (current.serverUrl ?? '');
    final tokenUnchanged = token == (current.authToken ?? '');
    if (urlUnchanged && tokenUnchanged) {
      await ref.read(appSettingsNotifierProvider.notifier).save(
            current.copyWith(syncProfilesEnabled: _syncProfiles),
          );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Case 3: URL or token changed — verify connection and fetch role before saving.
    // _testConnection() saves settings (including the new role) on success.
    await _testConnection();
    if (!mounted) return;
    if (_testSuccess) {
      // Persist the syncProfiles toggle on top of what _testConnection() saved.
      final updated = ref.read(appSettingsNotifierProvider).valueOrNull ??
          const AppSettings();
      await ref.read(appSettingsNotifierProvider.notifier).save(
            updated.copyWith(syncProfilesEnabled: _syncProfiles),
          );
      if (mounted) Navigator.of(context).pop();
    }
    // If !_testSuccess: _testMessage is already set with the error. Dialog stays open.
  }

  /// Calls [GET /api/ping] then [GET /api/me] to verify the server URL and
  /// token. On success, persists the discovered role to settings.
  Future<void> _testConnection() async {
    final url = _urlCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testLoading = false;
        _testSuccess = false;
        _testMessage = 'Enter a server URL first.';
      });
      return;
    }

    setState(() {
      _testLoading = true;
      _testMessage = null;
    });

    final client =
        RemoteApiClient(baseUrl: url, authToken: token.isEmpty ? null : token);
    try {
      // 1. Health check
      await client.get('/api/ping');

      // 2. Fetch role
      final me = await client.get('/api/me');
      final roleName = me['role'] as String? ?? SyncRole.viewer.name;
      final role = SyncRole.values.byName(roleName);

      // Persist the discovered role alongside current settings.
      final current = ref.read(appSettingsNotifierProvider).valueOrNull ??
          const AppSettings();
      await ref.read(appSettingsNotifierProvider.notifier).save(
            current.copyWith(
              serverUrl: url,
              authToken: token.isEmpty ? null : token,
              clearAuthToken: token.isEmpty,
              role: role,
              syncProfilesEnabled: _syncProfiles,
            ),
          );

      if (!mounted) return;
      setState(() {
        _testLoading = false;
        _testSuccess = true;
        _testMessage = role == SyncRole.editor
            ? 'Connected. Role: Editor (can push to server).'
            : 'Connected. Role: Viewer (pull only).';
      });
    } on RemoteApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _testLoading = false;
        _testSuccess = false;
        _testMessage = 'Connection failed: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testLoading = false;
        _testSuccess = false;
        _testMessage = 'Unexpected error: $e';
      });
    } finally {
      client.dispose();
    }
  }

  /// Manually triggers a scenario (and optionally profile) pull from the server.
  Future<void> _syncNow() async {
    final syncService = ref.read(scenarioSyncServiceProvider);
    if (syncService == null) {
      setState(() {
        _testSuccess = false;
        _testMessage =
            'No server configured. Enter a URL and test connection first.';
      });
      return;
    }
    setState(() => _syncLoading = true);
    try {
      final SyncResult result = await syncService.pullAll();
      ref.invalidate(scenarioListProvider);
      ref.invalidate(scenarioListWithStatusProvider);

      int profilesPulled = 0;
      final profileSync = ref.read(profileSyncServiceProvider);
      if (profileSync != null) {
        final profileResult = await profileSync.pullAll();
        profilesPulled = profileResult.pulled;
        if (profilesPulled > 0) ref.invalidate(profileListProvider);
      }

      // Update lastSyncedAt.
      final current = ref.read(appSettingsNotifierProvider).valueOrNull ??
          const AppSettings();
      await ref.read(appSettingsNotifierProvider.notifier).save(
            current.copyWith(lastSyncedAt: DateTime.now()),
          );
      if (!mounted) return;
      final totalPulled = result.pulled + profilesPulled;
      setState(() {
        _syncLoading = false;
        _testSuccess = true;
        _testMessage = totalPulled > 0
            ? 'Sync complete: $totalPulled item${totalPulled == 1 ? '' : 's'} updated.'
            : 'Sync complete: everything up-to-date.';
      });
    } on RemoteApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _syncLoading = false;
        _testSuccess = false;
        _testMessage = 'Sync failed: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncLoading = false;
        _testSuccess = false;
        _testMessage = 'Sync error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Watch the live settings for role and last-synced display — these update
    // in real time after Test Connection / Sync Now without reopening the dialog.
    final liveSettings = ref.watch(appSettingsNotifierProvider).valueOrNull;

    return AlertDialog(
      title: const Text('Server Settings'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: FutureBuilder<AppSettings>(
            future: _settingsFuture,
            builder: (context, snapshot) {
              // ── Loading ──────────────────────────────────────────────────
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // ── Error ────────────────────────────────────────────────────
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Could not load settings: ${snapshot.error}',
                    style: TextStyle(color: colorScheme.error),
                  ),
                );
              }

              // ── Data: populate controllers exactly once ───────────────────
              final loaded = snapshot.requireData;
              if (!_settingsInitialised) {
                _settingsInitialised = true;
                _urlCtrl.text = loaded.serverUrl ?? '';
                _tokenCtrl.text = loaded.authToken ?? '';
                _syncProfiles = loaded.syncProfilesEnabled;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Server URL ──────────────────────────────────────────
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://support.mycompany.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),

                  // ── API Token ───────────────────────────────────────────
                  TextField(
                    controller: _tokenCtrl,
                    obscureText: _tokenObscured,
                    decoration: InputDecoration(
                      labelText: 'API Token',
                      hintText: 'Paste the token from your server admin',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_tokenObscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        tooltip:
                            _tokenObscured ? 'Show token' : 'Hide token',
                        onPressed: () =>
                            setState(() => _tokenObscured = !_tokenObscured),
                      ),
                    ),
                  ),

                  // ── Test Connection feedback ────────────────────────────
                  if (_testMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _testSuccess
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 16,
                          color: _testSuccess
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _testMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _testSuccess
                                  ? colorScheme.primary
                                  : colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),

                  // ── Role display (live, read-only) ──────────────────────
                  if (liveSettings != null && liveSettings.hasServer) ...[
                    Row(
                      children: [
                        Icon(
                          liveSettings.canPush
                              ? Icons.edit_outlined
                              : Icons.visibility_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          liveSettings.canPush
                              ? 'Role: Editor (can push to server)'
                              : 'Role: Viewer (pull only)',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Sync Profiles toggle ────────────────────────────────
                  SwitchListTile(
                    title: const Text('Sync customer profiles'),
                    subtitle: const Text(
                        'Pull and push profiles to the shared server'),
                    value: _syncProfiles,
                    onChanged: (v) => setState(() => _syncProfiles = v),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // ── Last synced ─────────────────────────────────────────
                  if (liveSettings?.lastSyncedAt != null) ...[
                    const Divider(height: 16),
                    Text(
                      'Last synced: ${_formatDateTime(liveSettings!.lastSyncedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // ── Left side: Test Connection + Sync Now ───────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: (_testLoading || _syncLoading) ? null : _testConnection,
              icon: _testLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check, size: 18),
              label: const Text('Test Connection'),
            ),
            TextButton.icon(
              onPressed: (_testLoading || _syncLoading) ? null : _syncNow,
              icon: _syncLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: const Text('Sync Now'),
            ),
          ],
        ),
        // ── Right side: Cancel + Save ───────────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
