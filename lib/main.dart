import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'themes/app_theme.dart';
import 'services/goal_state.dart';
import 'services/language_state.dart';
import 'services/app_strings.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/history_screen.dart';
import 'screens/places_screen.dart';
import 'screens/profile_screen.dart';

const String kSupabaseUrl = 'https://bicwiijhjrsonlttzrqi.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpY3dpaWpoanJzb25sdHR6cnFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NzIyMjAsImV4cCI6MjA5NDI0ODIyMH0.8iL8OXBBPluD537wFJm5ypK4MhyzVYe1EXyMQ5BDl8U';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  // Restore the language the user picked last time (Profile > Language).
  await loadSavedLanguage();

  runApp(const SmartHealthFoodApp());
}

class SmartHealthFoodApp extends StatelessWidget {
  const SmartHealthFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final displayFont = GoogleFonts.poppinsTextTheme();

    TextTheme buildTextTheme(Color color) =>
        baseTextTheme.apply(bodyColor: color, displayColor: color).copyWith(
              headlineLarge: displayFont.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: color),
              headlineMedium: displayFont.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: color),
              titleLarge: displayFont.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: color),
              titleMedium: displayFont.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: color),
            );

    final lightScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: Colors.white,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      secondary: AppColors.accent,
    );

    // Readable pop-up messages in BOTH themes: white text on the coloured
    // snackbar backgrounds (dark mode otherwise falls back to dark text).
    const snackTheme = SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: Color(0xFFA5D6A7),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'SmartHealthFood',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: lightScheme,
            snackBarTheme: snackTheme,
            textTheme: buildTextTheme(AppColors.ink),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.bg,
              foregroundColor: AppColors.ink,
              elevation: 0,
              titleTextStyle: displayFont.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.inkSoft,
              showUnselectedLabels: true,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: darkScheme,
            snackBarTheme: snackTheme,
            textTheme: buildTextTheme(Colors.white.withValues(alpha: 0.92)),
          ),
          themeMode: mode, // driven by the global notifier in app_theme.dart
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const MainApp(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null ? const MainApp() : const LoginPage();
  }
}

