import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../services/goal_state.dart';
import '../models/food_history_item.dart';
import '../widgets/depth_progress_ring.dart';

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onNavigateToScan;

  const DashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onNavigateToScan,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = SupabaseService();

  List<FoodHistoryItem> _recentScans = [];
  int _totalCaloriesToday = 0;
  int _scansToday = 0;
  bool _isLoading = true;

  // Last 7 days, oldest first. The last entry is today.
  List<DateTime> _weekDays = [];
  List<int> _weekTotals = List<int>.filled(7, 0);

  // The goal now comes from the user's profile (see goal_state.dart).
  int get _dailyGoal => dailyGoalNotifier.value;

  @override
  void initState() {
    super.initState();
    dailyGoalNotifier.addListener(_onGoalChanged);
    dashboardRefreshNotifier.addListener(_onRefreshRequested);
    _loadData();
  }

  @override
  void dispose() {
    dailyGoalNotifier.removeListener(_onGoalChanged);
    dashboardRefreshNotifier.removeListener(_onRefreshRequested);
    super.dispose();
  }

  // The Dashboard tab stays alive in the background (IndexedStack), so it
  // must be told to reload when the user comes back to it after scanning.
  void _onRefreshRequested() {
    if (mounted) _loadData();
  }

  // Rebuild straight away when the goal is changed in Profile.
  void _onGoalChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGoal() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('daily_calorie_goal')
          .eq('id', user.id)
          .maybeSingle();
      final goal = (data?['daily_calorie_goal'] as num?)?.toInt();
      dailyGoalNotifier.value =
          (goal != null && goal > 0) ? goal : kDefaultDailyGoal;
    } catch (e) {
      // Column missing or offline: keep whatever goal we already have.
      debugPrint('Goal load error: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadGoal();

      final history = List<FoodHistoryItem>.of(await _service.fetchHistory());
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final now = DateTime.now();
      final days = List<DateTime>.generate(
        7,
        (i) => DateTime(now.year, now.month, now.day - (6 - i)),
      );
      final totals = List<int>.filled(7, 0);
      var scansToday = 0;

      for (final item in history) {
        // Use the date exactly as it was saved. Converting with toLocal()
        // pushed scans made after 4 PM into "tomorrow" (the time is saved
        // without a timezone, so Malaysia's +8 hours got added on top).
        final t = item.timestamp;
        // TEMPORARY check, remove once the totals look right:
        debugPrint(
            'SCAN ${item.foodName} | ${item.calories} cal | ${item.timestamp} | isUtc=${item.timestamp.isUtc}');
        for (var i = 0; i < 7; i++) {
          if (t.year == days[i].year &&
              t.month == days[i].month &&
              t.day == days[i].day) {
            totals[i] += item.calories;
            if (i == 6) scansToday++;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _recentScans = history.take(3).toList(); // show last 3
        _weekDays = days;
        _weekTotals = totals;
        _totalCaloriesToday = totals[6];
        _scansToday = scansToday;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final goal = _dailyGoal;

    final isOver = _totalCaloriesToday > goal;
    final overBy = _totalCaloriesToday - goal;
    final caloriesLeft = (goal - _totalCaloriesToday).clamp(0, goal);
    final percent = (_totalCaloriesToday / goal).clamp(0.0, 1.0);
    final realPercent = (_totalCaloriesToday / goal * 100).round();

    // Normal = green. Over goal = orange, so the change is obvious without
    // being alarming. The text and icon say it too, not colour alone.
    final warnColor =
        isDarkMode ? const Color(0xFFFFB74D) : Colors.deepOrange[700]!;
    final ringColor = isOver
        ? (isDarkMode ? const Color(0xFFFF9800) : Colors.deepOrange[500]!)
        : (isDarkMode ? const Color(0xFF66BB6A) : Colors.green[600]!);
    final ringHighlight = isOver
        ? (isDarkMode ? const Color(0xFFFFCC80) : Colors.orange[300]!)
        : (isDarkMode ? const Color(0xFFA5D6A7) : Colors.green[300]!);
    final ringTrackBase =
        isDarkMode ? const Color(0xFF2C4A3A) : Colors.grey[300]!;

    final mutedText = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SmartHealthFood',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
        ),
        backgroundColor:
            isDarkMode ? const Color(0xFF1B3B2B) : Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your nutrition with AI-powered food recognition.',
                style: TextStyle(fontSize: 14, color: mutedText),
              ),
              const SizedBox(height: 24),

              // ── Progress card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [const Color(0xFF1F4432), const Color(0xFF163224)]
                        : [Colors.white, const Color(0xFFF6FBF7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.grey.withValues(alpha: 0.15),
                      spreadRadius: 1,
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Today's Progress",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DepthProgressRing(
                      radius: 80,
                      strokeWidth: 14,
                      percent: percent,
                      color: ringColor,
                      highlightColor: ringHighlight,
                      trackBase: ringTrackBase,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isOver ? '+${_fmt(overBy)}' : _fmt(caloriesLeft),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isOver
                                  ? warnColor
                                  : (isDarkMode
                                      ? const Color(0xFF81C784)
                                      : Colors.green[700]),
                            ),
                          ),
                          Text(
                            isOver ? 'cal over' : 'cal left',
                            style: TextStyle(fontSize: 14, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Calories today',
                          _fmt(_totalCaloriesToday),
                          '/ ${_fmt(goal)} cal',
                          isDarkMode,
                        ),
                        _buildStatItem(
                          'Total scans',
                          '$_scansToday',
                          'today',
                          isDarkMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Daily calorie goal',
                      style: TextStyle(color: mutedText, fontSize: 14),
                    ),
                    Text(
                      '$realPercent% of daily goal',
                      style: TextStyle(
                        color: isOver
                            ? warnColor
                            : (isDarkMode
                                ? Colors.orange[300]
                                : Colors.orange[800]),
                        fontSize: 14,
                        fontWeight: isOver ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    if (isOver) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: warnColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: warnColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "You're ${_fmt(overBy)} cal over today's goal",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: warnColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 7-day chart ────────────────────────────
              _buildWeeklyCard(isDarkMode, goal, mutedText),
              const SizedBox(height: 24),

              // ── Scan button ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: widget.onNavigateToScan,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Food Now',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? const Color(0xFF2E7D32) : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Recent scans ───────────────────────────
              Text(
                'Recent Scans',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_recentScans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1B3B2B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_outlined,
                          size: 48,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No recent scans',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._recentScans.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? const Color(0xFF1B3B2B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2E7D32)
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.restaurant,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.green[700],
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.foodName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  '${item.calories} cal · ${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyCard(bool isDarkMode, int goal, Color mutedText) {
    final daysWithData = _weekTotals.where((t) => t > 0).toList();
    final average = daysWithData.isEmpty
        ? null
        : (daysWithData.reduce((a, b) => a + b) / daysWithData.length).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1B3B2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.grey.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 7 days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                average == null
                    ? 'No data yet'
                    : 'Avg ${_fmt(average)} cal/day',
                style: TextStyle(fontSize: 13, color: mutedText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_weekDays.length == 7)
            _WeeklyChart(
              days: _weekDays,
              totals: _weekTotals,
              goal: goal,
              isDark: isDarkMode,
              fmt: _fmt,
            )
          else
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, String subtitle, bool isDarkMode) {
    final muted = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    return Column(
      children: [
        Text(title, style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black)),
        Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Simple 7-day bar chart (no extra packages). Bars turn orange on days over
// the goal, and a horizontal line marks the goal.
// ---------------------------------------------------------------------------
class _WeeklyChart extends StatelessWidget {
  final List<DateTime> days;
  final List<int> totals;
  final int goal;
  final bool isDark;
  final String Function(int) fmt;

  const _WeeklyChart({
    required this.days,
    required this.totals,
    required this.goal,
    required this.isDark,
    required this.fmt,
  });

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const double _barArea = 110;
  static const double _valueRow = 18;

  String _short(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  String _dayLabel(int i) =>
      i == days.length - 1 ? 'Today' : _dayNames[days[i].weekday - 1];

  @override
  Widget build(BuildContext context) {
    final maxTotal = totals.fold<int>(goal, (m, v) => v > m ? v : m);
    final scaleMax = maxTotal * 1.1;
    final goalBottom = goal / scaleMax * _barArea;

    final okColor = isDark ? const Color(0xFF66BB6A) : Colors.green[600]!;
    final overColor =
        isDark ? const Color(0xFFFFB74D) : Colors.deepOrange[500]!;
    final lineColor = isDark ? Colors.white70 : Colors.grey[800]!;
    final muted = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    final summary = List.generate(
      days.length,
      (i) => '${_dayLabel(i)} ${totals[i]} calories',
    ).join(', ');

    return Semantics(
      label: 'Calories for the last 7 days, goal $goal. $summary',
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: _valueRow + _barArea,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(days.length, (i) {
                        final t = totals[i];
                        final isToday = i == days.length - 1;
                        final over = t > goal;
                        final h = t == 0
                            ? 2.0
                            : (t / scaleMax * _barArea).clamp(2.0, _barArea);
                        final base = over ? overColor : okColor;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: _valueRow,
                                  child: Center(
                                    child: Text(
                                      t == 0 ? '' : _short(t),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isToday
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: over ? overColor : muted,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: t == 0
                                        ? muted.withValues(alpha: 0.25)
                                        : base.withValues(
                                            alpha: isToday ? 1.0 : 0.6),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Goal line, drawn on top of the bars.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: goalBottom,
                    child: Container(height: 1.5, color: lineColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(days.length, (i) {
                final isToday = i == days.length - 1;
                return Expanded(
                  child: Center(
                    child: Text(
                      _dayLabel(i),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? (isDark ? Colors.white : Colors.black)
                            : muted,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _legend(
                  Container(width: 16, height: 2, color: lineColor),
                  'Goal ${fmt(goal)} cal',
                  muted,
                ),
                _legend(
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: overColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  'Over goal',
                  muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Widget swatch, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11.5, color: color)),
      ],
    );
  }
}
