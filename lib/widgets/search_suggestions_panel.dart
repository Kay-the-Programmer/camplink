import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_colors.dart';
import '../services/search_history_service.dart';

class SearchSuggestionsPanel extends StatefulWidget {
  final ValueChanged<String> onSelect;

  const SearchSuggestionsPanel({super.key, required this.onSelect});

  @override
  State<SearchSuggestionsPanel> createState() => _SearchSuggestionsPanelState();
}

class _SearchSuggestionsPanelState extends State<SearchSuggestionsPanel> {
  static const _trending = [
    'food',
    'groceries',
    'textbooks',
    'stationery',
    'electronics',
    'airtime',
    'USB cable',
    'calculator',
    'clothes',
    'services',
  ];

  final _svc = SearchHistoryService();
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await _svc.load();
    if (mounted) setState(() => _recent = h);
  }

  Future<void> _remove(String q) async {
    await _svc.remove(q);
    _load();
  }

  Future<void> _clearAll() async {
    await _svc.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_recent.isNotEmpty) ...[
          _SectionHeader(
            icon: Symbols.history,
            label: 'Recent searches',
            color: scheme.primary,
            action: TextButton(
              onPressed: _clearAll,
              child: const Text('Clear all'),
            ),
          ),
          const SizedBox(height: 4),
          ..._recent.map(
            (q) => _SuggestionTile(
              icon: Symbols.history,
              iconColor: scheme.onSurfaceVariant,
              label: q,
              onTap: () => widget.onSelect(q),
              trailing: IconButton(
                icon: Icon(Symbols.close,
                    size: 16, color: scheme.onSurfaceVariant),
                onPressed: () => _remove(q),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _SectionHeader(
          icon: Symbols.trending_up,
          label: 'Trending on CampLink',
          color: kOrange,
        ),
        const SizedBox(height: 4),
        ..._trending.map(
          (q) => _SuggestionTile(
            icon: Symbols.trending_up,
            iconColor: kOrange,
            label: q,
            onTap: () => widget.onSelect(q),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? action;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
        const Spacer(),
        ?action,
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SuggestionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 15)),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
