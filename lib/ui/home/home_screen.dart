import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_providers.dart';
import '../../providers/storage_provider.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'new_profile_dialog.dart';
import 'profile_list_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final storageAsync = ref.watch(storageServiceProvider);

    return storageAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(error: e),
      data: (_) {
        final profilesAsync = ref.watch(profileListProvider);
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Customer Profiles'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () => ref.invalidate(profileListProvider),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SearchBar(
                    hintText: 'Search profiles...',
                    leading: const Icon(Icons.search),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
              profilesAsync.when(
                loading: () => const SliverFillRemaining(
                    child: LoadingWidget()),
                error: (e, _) => SliverFillRemaining(
                    child: AppErrorWidget(
                        error: e,
                        onRetry: () =>
                            ref.invalidate(profileListProvider))),
                data: (profiles) {
                  final filtered = _search.isEmpty
                      ? profiles
                      : profiles
                          .where((p) => p.name
                              .toLowerCase()
                              .contains(_search.toLowerCase()))
                          .toList();

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline),
                            const SizedBox(height: 16),
                            Text(
                              _search.isEmpty
                                  ? 'No profiles yet.\nCreate one to get started.'
                                  : 'No profiles match "$_search".',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          ProfileListTile(profile: filtered[index]),
                      childCount: filtered.length,
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const NewProfileDialog(),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('New Profile'),
          ),
        );
      },
    );
  }
}
