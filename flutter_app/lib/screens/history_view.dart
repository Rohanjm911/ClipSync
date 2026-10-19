import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rich_clipboard_card.dart';

class HistoryView extends StatefulWidget {
  final ClipSyncState state;

  const HistoryView({super.key, required this.state});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'all'; // all, pinned, sensitive
  final Set<String> _revealedItemIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
        title: const Text(
          'Clear Clipboard History?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will purge all local encrypted history records. This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
            ),
            onPressed: () {
              widget.state.clearHistory();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    var items = widget.state.history.where((item) {
      if (_activeFilter == 'pinned' && !item.isPinned) return false;
      if (_activeFilter == 'sensitive' && !item.isSensitive) return false;
      if (query.isNotEmpty) {
        return item.textData.toLowerCase().contains(query) ||
            item.originDeviceName.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clipboard History & Vault',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.state.history.length} encrypted record(s) stored locally.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (widget.state.history.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _confirmClearHistory,
                  icon: const Icon(
                    Icons.delete_sweep,
                    size: 16,
                    color: AppColors.statusError,
                  ),
                  label: const Text(
                    'Clear Vault',
                    style: TextStyle(color: AppColors.statusError),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Filter Bar (Responsive for Mobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search clipboard history by keyword...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Pinned', 'pinned'),
                  _buildFilterChip('Sensitive', 'sensitive'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Items List
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'No matching clipboard items found.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isRevealed = _revealedItemIds.contains(item.id);
                return _buildHistoryCard(item, isRevealed);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary
              : AppColors.bgSurfaceElevated,
          border: Border.all(
            color: isSelected
                ? AppColors.accentPrimary
                : AppColors.borderStrong,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item, bool isRevealed) {
    final isLocal = item.originDeviceId == widget.state.localDevice.deviceId;

    return RichClipboardCard(
      item: item,
      isLocal: isLocal,
      isRevealed: isRevealed,
      isCompact: false,
      onToggleReveal: () {
        setState(() {
          if (isRevealed) {
            _revealedItemIds.remove(item.id);
          } else {
            _revealedItemIds.add(item.id);
          }
        });
      },
      onTogglePin: () => widget.state.togglePin(item.id),
      onDelete: () => widget.state.deleteHistoryItem(item.id),
      onCopy: () {
        widget.state.copyToSystemClipboard(item.textData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Copied to clipboard'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.accentPrimary,
          ),
        );
      },
    );
  }
}
