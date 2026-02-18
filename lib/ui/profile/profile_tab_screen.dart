import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile/customer_profile.dart';
import '../../data/services/file_import_export_service.dart';
import '../../providers/profile_providers.dart';
import '../../providers/tab_providers.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'profile_header_widget.dart';
import 'attachments_panel.dart';
import 'sessions_list_widget.dart';

class ProfileTabScreen extends ConsumerStatefulWidget {
  final String profileId;

  const ProfileTabScreen({super.key, required this.profileId});

  @override
  ConsumerState<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends ConsumerState<ProfileTabScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileByIdProvider(widget.profileId));

    // Ensure tab is open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileAsync.whenData((profile) {
        if (profile != null) {
          ref
              .read(openTabsProvider.notifier)
              .openProfile(widget.profileId, profile.name);
        }
      });
    });

    return profileAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(
          error: e,
          onRetry: () =>
              ref.invalidate(profileByIdProvider(widget.profileId))),
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text('Profile not found.'));
        }
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 40,
            titleSpacing: 0,
            title: const SizedBox.shrink(),
            actions: [
              TextButton.icon(
                onPressed:
                    _exporting ? null : () => _exportProfile(context, profile),
                icon: _exporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, size: 16),
                label: const Text('Export Profile'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderWidget(profile: profile),
                const Divider(height: 1),
                const SizedBox(height: 12),
                AttachmentsPanel(profile: profile),
                const Divider(height: 24),
                SessionsListWidget(profile: profile),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportProfile(
      BuildContext context, CustomerProfile profile) async {
    setState(() => _exporting = true);
    try {
      final service = FileImportExportService();
      final safeName = profile.name
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final path =
          await service.pickJsonFileToExport('profile_$safeName.json');
      if (path == null) return;
      final repo = ref.read(profileRepositoryProvider);
      await repo.exportToFile(profile, path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile exported to $path')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
