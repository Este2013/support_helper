import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_providers.dart';
import '../../providers/scenario_providers.dart';
import '../home/home_screen.dart';
import '../editor/editor_shell.dart';
import '../settings/settings_dialog.dart';

class AppShell extends ConsumerStatefulWidget {
  /// The child widget provided by GoRouter for the currently matched route.
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _homeIndex = 0;
  static const _editorIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Eagerly load settings (including token from platform secure storage) on
    // the first frame so the startup sync has credentials available immediately.
    ref.watch(appSettingsNotifierProvider);

    // Trigger the startup sync once. The provider is keepAlive so it only
    // fires one pull per app session. Result is intentionally ignored here
    // — success invalidates the scenario list providers automatically.
    ref.watch(scenarioStartupSyncProvider);

    final tabs = ref.watch(openTabsProvider);
    final location = GoRouterState.of(context).uri.toString();

    int navIndex = 0;
    if (location.startsWith('/editor')) navIndex = 1;

    // Whether we are on a persistent top-level tab vs a dynamic sub-route.
    final bool isHome = location == '/';
    final bool isEditorList = location == '/editor';
    // Sub-routes of /editor (new, :id/:version) go through GoRouter's child.
    final bool isEditorSub =
        location.startsWith('/editor/');
    // Profile / session routes.
    final bool isProfile = location.startsWith('/profile');

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navIndex,
            onDestinationSelected: (index) {
              if (index == 0) context.go('/');
              if (index == 1) context.go('/editor');
            },
            labelType: NavigationRailLabelType.all,
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const SettingsDialog(),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: Text('Editor'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (tabs.isNotEmpty)
                  _ProfileTabBar(tabs: tabs, location: location),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Home (persistent, always in tree) ────────────────
                      Offstage(
                        offstage: !isHome,
                        child: const _KeepAliveView(child: HomeScreen()),
                      ),
                      // ── Editor list panel (persistent, always in tree) ───
                      // Hidden when a sub-editor route or profile is active,
                      // but never destroyed so the list scroll is preserved.
                      Offstage(
                        offstage: !isEditorList,
                        child: const _KeepAliveView(child: EditorShell()),
                      ),
                      // ── GoRouter child: editor sub-routes + profile ───────
                      // These are rendered on top when active.
                      if (isEditorSub || isProfile) widget.child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a widget with [AutomaticKeepAliveClientMixin] so it is never
/// discarded by the [IndexedStack] when its slot is not active.
class _KeepAliveView extends StatefulWidget {
  final Widget child;
  const _KeepAliveView({required this.child});

  @override
  State<_KeepAliveView> createState() => _KeepAliveViewState();
}

class _KeepAliveViewState extends State<_KeepAliveView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by mixin
    return widget.child;
  }
}

// ── Profile tab bar ──────────────────────────────────────────────────────────

class _ProfileTabBar extends ConsumerWidget {
  final List<OpenTab> tabs;
  final String location;

  const _ProfileTabBar({required this.tabs, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((tab) {
                  final isActive =
                      location.startsWith('/profile/${tab.profileId}');
                  return _ProfileTab(
                    tab: tab,
                    isActive: isActive,
                    onTap: () => context.go('/profile/${tab.profileId}'),
                    onClose: () {
                      ref
                          .read(openTabsProvider.notifier)
                          .closeTab(tab.profileId);
                      if (isActive) context.go('/');
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final OpenTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ProfileTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.surfaceContainerHighest
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 14),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                tab.displayName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