// ---------------------------------------------------------------------------
// Main app shell (bottom-nav + tabs) — shown once the user is authenticated.
// Chat and Profile live behind a floating "speed dial" button instead of
// taking up two bottom-nav slots.
// ---------------------------------------------------------------------------
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  bool _fabOpen = false;

  late final AnimationController _fabController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
      _fabOpen ? _fabController.forward() : _fabController.reverse();
    });
  }

  void _closeFab() {
    if (_fabOpen) {
      setState(() {
        _fabOpen = false;
        _fabController.reverse();
      });
    }
  }

  void _openChat() {
    _closeFab();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreenPage(
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
          onToggleDarkMode: toggleGlobalDarkMode,
        ),
      ),
    );
  }

  void _openProfile() {
    _closeFab();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
          onToggleDarkMode: toggleGlobalDarkMode,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  // Rebuild the navigation bar and menu when the language is changed.
  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _tabIndex,
            children: [
              DashboardScreen(
                isDarkMode: isDark,
                onToggleDarkMode: toggleGlobalDarkMode,
                onNavigateToScan: () => setState(() => _tabIndex = 1),
              ),
              ScanScreenPage(
                  isDarkMode: isDark, onToggleDarkMode: toggleGlobalDarkMode),
              HistoryScreenPage(
                  isDarkMode: isDark, onToggleDarkMode: toggleGlobalDarkMode),
              PlacesScreenPage(
                  isDarkMode: isDark, onToggleDarkMode: toggleGlobalDarkMode),
            ],
          ),
          // Dim the background slightly when the speed-dial is open, and let
          // tapping outside the buttons close it.
          if (_fabOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFab,
                child: AnimatedBuilder(
                  animation: _fabController,
                  builder: (context, child) => Container(
                    color: Colors.black
                        .withValues(alpha: 0.25 * _fabController.value),
                  ),
                ),
              ),
            ),
        ],
      ),
      // HCI FIX: extendBody removed so page content stops ABOVE the dock
      // instead of scrolling underneath it (no more overlapping controls).
      floatingActionButton: _buildSpeedDial(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildFlyingDock(isDark),
    );
  }

  // ---------------------------------------------------------------------
  // "Flying dock" — a floating pill-shaped nav bar instead of a flat,
  // edge-to-edge BottomNavigationBar. Sits with margin on all sides, has
  // its own shadow/elevation, and an animated pill that slides behind
  // whichever icon is selected.
  // ---------------------------------------------------------------------
  static const _dockItems = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'nav_dashboard'
    ),
    (
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt_rounded,
      label: 'nav_scan'
    ),
    (
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'nav_history'
    ),
    (
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on_rounded,
      label: 'nav_places'
    ),
  ];

  Widget _buildFlyingDock(bool isDark) {
    final dockBg = isDark ? const Color(0xFF1B3B2B) : Colors.white;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: dockBg,
          borderRadius: tagRadius(r: 30, sharp: 12),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.ink)
                  .withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / _dockItems.length;
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Sliding highlight pill behind the selected icon
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * _tabIndex + 6,
                  top: 8,
                  child: Container(
                    width: itemWidth - 12,
                    height: 68 - 16,
                    decoration: BoxDecoration(
                      // HCI FIX: brighter pill so the active tab is obvious
                      color: isDark
                          ? const Color(0xFF81C784).withValues(alpha: 0.28)
                          : AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: tagRadius(r: 20, sharp: 8),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_dockItems.length, (i) {
                    final item = _dockItems[i];
                    final selected = _tabIndex == i;
                    // HCI FIX: higher contrast text/icons in dark mode
                    final fg = selected
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark
                            ? const Color(0xFFB8C7BE)
                            : AppColors.inkSoft);

                    return SizedBox(
                      width: itemWidth,
                      height: 68,
                      child: InkWell(
                        borderRadius: tagRadius(r: 20, sharp: 8),
                        onTap: () {
                          // HCI FIX: haptic feedback confirms the tap
                          if (!selected) HapticFeedback.selectionClick();
                          _closeFab();
                          setState(() => _tabIndex = i);
                          // Reload today's totals whenever the Dashboard tab
                          // is opened (e.g. after scanning new food).
                          if (i == 0) dashboardRefreshNotifier.value++;
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              color: fg,
                              size: 24,
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: fg,
                              ),
                              child: Text(tr(item.label)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpeedDial(bool isDark) {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _miniAction(
              visible: _fabController.value,
              icon: Icons.person_outline_rounded,
              label: tr('menu_profile'),
              onTap: _openProfile,
            ),
            const SizedBox(height: 12),
            _miniAction(
              visible: _fabController.value,
              icon: Icons.chat_bubble_outline_rounded,
              label: tr('menu_chat'),
              onTap: _openChat,
            ),
            const SizedBox(height: 16),
            // Main toggle button
            // HCI FIX: icon + tooltip now match what the button really does
            // (opens Chat & Profile), instead of a misleading "+".
            FloatingActionButton(
              onPressed: _toggleFab,
              tooltip: _fabOpen ? tr('menu_close') : tr('menu_open'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: tagRadius(r: 20, sharp: 8),
              ),
              child: Icon(_fabOpen ? Icons.close_rounded : Icons.apps_rounded),
            ),
          ],
        );
      },
    );
  }

  Widget _miniAction({
    required double visible,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Fade + slide the mini buttons in as the controller animates 0 -> 1.
    return IgnorePointer(
      ignoring: visible < 0.5,
      child: Opacity(
        opacity: visible,
        child: Transform.translate(
          offset: Offset(0, (1 - visible) * 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: tagRadius(r: 14, sharp: 6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                heroTag: label,
                mini: true,
                onPressed: onTap,
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: tagRadius(r: 16, sharp: 6),
                ),
                child: Icon(icon, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
