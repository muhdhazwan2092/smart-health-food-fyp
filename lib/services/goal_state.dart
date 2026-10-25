import 'package:flutter/foundation.dart';

/// Default daily calorie goal used until the user sets their own.
const int kDefaultDailyGoal = 2000;

/// Shared between the Profile screen (where the goal is set) and the
/// Dashboard (where it is shown), so changing the goal updates the dashboard
/// straight away without a manual refresh.
final ValueNotifier<int> dailyGoalNotifier =
    ValueNotifier<int>(kDefaultDailyGoal);

/// Bump this (value++) to tell the Dashboard to reload its data, e.g. when
/// the user switches back to the Dashboard tab after scanning food.
final ValueNotifier<int> dashboardRefreshNotifier = ValueNotifier<int>(0);
