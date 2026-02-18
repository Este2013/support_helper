import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tab_providers.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(openTabsProvider);
    final location = GoRouterState.of(context).uri.toString();

    int navIndex = 0;
    if (location.startsWith('/editor')) navIndex = 1;

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
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                  final isActive = location.startsWith('/profile/${tab.profileId}');
                  return _ProfileTab(
                    tab: tab,
                    isActive: isActive,
                    onTap: () => context.go('/profile/${tab.profileId}'),
                    onClose: () {
                      ref.read(openTabsProvider.notifier).closeTab(tab.profileId);
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
