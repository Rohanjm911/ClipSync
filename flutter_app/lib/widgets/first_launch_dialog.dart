import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/state_service.dart';
import '../theme/app_theme.dart';

class FirstLaunchDialog extends StatefulWidget {
  final ClipSyncState state;
  final void Function(String chosenName) onCompleted;

  const FirstLaunchDialog({
    super.key,
    required this.state,
    required this.onCompleted,
  });

  @override
  State<FirstLaunchDialog> createState() => _FirstLaunchDialogState();
}

class _FirstLaunchDialogState extends State<FirstLaunchDialog> {
  late TextEditingController _nameController;
  late bool _isDesktop;
  late List<String> _presets;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        (kIsWeb && !defaultTargetPlatform.toString().contains('android'));

    _presets = _isDesktop
        ? ['💻 Main PC', '💻 Workstation', '💻 Work Laptop', '💻 Windows PC']
        : [
            '📱 Personal Phone',
            '📱 Work Phone',
            '📱 Galaxy S',
            '📱 Pixel Phone',
          ];

    String initialName = widget.state.localDevice.deviceName.trim();
    if (initialName.isEmpty ||
        initialName.startsWith('Pixel 8 Pro') ||
        initialName.startsWith('Desktop-PC-Win11')) {
      initialName = _isDesktop ? 'My Windows PC' : 'My Android Phone';
    }

    _nameController = TextEditingController(text: initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a device name';
      });
      return;
    }
    widget.state.completeOnboarding(name);
    widget.onCompleted(name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPrimary.withValues(alpha: 0.22),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(26),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Platform Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withValues(alpha: 0.15),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stack) => const Icon(
                          Icons.content_paste_rounded,
                          color: AppColors.accentCyan,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.accentPrimary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isDesktop
                                      ? Icons.desktop_windows_rounded
                                      : Icons.phone_android_rounded,
                                  size: 12,
                                  color: AppColors.accentCyan,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isDesktop
                                      ? 'WINDOWS PC SETUP'
                                      : 'ANDROID SETUP',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.accentCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Welcome to ClipSync',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Description
                const Text(
                  'Give this device a personalized name so your companion devices can immediately recognize it when syncing clipboard data.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                // Text Field Label
                const Text(
                  'Device Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Device Name TextField
                TextField(
                  controller: _nameController,
                  maxLength: 32,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.bgSurfaceElevated,
                    counterStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    hintText: _isDesktop
                        ? 'e.g., Rohan\'s Work PC'
                        : 'e.g., Rohan\'s Phone',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.accentCyan,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () => _nameController.clear(),
                    ),
                    errorText: _errorMessage,
                    errorStyle: const TextStyle(
                      color: AppColors.statusError,
                      fontSize: 11,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtle,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtle,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.accentPrimary,
                        width: 1.6,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 10),

                // Quick Preset Chips
                Row(
                  children: const [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppColors.accentCyan,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Quick Presets:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((preset) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _nameController.text = preset
                              .replaceAll(RegExp(r'^[^\w\s]+\s*'), '')
                              .trim();
                          _errorMessage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          preset,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Set Name Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Save Name & Start Syncing',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footnote
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.tune_rounded,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'You can change your device name anytime later in Settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
