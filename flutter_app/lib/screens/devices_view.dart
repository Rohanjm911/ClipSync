import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/state_service.dart';
import '../theme/app_theme.dart';

class DevicesView extends StatelessWidget {
  final ClipSyncState state;
  final VoidCallback onNavigateToPairing;

  const DevicesView({
    super.key,
    required this.state,
    required this.onNavigateToPairing,
  });

  void _confirmRevoke(BuildContext context, PairedDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.statusError, size: 20),
            SizedBox(width: 8),
            Text(
              'Revoke Device Trust?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to revoke "${device.deviceName}"?\n\nIts cryptographic keys will be permanently invalidated locally and all future sync requests from this device will be immediately discarded.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              state.revokeDevice(device.deviceId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✓ Revoked cryptographic trust for ${device.deviceName}',
                  ),
                  backgroundColor: AppColors.statusError,
                ),
              );
            },
            child: const Text('Revoke Trust'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context, {
    required bool isLocal,
    PairedDevice? device,
  }) {
    final currentName = isLocal
        ? state.localDevice.deviceName
        : device!.deviceName;
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              isLocal ? 'Rename This Device' : 'Rename Paired Node',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLocal
                  ? 'Enter custom name for this device:'
                  : 'Enter custom alias for ${device!.deviceName}:',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(hintText: 'Device Name'),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                if (isLocal) {
                  state.updateDeviceName(newName);
                } else {
                  state.renamePairedDevice(device!.deviceId, newName);
                }
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Device name saved as "$newName"'),
                    backgroundColor: AppColors.statusSuccess,
                  ),
                );
              }
            },
            child: const Text('Save Name'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = state.localDevice;
    final activeDevices = state.pairedDevices
        .where((d) => !d.isRevoked)
        .toList();
    final revokedDevices = state.pairedDevices
        .where((d) => d.isRevoked)
        .toList();

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
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connected Devices',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activeDevices.length} active node(s) holding verified cryptographic trust.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onNavigateToPairing,
                icon: const Icon(Icons.add_link, size: 16),
                label: const Text('Pair New Node'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Local Device Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.6),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final deviceDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          local.deviceName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'THIS DEVICE (HOST)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Platform: ${local.platform} • Fingerprint: ${local.fingerprint}...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );

                final renameBtn = ElevatedButton.icon(
                  onPressed: () => _showRenameDialog(context, isLocal: true),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Rename Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgSurfaceElevated,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderStrong),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              local.icon,
                              size: 24,
                              color: AppColors.accentPrimary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: deviceDetails),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(width: double.infinity, child: renameBtn),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          local.icon,
                          size: 24,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: deviceDetails),
                      const SizedBox(width: 12),
                      renameBtn,
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Active Devices Header
          const Text(
            'Paired Companion Devices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Active Devices List
          if (activeDevices.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.devices_other,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No companion devices paired.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pair your Android phone or companion PC using the QR code ceremony.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onNavigateToPairing,
                    child: const Text('Start Pairing'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeDevices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = activeDevices[index];
                return _buildDeviceTile(context, device, isRevoked: false);
              },
            ),

          // Revoked Devices Section
          if (revokedDevices.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Revoked Devices (Blocked)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.statusError,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Devices with invalidated signatures. Packets from these IDs are immediately dropped.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: revokedDevices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final device = revokedDevices[index];
                return _buildDeviceTile(context, device, isRevoked: true);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    PairedDevice device, {
    required bool isRevoked,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(
          color: isRevoked
              ? AppColors.statusError.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          final deviceDetails = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    device.deviceName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!isRevoked)
                    InkWell(
                      onTap: () => _showRenameDialog(
                        context,
                        isLocal: false,
                        device: device,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
                              'Rename',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isRevoked
                          ? AppColors.statusError.withValues(alpha: 0.15)
                          : AppColors.statusSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      isRevoked ? 'REVOKED' : device.connectionType,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isRevoked
                            ? AppColors.statusError
                            : AppColors.statusSuccess,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Fingerprint: ${device.fingerprint}... • Paired ${DateTime.now().difference(device.pairedAt).inHours}h ago',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Consolas',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ed25519 PubKey: ${device.ed25519PubKey}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'Consolas',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final actionBtn = !isRevoked
              ? OutlinedButton.icon(
                  onPressed: () => _confirmRevoke(context, device),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusError,
                    side: const BorderSide(color: AppColors.statusError),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Revoke Trust'),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  tooltip: 'Delete Record Permanently',
                  onPressed: () => state.deleteDevice(device.deviceId),
                );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRevoked
                            ? AppColors.statusError.withValues(alpha: 0.12)
                            : AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isRevoked ? Icons.block : device.icon,
                        size: 22,
                        color: isRevoked
                            ? AppColors.statusError
                            : AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: deviceDetails),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: actionBtn),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRevoked
                        ? AppColors.statusError.withValues(alpha: 0.12)
                        : AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isRevoked ? Icons.block : device.icon,
                    size: 22,
                    color: isRevoked
                        ? AppColors.statusError
                        : AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: deviceDetails),
                const SizedBox(width: 12),
                actionBtn,
              ],
            );
          }
        },
      ),
    );
  }
}
