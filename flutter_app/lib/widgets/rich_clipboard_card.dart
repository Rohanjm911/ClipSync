import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class RichClipboardCard extends StatelessWidget {
  final HistoryItem item;
  final bool isLocal;
  final bool isRevealed;
  final VoidCallback onCopy;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleReveal;
  final bool isCompact;

  const RichClipboardCard({
    super.key,
    required this.item,
    required this.isLocal,
    this.isRevealed = false,
    required this.onCopy,
    this.onTogglePin,
    this.onDelete,
    this.onToggleReveal,
    this.isCompact = false,
  });

  static Color? _parseColor(String raw) {
    final text = raw.trim();
    final hexRegex = RegExp(
      r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
    );
    if (hexRegex.hasMatch(text)) {
      try {
        String hex = text.substring(1);
        if (hex.length == 3) {
          hex = hex.split('').map((c) => '$c$c').join();
        }
        if (hex.length == 6) {
          hex = 'FF$hex';
        }
        return Color(int.parse(hex, radix: 16));
      } catch (_) {
        return null;
      }
    }

    final rgbRegex = RegExp(
      r'^rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$',
      caseSensitive: false,
    );
    final match = rgbRegex.firstMatch(text);
    if (match != null) {
      try {
        final r = int.parse(match.group(1)!);
        final g = int.parse(match.group(2)!);
        final b = int.parse(match.group(3)!);
        if (r <= 255 && g <= 255 && b <= 255) {
          return Color.fromARGB(255, r, g, b);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static bool _isUrl(String raw) {
    final text = raw.trim();
    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      return false;
    }
    final uri = Uri.tryParse(text);
    return uri != null && uri.hasAuthority;
  }

  static String? _detectCodeType(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    if ((text.startsWith('{') && text.endsWith('}')) ||
        (text.startsWith('[') && text.endsWith(']'))) {
      return 'JSON';
    }

    final cliStarters = [
      'curl ',
      'git ',
      'docker ',
      'npm ',
      'pnpm ',
      'yarn ',
      'cargo ',
      'flutter ',
      'pip ',
    ];
    if (cliStarters.any((s) => text.startsWith(s))) {
      return 'CLI / BASH';
    }

    final codeKeywords = [
      'function ',
      'const ',
      'let ',
      'var ',
      'import ',
      'export ',
      'class ',
      'def ',
      'fn ',
      'pub fn ',
    ];
    if (codeKeywords.any((k) => text.contains(k))) {
      return 'CODE';
    }

    if (text.contains('\n') &&
        (text.contains('{') || text.contains(';') || text.contains('=>'))) {
      return 'SNIPPET';
    }

    return null;
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final parsedColor = !item.isSensitive ? _parseColor(item.textData) : null;
    final isUrl = !item.isSensitive && _isUrl(item.textData);
    final codeType = (!item.isSensitive && parsedColor == null && !isUrl)
        ? _detectCodeType(item.textData)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.95),
        border: Border.all(
          color: item.isPinned
              ? AppColors.accentPrimary.withValues(alpha: 0.8)
              : AppColors.borderSubtle,
          width: item.isPinned ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: item.isPinned
            ? [
                BoxShadow(
                  color: AppColors.accentPrimary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Device badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isLocal
                            ? AppColors.accentPrimary.withValues(alpha: 0.15)
                            : AppColors.statusSuccess.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isLocal
                              ? AppColors.accentPrimary.withValues(alpha: 0.3)
                              : AppColors.statusSuccess.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLocal ? Icons.devices : Icons.cloud_done,
                            size: 11,
                            color: isLocal
                                ? AppColors.accentPrimary
                                : AppColors.statusSuccess,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLocal ? 'This Device' : item.originDeviceName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isLocal
                                  ? AppColors.accentPrimary
                                  : AppColors.statusSuccess,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Type Badge
                    if (item.isSensitive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.statusWarning.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 10,
                              color: AppColors.statusWarning,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sensitive Masked',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusWarning,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (parsedColor != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: parsedColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: parsedColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: parsedColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Color Swatch',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isUrl)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.accentCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 11,
                              color: AppColors.accentCyan,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Web Link',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (codeType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.accentPrimary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.code,
                              size: 11,
                              color: AppColors.accentPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              codeType,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    Text(
                      _formatTimeAgo(item.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Card actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCompact) ...[
                      if (item.isSensitive && onToggleReveal != null)
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isRevealed
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: isRevealed ? 'Mask secret' : 'Reveal secret',
                          onPressed: onToggleReveal,
                        ),
                      if (onTogglePin != null)
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            item.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 15,
                            color: item.isPinned
                                ? AppColors.accentPrimary
                                : AppColors.textMuted,
                          ),
                          tooltip: item.isPinned ? 'Unpin' : 'Pin to top',
                          onPressed: onTogglePin,
                        ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.copy,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'Copy to OS clipboard',
                        onPressed: onCopy,
                      ),
                      if (onDelete != null)
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                          tooltip: 'Delete item',
                          onPressed: onDelete,
                        ),
                    ] else ...[
                      InkWell(
                        onTap: onCopy,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                size: 12,
                                color: AppColors.accentPrimary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Card Body: Rich Preview Render
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _buildBodyContent(context, parsedColor, isUrl, codeType),
          ),

          // Footer info (if not compact)
          if (!isCompact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'SHA-256: ${item.contentHash.substring(0, 20)}...',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontFamily: 'Consolas',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.textData.length} chars',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    Color? parsedColor,
    bool isUrl,
    String? codeType,
  ) {
    if (item.isSensitive && !isRevealed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.statusWarning.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, size: 16, color: AppColors.statusWarning),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '••••••••••••••••••••••••••••••••',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.statusWarning,
                  letterSpacing: 3,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Color Swatch Card
    if (parsedColor != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: parsedColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: parsedColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    item.textData,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Consolas',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RGB(${parsedColor.r.toInt()}, ${parsedColor.g.toInt()}, ${parsedColor.b.toInt()}) • Alpha ${(parsedColor.a * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Web URL Card
    if (isUrl) {
      final uri = Uri.tryParse(item.textData.trim());
      final host = uri?.host ?? 'Link';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.accentCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.public,
                size: 20,
                color: AppColors.accentCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    item.textData.trim(),
                    maxLines: isCompact ? 1 : 2,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Code / CLI Terminal Card
    if (codeType != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF090D16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terminal Topbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceElevated.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    codeType,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SelectableText(
                item.textData,
                maxLines: isCompact ? 3 : null,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE2E8F0),
                  fontFamily: 'Consolas',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Standard Text Card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: SelectableText(
        item.textData,
        maxLines: isCompact ? 2 : null,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }
}
