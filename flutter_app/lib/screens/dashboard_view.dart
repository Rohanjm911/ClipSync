import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rich_clipboard_card.dart';
import '../widgets/first_launch_dialog.dart';

class DashboardView extends StatefulWidget {
  final ClipSyncState state;
  final VoidCallback onNavigateToPairing;
  final VoidCallback onNavigateToHistory;

  const DashboardView({
    super.key,
    required this.state,
    required this.onNavigateToPairing,
    required this.onNavigateToHistory,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _syncController = TextEditingController();

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  void _handleQuickSync() {
    final text = _syncController.text.trim();
    if (text.isNotEmpty) {
      widget.state.syncLocalText(text);
      _syncController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Text encrypted & broadcasted to paired devices'),
          backgroundColor: AppColors.statusSuccess,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pasteFromSystemClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      _syncController.text = data.text!;
    }
  }

  Future<void> _handleBluetoothSync() async {
    String text = _syncController.text.trim();
    if (text.isEmpty) {
      final clip = await Clipboard.getData('text/plain');
      if (!mounted) return;
      if (clip != null && clip.text != null && clip.text!.trim().isNotEmpty) {
        text = clip.text!.trim();
      }
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter or copy text first to sync via Bluetooth.',
          ),
          backgroundColor: AppColors.statusWarning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final res = await widget.state.syncViaBluetooth(text);
    _syncController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.bluetooth_connected,
              color: AppColors.accentCyan,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                res['message'] ?? 'Dispatched over Bluetooth Direct Sync',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.bgSurfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.accentCyan),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showBluetoothHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentCyan.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCyan.withValues(alpha: 0.18),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.bluetooth_audio,
                        color: AppColors.accentCyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bluetooth Direct Sync',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Offline P2P Synchronization',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'ClipSync allows direct offline clipboard sync between your Windows PC and Android phone without any Wi-Fi router or internet connection:',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBluetoothStep(
                  '1',
                  'Pair PC & Phone in Bluetooth Settings',
                  'Pair both devices once using Windows Bluetooth & Devices settings.',
                ),
                const SizedBox(height: 10),
                _buildBluetoothStep(
                  '2',
                  'Enable Bluetooth Tethering on Phone',
                  'On Android, go to Settings -> Network -> Hotspot & Tethering -> Turn on "Bluetooth Tethering".',
                ),
                const SizedBox(height: 10),
                _buildBluetoothStep(
                  '3',
                  'Connect from Windows & Sync!',
                  'On PC, right-click your phone in Bluetooth devices -> Connect using -> Access point. ClipSync now mirrors your clipboard instantly offline!',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Got it!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothStep(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentCyan),
          ),
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accentCyan,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangeNameDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FirstLaunchDialog(
        state: widget.state,
        onCompleted: (newName) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Device name changed to: "$newName"'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.state.connectionStatus;
    final history = widget.state.history;
    final activePeers = widget.state.pairedDevices
        .where((d) => !d.isRevoked)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Quick Rename
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Real-Time Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Icon(
                        widget.state.localDevice.icon,
                        size: 14,
                        color: AppColors.accentPrimary,
                      ),
                      Text(
                        '${widget.state.localDevice.deviceName} (${widget.state.localDevice.platform})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showChangeNameDialog(context),
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceElevated,
                            border: Border.all(color: AppColors.borderStrong),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 10,
                                color: AppColors.accentPrimary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Rename Device',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.statusSuccess),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.stateDisplay,
                      style: const TextStyle(
                        color: AppColors.statusSuccess,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Status Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                _buildMetricCard(
                  title: 'Active Paired Peers',
                  value: '$activePeers Device(s)',
                  subtext: activePeers > 0
                      ? 'Direct LAN connected'
                      : 'No active peers',
                  icon: Icons.devices,
                  color: AppColors.accentPrimary,
                ),
                _buildMetricCard(
                  title: 'Network Latency',
                  value: '${status.pingMs} ms',
                  subtext: 'Direct socket RTT',
                  icon: Icons.speed,
                  color: AppColors.statusSuccess,
                ),
                _buildMetricCard(
                  title: 'Traffic Handled',
                  value:
                      '${(status.bytesSent + status.bytesReceived) ~/ 1024} KB',
                  subtext:
                      '${status.bytesSent} B up / ${status.bytesReceived} B down',
                  icon: Icons.swap_vert,
                  color: AppColors.statusInfo,
                ),
                _buildMetricCard(
                  title: 'Security Engine',
                  value: 'ChaCha20-Poly1305',
                  subtext: 'Ed25519 Signatures',
                  icon: Icons.shield,
                  color: AppColors.statusWarning,
                ),
              ];

              if (isWide) {
                return GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: cards,
                );
              } else {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: cards,
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // Bluetooth Direct Sync Hub Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(
                color: widget.state.settings.bluetoothEnabled
                    ? AppColors.accentCyan.withValues(alpha: 0.45)
                    : AppColors.borderSubtle,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: widget.state.settings.bluetoothEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.08),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bluetooth,
                        color: AppColors.accentCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bluetooth Direct Sync (Offline Mode)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.state.settings.bluetoothEnabled
                                ? 'Active • Ready to mirror clipboard via Bluetooth PAN without Wi-Fi'
                                : 'Disabled • Turn on for offline Bluetooth synchronization',
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.state.settings.bluetoothEnabled
                                  ? AppColors.statusSuccess
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.state.settings.bluetoothEnabled,
                      activeTrackColor: AppColors.accentCyan.withValues(
                        alpha: 0.35,
                      ),
                      activeThumbColor: AppColors.accentCyan,
                      onChanged: (val) {
                        setState(() {
                          widget.state.toggleBluetooth(val);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _handleBluetoothSync,
                      icon: const Icon(Icons.bluetooth_searching, size: 15),
                      label: const Text('Sync via Bluetooth Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan.withValues(
                          alpha: 0.15,
                        ),
                        foregroundColor: AppColors.accentCyan,
                        elevation: 0,
                        side: BorderSide(
                          color: AppColors.accentCyan.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showBluetoothHelpDialog(context),
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      label: const Text(
                        'Bluetooth Guide',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderSubtle),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Manual Sync Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: AppColors.accentPrimary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Broadcast Clipboard Payload',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instantly sign, encrypt, and push text across all connected Android and Windows nodes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, boxConstraints) {
                    final isSmallScreen = boxConstraints.maxWidth < 500;
                    if (isSmallScreen) {
                      return Column(
                        children: [
                          TextField(
                            controller: _syncController,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type or paste clipboard content...',
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.content_paste,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                tooltip: 'Paste from clipboard',
                                onPressed: _pasteFromSystemClipboard,
                              ),
                            ),
                            onSubmitted: (_) => _handleQuickSync(),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _handleQuickSync,
                                icon: const Icon(Icons.send, size: 15),
                                label: const Text('Sync Everywhere'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _handleBluetoothSync,
                                icon: const Icon(Icons.bluetooth, size: 15),
                                label: const Text('Bluetooth Sync'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentCyan
                                      .withValues(alpha: 0.15),
                                  foregroundColor: AppColors.accentCyan,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: AppColors.accentCyan.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _syncController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Type or paste clipboard content here...',
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.content_paste,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  tooltip: 'Paste from system clipboard',
                                  onPressed: _pasteFromSystemClipboard,
                                ),
                              ),
                              onSubmitted: (_) => _handleQuickSync(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _handleQuickSync,
                            icon: const Icon(Icons.send, size: 15),
                            label: const Text('Sync Everywhere'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _handleBluetoothSync,
                            icon: const Icon(Icons.bluetooth, size: 15),
                            label: const Text('Bluetooth Sync'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentCyan.withValues(
                                alpha: 0.15,
                              ),
                              foregroundColor: AppColors.accentCyan,
                              elevation: 0,
                              side: BorderSide(
                                color: AppColors.accentCyan.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recent Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Recent Clipboard Syncs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToHistory,
                child: const Text(
                  'View Full History →',
                  style: TextStyle(color: AppColors.accentPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'No recent clipboard items synced yet.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.take(5).length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildRecentItemTile(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.95),
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
            ),
          ),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemTile(HistoryItem item) {
    final isLocal = item.originDeviceId == widget.state.localDevice.deviceId;

    return RichClipboardCard(
      item: item,
      isLocal: isLocal,
      isCompact: true,
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
