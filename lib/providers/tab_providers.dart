import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab_providers.g.dart';

class OpenTab {
  final String profileId;
  final String displayName;

  const OpenTab({required this.profileId, required this.displayName});
}

@Riverpod(keepAlive: true)
class OpenTabs extends _$OpenTabs {
  @override
  List<OpenTab> build() => [];

  void openProfile(String profileId, String displayName) {
    if (state.any((t) => t.profileId == profileId)) return;
    state = [...state, OpenTab(profileId: profileId, displayName: displayName)];
  }

  void closeTab(String profileId) {
    state = state.where((t) => t.profileId != profileId).toList();
  }

  void updateDisplayName(String profileId, String name) {
    state = [
      for (final t in state)
        if (t.profileId == profileId)
          OpenTab(profileId: profileId, displayName: name)
        else
          t,
    ];
  }

  bool isOpen(String profileId) =>
      state.any((t) => t.profileId == profileId);
}
