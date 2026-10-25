import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/app_theme.dart';

enum _GoalMode { manual, calculate }

/// Lets the user either type their own daily calorie goal, or calculate an
/// estimate from age, sex, height, weight, activity and aim.
/// Pops with the chosen goal (int), or null if cancelled.
class CalorieGoalDialog extends StatefulWidget {
  final int currentGoal;
  final bool isDarkMode;

  const CalorieGoalDialog({
    super.key,
    required this.currentGoal,
    required this.isDarkMode,
  });

  @override
  State<CalorieGoalDialog> createState() => _CalorieGoalDialogState();
}

class _CalorieGoalDialogState extends State<CalorieGoalDialog> {
  static const int _minGoal = 1000;
  static const int _maxGoal = 5000;
  static const int _safeFloor = 1200; // calculator never suggests below this

  static const _activityLabels = [
    'Little or no exercise',
    'Light (1–3 days/week)',
    'Moderate (3–5 days/week)',
    'Very active (6–7 days/week)',
  ];
  static const _activityFactors = [1.2, 1.375, 1.55, 1.725];

  static const _aimLabels = ['Lose weight', 'Maintain', 'Gain weight'];
  static const _aimAdjust = [-500, 0, 300];

  _GoalMode _mode = _GoalMode.manual;
  late final TextEditingController _manual;
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  bool _male = true;
  int _activity = 1;
  int _aim = 1;

  @override
  void initState() {
    super.initState();
    _manual = TextEditingController(text: widget.currentGoal.toString());
  }

  @override
  void dispose() {
    _manual.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  // ── Values ──────────────────────────────────────────────
  int? get _manualValue {
    final v = int.tryParse(_manual.text);
    if (v == null || v < _minGoal || v > _maxGoal) return null;
    return v;
  }

  bool _inRange(String text, int lo, int hi) {
    final v = int.tryParse(text);
    return v != null && v >= lo && v <= hi;
  }

  // Mifflin-St Jeor estimate, rounded to the nearest 50 kcal.
  int? get _calculatedValue {
    if (!_inRange(_age.text, 18, 90) ||
        !_inRange(_height.text, 120, 230) ||
        !_inRange(_weight.text, 30, 250)) {
      return null;
    }
    final age = int.parse(_age.text);
    final height = int.parse(_height.text);
    final weight = int.parse(_weight.text);

    final bmr = 10 * weight + 6.25 * height - 5 * age + (_male ? 5 : -161);
    final target = bmr * _activityFactors[_activity] + _aimAdjust[_aim];
    final rounded = (target / 50).round() * 50;
    return rounded.clamp(_safeFloor, _maxGoal).toInt();
  }

  int? get _value =>
      _mode == _GoalMode.manual ? _manualValue : _calculatedValue;

  String? _errorFor(String text, int lo, int hi, String message) {
    if (text.isEmpty) return null;
    return _inRange(text, lo, hi) ? null : message;
  }

  // ── UI helpers ──────────────────────────────────────────
  InputDecoration _dec({
    required String label,
    String? suffix,
    String? error,
    String? helper,
  }) {
    final isDark = widget.isDarkMode;
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      errorText: error,
      helperText: helper,
      filled: true,
      fillColor: isDark ? const Color(0xFF16241C) : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    String? error,
    String? helper,
  }) {
    final isDark = widget.isDarkMode;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
      ),
      decoration: _dec(
        label: label,
        suffix: suffix,
        error: error,
        helper: helper,
      ),
    );
  }

  Widget _choiceChips({
    required List<String> labels,
    required int selected,
    required ValueChanged<int> onSelected,
  }) {
    final isDark = widget.isDarkMode;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (i) {
        final isSel = selected == i;
        return ChoiceChip(
          label: Text(labels[i]),
          selected: isSel,
          onSelected: (_) => onSelected(i),
          selectedColor: isDark ? const Color(0xFF81C784) : AppColors.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel
                ? (isDark ? const Color(0xFF0A1F16) : Colors.white)
                : (isDark ? Colors.white70 : AppColors.ink),
          ),
        );
      }),
    );
  }

  Widget _sectionLabel(String text) {
    final isDark = widget.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[300] : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _manualForm() {
    return _numberField(
      controller: _manual,
      label: 'Daily calorie goal',
      suffix: 'cal',
      helper: 'Between $_minGoal and $_maxGoal',
      error: _errorFor(
        _manual.text,
        _minGoal,
        _maxGoal,
        'Enter a number between $_minGoal and $_maxGoal',
      ),
    );
  }

  Widget _calculateForm() {
    final isDark = widget.isDarkMode;
    final result = _calculatedValue;
    final muted = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Sex'),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Male')),
            ButtonSegment(value: false, label: Text('Female')),
          ],
          selected: {_male},
          onSelectionChanged: (s) => setState(() => _male = s.first),
        ),
        const SizedBox(height: 14),
        _numberField(
          controller: _age,
          label: 'Age',
          suffix: 'years',
          error: _errorFor(_age.text, 18, 90, 'Enter an age from 18 to 90'),
        ),
        const SizedBox(height: 12),
        _numberField(
          controller: _height,
          label: 'Height',
          suffix: 'cm',
          error: _errorFor(
              _height.text, 120, 230, 'Enter a height from 120 to 230 cm'),
        ),
        const SizedBox(height: 12),
        _numberField(
          controller: _weight,
          label: 'Weight',
          suffix: 'kg',
          error: _errorFor(
              _weight.text, 30, 250, 'Enter a weight from 30 to 250 kg'),
        ),
        const SizedBox(height: 14),
        _sectionLabel('Activity level'),
        _choiceChips(
          labels: _activityLabels,
          selected: _activity,
          onSelected: (i) => setState(() => _activity = i),
        ),
        const SizedBox(height: 14),
        _sectionLabel('My aim'),
        _choiceChips(
          labels: _aimLabels,
          selected: _aim,
          onSelected: (i) => setState(() => _aim = i),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF81C784).withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: tagRadius(r: 16, sharp: 6),
          ),
          child: Column(
            children: [
              Text(
                result == null
                    ? 'Fill in all fields to see your estimate'
                    : 'Your estimated daily goal',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: muted),
              ),
              if (result != null) ...[
                const SizedBox(height: 4),
                Text(
                  '$result cal',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF81C784) : AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'A general estimate only, not medical advice. '
                'Talk to a doctor or dietitian for personal guidance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1B3B2B) : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: tagRadius(r: 28, sharp: 10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Daily calorie goal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<_GoalMode>(
                segments: const [
                  ButtonSegment(
                    value: _GoalMode.manual,
                    label: Text('Enter myself'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                  ButtonSegment(
                    value: _GoalMode.calculate,
                    label: Text('Calculate'),
                    icon: Icon(Icons.calculate_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 18),
              if (_mode == _GoalMode.manual)
                _manualForm()
              else
                _calculateForm(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.white70 : AppColors.inkSoft,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: tagRadius(r: 16, sharp: 7),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _value == null
                            ? null
                            : () => Navigator.of(context).pop(_value),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: tagRadius(r: 16, sharp: 7),
                          ),
                        ),
                        child: const Text('Save goal'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
