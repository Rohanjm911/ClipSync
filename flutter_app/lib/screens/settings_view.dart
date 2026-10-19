import 'package:flutter/material.dart';

import '../services/state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/first_launch_dialog.dart';

class SettingsView extends StatefulWidget {
  final ClipSyncState state;

  const SettingsView({super.key, required this.state});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _portController;
  late TextEditingController _signalUrlController;
  late TextEditingController _companionIpController;
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(
      text: widget.state.settings.localPort.toString(),
    );
    _signalUrlController = TextEditingController(
      text: widget.state.settings.signalingUrl,
    );
    _companionIpController = TextEditingController(
      text: widget.state.settings.companionIp,
    );
  }

  @override
  void dispose() {
    _portController.dispose();
    _signalUrlController.dispose();
    _companionIpController.dispose();
    super.dispose();
  }

  Future<void> _handlePingTest() async {
    final ip = _companionIpController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter companion device IP address (e.g. 192.168.1.15)',
          ),
          backgroundColor: AppColors.statusWarning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isPinging = true);
    widget.state.settings.companionIp = ip;
    final success = await widget.state.pingCompanion(ip);
    if (!mounted) return;
    setState(() => _isPinging = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Successfully connected to companion device at $ip:48901!',
          ),
          backgroundColor: AppColors.statusSuccess,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✗ Could not reach $ip:48901. Ensure both devices are on the same Wi-Fi / Bluetooth network.',
          ),
          backgroundColor: AppColors.statusError,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _saveNetworkSettings() {
    final port = int.tryParse(_portController.text.trim()) ?? 48901;
    widget.state.settings.companionIp = _companionIpController.text.trim();
    widget.state.updateSettings(
      localPort: port,
      signalingUrl: _signalUrlController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Network settings updated successfully.'),
        backgroundColor: AppColors.statusSuccess,
      ),
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
    final dev = widget.state.localDevice;
    final s = widget.state.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Application Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage device cryptographic identity, network ports, and sync security filters.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Cryptographic Identity Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: AppColors.accentPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Host Cryptographic Identity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showChangeNameDialog(context),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit Name'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildIdentityField('Device Label', dev.deviceName),
                _buildIdentityField('Platform Target', dev.platform),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Device Type Profile: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.state.switchDeviceType(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: dev.platform.contains('Windows')
                              ? AppColors.accentPrimary
                              : AppColors.bgSurfaceElevated,
                          border: Border.all(
                            color: dev.platform.contains('Windows')
                                ? AppColors.accentPrimary
                                : AppColors.borderStrong,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.laptop,
                              size: 14,
                              color: dev.platform.contains('Windows')
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Windows PC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: dev.platform.contains('Windows')
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.state.switchDeviceType(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: dev.platform.contains('Android')
                              ? AppColors.accentPrimary
                              : AppColors.bgSurfaceElevated,
                          border: Border.all(
                            color: dev.platform.contains('Android')
                                ? AppColors.accentPrimary
                                : AppColors.borderStrong,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.smartphone,
                              size: 14,
                              color: dev.platform.contains('Android')
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Android Phone',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: dev.platform.contains('Android')
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildIdentityField(
                  'SHA-256 Node Fingerprint',
                  dev.fingerprint,
                ),
                _buildIdentityField(
                  'Ed25519 Signing Public Key',
                  dev.ed25519PubKey,
                ),
                _buildIdentityField('X25519 DH Public Key', dev.x25519PubKey),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security & Sync Preferences
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Synchronization & Privacy Policies',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Automatic Clipboard Mirroring',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Automatically sync system clipboard updates across all authorized peers in real-time.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: s.autoSync,
                  activeThumbColor: AppColors.accentPrimary,
                  activeTrackColor: AppColors.accentPrimary.withValues(
                    alpha: 0.3,
                  ),
                  onChanged: (val) => setState(
                    () => widget.state.updateSettings(autoSync: val),
                  ),
                ),
                const Divider(color: AppColors.borderSubtle),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Sensitive Content Masking & Secret Exclusion',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Detects SSH keys, Bearer tokens, GitHub personal access tokens, and credit cards to automatically mask them.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: s.excludeSensitive,
                  activeThumbColor: AppColors.accentPrimary,
                  activeTrackColor: AppColors.accentPrimary.withValues(
                    alpha: 0.3,
                  ),
                  onChanged: (val) => setState(
                    () => widget.state.updateSettings(excludeSensitive: val),
                  ),
                ),
                const Divider(color: AppColors.borderSubtle),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.bluetooth,
                    color: AppColors.accentPrimary,
                    size: 20,
                  ),
                  title: const Text(
                    'Bluetooth Direct Sync & Fallback',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Enables Bluetooth PAN & direct transport so clipboard syncs in real-time even without Wi-Fi connection.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: s.bluetoothEnabled,
                  activeThumbColor: AppColors.accentPrimary,
                  activeTrackColor: AppColors.accentPrimary.withValues(
                    alpha: 0.3,
                  ),
                  onChanged: (val) =>
                      setState(() => widget.state.toggleBluetooth(val)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Network Configurations
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Network & Transport Configuration',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Local Wi-Fi IP Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi,
                        size: 16,
                        color: AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'My Local IP: ${widget.state.localNetworkIp ?? '127.0.0.1'}:${widget.state.settings.localPort}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Companion Device IP (Direct LAN or Bluetooth PAN IP)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _companionIpController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 192.168.1.15 or 192.168.44.1',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isPinging ? null : _handlePingTest,
                      icon: _isPinging
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.network_ping, size: 16),
                      label: Text(_isPinging ? 'Pinging...' : 'Test Ping'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Quick Bluetooth IPs:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    _buildQuickIpChip(
                      '192.168.44.1 (Android Gateway)',
                      '192.168.44.1',
                    ),
                    _buildQuickIpChip('192.168.44.2 (PC Peer)', '192.168.44.2'),
                    _buildQuickIpChip(
                      '172.20.10.1 (Hotspot PAN)',
                      '172.20.10.1',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Local Discovery Port (mDNS / TCP)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Self-Hosted Signaling Server WebSocket URL',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _signalUrlController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _saveNetworkSettings,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save Network Preferences'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickIpChip(String label, String ip) {
    return InkWell(
      onTap: () {
        setState(() {
          _companionIpController.text = ip;
          _saveNetworkSettings();
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCyan,
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFamily: 'Consolas',
            ),
          ),
        ],
      ),
    );
  }
}
