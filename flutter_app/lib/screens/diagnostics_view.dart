import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/state_service.dart';
import '../theme/app_theme.dart';

class DiagnosticsView extends StatelessWidget {
  final ClipSyncState state;

  const DiagnosticsView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.connectionStatus;
    final logs = state.diagnosticLogs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Network Diagnostics & Peer Inspector',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Low-level protocol telemetry, socket verification, and packet audit logs.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Smart Hybrid State Machine Pipeline
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
                  'Smart Hybrid Transport Priority Matrix',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 650;
                    final steps = [
                      _buildPipelineStep(
                        title: '1. Local Direct Socket',
                        sub: 'mDNS / UDP Broadcast',
                        isActive:
                            status.state == ConnectionStateEnum.connectedDirect,
                        statusText: 'ACTIVE (Primary)',
                        statusColor: AppColors.statusSuccess,
                      ),
                      _buildPipelineStep(
                        title: '2. Remote P2P WebRTC',
                        sub: 'STUN / ICE Traversal',
                        isActive:
                            status.state == ConnectionStateEnum.connectedP2p,
                        statusText: 'STANDBY',
                        statusColor: AppColors.textMuted,
                      ),
                      _buildPipelineStep(
                        title: '3. E2EE Encrypted Relay',
                        sub: 'Opaque Forwarder',
                        isActive:
                            status.state == ConnectionStateEnum.connectedRelay,
                        statusText: 'FALLBACK',
                        statusColor: AppColors.textMuted,
                      ),
                    ];

                    if (isDesktop) {
                      return Row(
                        children: [
                          Expanded(child: steps[0]),
                          const SizedBox(width: 12),
                          Expanded(child: steps[1]),
                          const SizedBox(width: 12),
                          Expanded(child: steps[2]),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          steps[0],
                          const SizedBox(height: 10),
                          steps[1],
                          const SizedBox(height: 10),
                          steps[2],
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Connection Details Grid
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
                  'Active Transport Telemetry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _buildTelemetryRow('Current Engine Mode', status.transportMode),
                _buildTelemetryRow(
                  'Direct Round-Trip Time',
                  '${status.pingMs} ms (Zero WAN routing)',
                ),
                _buildTelemetryRow(
                  'Local Listening Port',
                  '${state.settings.localPort} (TCP/UDP)',
                ),
                _buildTelemetryRow(
                  'Signaling Service',
                  state.settings.signalingUrl,
                ),
                _buildTelemetryRow(
                  'Encrypted Stream Cipher',
                  'ChaCha20-Poly1305 (IETF variant)',
                ),
                _buildTelemetryRow(
                  'Identity Key Algorithm',
                  'Ed25519 (RFC 8032)',
                ),
                _buildTelemetryRow(
                  'Diffie-Hellman Key Exchange',
                  'X25519 Curve25519',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Packet Log Stream
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cryptographic Packet Event Stream',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${logs.length} events logged',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.borderSubtle),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'Consolas',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        border: Border.all(color: AppColors.borderStrong),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        log.eventType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Consolas',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        log.details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (log.isEncrypted) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock,
                        size: 12,
                        color: AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'E2EE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required String title,
    required String sub,
    required bool isActive,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.bgSurfaceElevated : AppColors.bgPrimary,
        border: Border.all(
          color: isActive ? AppColors.statusSuccess : AppColors.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Consolas',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
