import 'package:flutter/material.dart';

import 'screens/dashboard_view.dart';
import 'screens/pairing_view.dart';
import 'screens/devices_view.dart';
import 'screens/history_view.dart';
import 'screens/diagnostics_view.dart';
import 'screens/settings_view.dart';
import 'services/state_service.dart';
import 'theme/app_theme.dart';
import 'widgets/first_launch_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClipSyncApp());
}

class ClipSyncApp extends StatelessWidget {
  const ClipSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final ClipSyncState _state = ClipSyncState();
  int _currentIndex = 0;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_checkFirstLaunch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLaunch());
  }

  @override
  void dispose() {
    _state.removeListener(_checkFirstLaunch);
    _state.dispose();
    super.dispose();
  }

  void _checkFirstLaunch() {
    if (_state.isInitialized &&
        _state.isFirstLaunch &&
        !_dialogShowing &&
        mounted) {
      _dialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_state.isFirstLaunch) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => FirstLaunchDialog(
            state: _state,
            onCompleted: (chosenName) {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
              _dialogShowing = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.statusSuccess,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Device named "$chosenName". Clipboard sync is active!',
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
                    side: const BorderSide(color: AppColors.borderStrong),
                  ),
                ),
              );
            },
          ),
        ).then((_) {
          _dialogShowing = false;
        });
      });
    }
  }

  final List<String> _tabTitles = [
    'Dashboard',
    'Pair Device',
    'Authorized Devices',
    'Clipboard History',
    'Diagnostics',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;

            final currentScreen = _buildCurrentScreen();

            if (isDesktop) {
              return Scaffold(
                backgroundColor: AppColors.bgPrimary,
                body: Row(
                  children: [
                    _buildDesktopSidebar(),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                    ),
                    Expanded(child: currentScreen),
                  ],
                ),
              );
            } else {
              // Mobile Layout (Android Phone)
              return Scaffold(
                backgroundColor: AppColors.bgPrimary,
                appBar: AppBar(
                  backgroundColor: AppColors.bgSurface,
                  elevation: 0,
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _tabTitles[_currentIndex],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusSuccess,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: currentScreen,
                bottomNavigationBar: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgSurface,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle, width: 1),
                    ),
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: AppColors.bgSurface,
                      indicatorColor: AppColors.accentPrimary.withValues(
                        alpha: 0.2,
                      ),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentPrimary,
                          );
                        }
                        return const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        );
                      }),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const IconThemeData(
                            color: AppColors.accentPrimary,
                            size: 20,
                          );
                        }
                        return const IconThemeData(
                          color: AppColors.textSecondary,
                          size: 20,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (idx) =>
                          setState(() => _currentIndex = idx),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.qr_code),
                          label: 'Pair',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.devices),
                          label: 'Devices',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.history),
                          label: 'History',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.troubleshoot),
                          label: 'Diags',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardView(
          state: _state,
          onNavigateToPairing: () => setState(() => _currentIndex = 1),
          onNavigateToHistory: () => setState(() => _currentIndex = 3),
        );
      case 1:
        return PairingView(state: _state);
      case 2:
        return DevicesView(
          state: _state,
          onNavigateToPairing: () => setState(() => _currentIndex = 1),
        );
      case 3:
        return HistoryView(state: _state);
      case 4:
        return DiagnosticsView(state: _state);
      case 5:
        return SettingsView(state: _state);
      default:
        return DashboardView(
          state: _state,
          onNavigateToPairing: () => setState(() => _currentIndex = 1),
          onNavigateToHistory: () => setState(() => _currentIndex = 3),
        );
    }
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 220,
      color: AppColors.bgSurface,
      child: Column(
        children: [
          // App Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ClipSync',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'E2EE Sync',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              children: [
                _buildSidebarNavItem(0, 'Dashboard', Icons.dashboard_outlined),
                _buildSidebarNavItem(1, 'Pair Device', Icons.qr_code_2),
                _buildSidebarNavItem(2, 'Devices', Icons.devices),
                _buildSidebarNavItem(3, 'History', Icons.history),
                _buildSidebarNavItem(4, 'Diagnostics', Icons.troubleshoot),
                _buildSidebarNavItem(5, 'Settings', Icons.settings_outlined),
              ],
            ),
          ),

          // Footer Status Card
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceElevated,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Engine Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusSuccess,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _state.localDevice.deviceName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontFamily: 'Consolas',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
