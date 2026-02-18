import 'package:flutter/material.dart';
import '../../data/models/profile/session_history_entry.dart';

class HistorySidebar extends StatefulWidget {
  final List<SessionHistoryEntry> history;

  const HistorySidebar({super.key, required this.history});

  @override
  State<HistorySidebar> createState() => _HistorySidebarState();
}

class _HistorySidebarState extends State<HistorySidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _collapsed ? 40 : 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _collapsed ? Icons.chevron_left : Icons.chevron_right,
                  ),
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  tooltip: _collapsed ? 'Show history' : 'Hide history',
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 4),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('${widget.history.length}'),
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
          ),
          if (!_collapsed)
            Expanded(
              child: widget.history.isEmpty
                  ? Center(
                      child: Text(
                        'No answers yet',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: widget.history.length,
                      itemBuilder: (_, i) {
                        final entry = widget.history[i];
                        return _HistoryEntryTile(
                          entry: entry,
                          index: i + 1,
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  final SessionHistoryEntry entry;
  final int index;

  const _HistoryEntryTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.questionTitle,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.answerLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSecondaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
