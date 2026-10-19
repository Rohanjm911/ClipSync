import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/state_service.dart';
import '../theme/app_theme.dart';

class PairingView extends StatefulWidget {
  final ClipSyncState state;

  const PairingView({super.key, required this.state});

  @override
  State<PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends State<PairingView> {
  Timer? _timer;
  int _secondsRemaining = 180;
  int _selectedTab = 0;
  final TextEditingController _sasInputController = TextEditingController();
  final TextEditingController _peerNameController = TextEditingController();
  final TextEditingController _btIpController = TextEditingController(
    text: '192.168.44.1',
  );
  bool _isTestingBt = false;
  String? _btTestResult;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsRemaining = widget.state.activePairing.expiresAt
        .difference(DateTime.now())
        .inSeconds;
    if (_secondsRemaining <= 0) {
      widget.state.generatePairingPayload();
      _secondsRemaining = 180;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final diff = widget.state.activePairing.expiresAt
            .difference(DateTime.now())
            .inSeconds;
        if (diff <= 0) {
          widget.state.generatePairingPayload();
          _secondsRemaining = 180;
        } else {
          _secondsRemaining = diff;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sasInputController.dispose();
    _peerNameController.dispose();
    _btIpController.dispose();
    super.dispose();
  }

  void _handleManualPair() {
    final code = _sasInputController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit verification code.'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    widget.state.completeManualPairing(code, _peerNameController.text);
    _sasInputController.clear();
    _peerNameController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Device successfully verified and paired!'),
        backgroundColor: AppColors.statusSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pairing = widget.state.activePairing;
    final progress = (_secondsRemaining / 180.0).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Device Pairing Ceremony',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mutual, zero-cloud cryptographic handshake connecting Phone & PC via SAS verification.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Pairing Mode Switcher Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? AppColors.accentPrimary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: _selectedTab == 0
                            ? Border.all(color: AppColors.accentPrimary)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 16,
                            color: _selectedTab == 0
                                ? AppColors.accentPrimary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Wi-Fi / QR Code Pairing',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedTab == 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? const Color(0xFF00D2FF).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: _selectedTab == 1
                            ? Border.all(color: const Color(0xFF00D2FF))
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth,
                            size: 16,
                            color: _selectedTab == 1
                                ? const Color(0xFF00D2FF)
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bluetooth Direct Pairing',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedTab == 1
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Layout based on selected tab
          if (_selectedTab == 0)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildQrCard(pairing, progress)),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildManualPairCard()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildQrCard(pairing, progress),
                      const SizedBox(height: 20),
                      _buildManualPairCard(),
                    ],
                  );
                }
              },
            )
          else
            _buildBluetoothPairingCard(pairing),
          const SizedBox(height: 28),

          // Security Trust Footnote
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user,
                  color: AppColors.statusSuccess,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zero-Knowledge Mutual Key Exchange',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Session tokens strictly expire after 180 seconds. Visual comparison of the 6-digit Short Authentication String (SAS) guarantees zero Man-In-The-Middle attacks.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(dynamic pairing, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Scan QR Code with Phone',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceElevated,
                  border: Border.all(color: AppColors.borderStrong),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_secondsRemaining}s left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.bgSurfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(
              _secondsRemaining > 30
                  ? AppColors.accentPrimary
                  : AppColors.statusError,
            ),
            minHeight: 4,
          ),
          const SizedBox(height: 24),

          // Crisp QR Image with Solid White Background for Camera Readability
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: QrImageView(
              data: pairing.serialize(),
              version: QrVersions.auto,
              size: 200.0,
              gapless: true,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // SAS Code Display
          const Text(
            'Short Authentication String (SAS)',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceElevated,
              border: Border.all(color: AppColors.accentPrimary),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${pairing.sasCode.substring(0, 3)} ${pairing.sasCode.substring(3)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: AppColors.textPrimary,
                fontFamily: 'Consolas',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Compare this code on both screens to confirm genuine pairing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              widget.state.generatePairingPayload();
              _startCountdown();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Generate Fresh Pairing Token'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualPairCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Pairing Code',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'If camera is unavailable, enter the 6-digit code shown on the companion device:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Device Label (Optional)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _peerNameController,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. My Galaxy Phone'),
          ),
          const SizedBox(height: 16),
          const Text(
            '6-Digit Auth Code',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _sasInputController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 4,
              fontFamily: 'Consolas',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: '••••••',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleManualPair,
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Verify & Complete Pairing'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),
          const Text(
            'Local Network Discovery',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Broadcast IP: 192.168.1.105:48901\nProtocol: _clipsync._tcp.local (mDNS)\nNo external router configuration required.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.5,
              fontFamily: 'Consolas',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothPairingCard(dynamic pairing) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(
          color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.bluetooth_connected,
                  color: Color(0xFF00D2FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth Direct Sync Pairing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pair PC and Phone directly without any Wi-Fi router or internet access.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),

          // 3-Step Guide Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3-Step Quick Bluetooth Setup:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00D2FF),
                  ),
                ),
                const SizedBox(height: 8),
                _buildGuideStep(
                  '1',
                  'Turn ON Bluetooth on both your PC and Phone and pair them once in OS Bluetooth Settings.',
                ),
                const SizedBox(height: 6),
                _buildGuideStep(
                  '2',
                  'On Android: Go to Settings → Hotspot & Tethering → Turn ON "Bluetooth Tethering".',
                ),
                const SizedBox(height: 6),
                _buildGuideStep(
                  '3',
                  'On Windows: In Bluetooth & Devices, click on your phone → Connect using Personal Area Network (PAN).',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Companion BT IP field
          const Text(
            'Target Companion Bluetooth IP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _btIpController,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Consolas',
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. 192.168.44.1',
              prefixIcon: Icon(Icons.lan, size: 16, color: Color(0xFF00D2FF)),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Presets
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPresetChip('192.168.44.1', 'Android Gateway'),
              _buildPresetChip('192.168.44.2', 'PC Peer'),
              _buildPresetChip('172.20.10.1', 'Hotspot PAN'),
            ],
          ),
          const SizedBox(height: 20),

          // 6-digit SAS Auth
          const Text(
            'Security SAS Code',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _sasInputController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 4,
              fontFamily: 'Consolas',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: '••••••',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Test Direct Link & Complete Pairing
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTestingBt
                      ? null
                      : () async {
                          setState(() {
                            _isTestingBt = true;
                            _btTestResult = null;
                          });
                          final ip = _btIpController.text.trim();
                          if (ip.isNotEmpty) {
                            widget.state.updateCompanionIp(ip);
                          }
                          final res = await widget.state.syncViaBluetooth(
                            'ClipSync Bluetooth Pairing Handshake',
                            force: true,
                          );
                          if (mounted) {
                            setState(() {
                              _isTestingBt = false;
                              _btTestResult = res['success'] == true
                                  ? '✓ Direct connection reachable!'
                                  : 'Offline/Unreachable';
                            });
                          }
                        },
                  icon: _isTestingBt
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.bolt,
                          size: 16,
                          color: Color(0xFF00D2FF),
                        ),
                  label: const Text('Test Bluetooth Link'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final ip = _btIpController.text.trim();
                    if (ip.isNotEmpty) {
                      widget.state.updateCompanionIp(ip);
                    }
                    _handleManualPair();
                  },
                  icon: const Icon(Icons.bluetooth, size: 16),
                  label: const Text('Pair via Bluetooth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007ACC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (_btTestResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _btTestResult!.startsWith('✓')
                    ? AppColors.statusSuccess.withValues(alpha: 0.15)
                    : AppColors.statusWarning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _btTestResult!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _btTestResult!.startsWith('✓')
                      ? AppColors.statusSuccess
                      : AppColors.statusWarning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String instruction) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00D2FF),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            instruction,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String ip, String label) {
    return ActionChip(
      avatar: const Icon(Icons.bluetooth, size: 12, color: Color(0xFF00D2FF)),
      label: Text('$ip ($label)', style: const TextStyle(fontSize: 11)),
      backgroundColor: AppColors.bgSurfaceElevated,
      side: const BorderSide(color: AppColors.borderSubtle),
      onPressed: () {
        setState(() {
          _btIpController.text = ip;
        });
        widget.state.updateCompanionIp(ip);
      },
    );
  }
}
