import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/scan_controller.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../models/food_analysis_result.dart';

class ScanScreenPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const ScanScreenPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<ScanScreenPage> createState() => _ScanScreenPageState();
}

class _ScanScreenPageState extends State<ScanScreenPage> {
  // The key is passed in at run/build time and is NOT stored in the code:
  //   flutter run --dart-define-from-file=env.json
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final picker = ImagePicker();
  late final ScanController controller;

  File? selectedImage;
  Uint8List? selectedImageBytes;
  FoodAnalysisResult? result;
  bool isProcessing = false;

  /// Friendly message shown with the "Try again" button. Null = no error.
  String? errorMessage;

  bool get _hasImage => selectedImage != null || selectedImageBytes != null;

  @override
  void initState() {
    super.initState();
    controller = ScanController(
      api: ApiService('GEMINI', _apiKey),
      supabase: SupabaseService(),
      storage: StorageService(),
    );
  }

  // ======================
  // PICK IMAGE
  // ======================
  Future<void> _pickImage(ImageSource source) async {
    if (isProcessing) return; // don't swap the photo mid-analysis

    final img = await picker.pickImage(source: source);
    if (img == null) return;

    if (kIsWeb) {
      final bytes = await img.readAsBytes();
      setState(() {
        selectedImage = null;
        selectedImageBytes = bytes;
        result = null;
        errorMessage = null;
      });
    } else {
      setState(() {
        selectedImage = File(img.path);
        selectedImageBytes = null;
        result = null;
        errorMessage = null;
      });
    }
    analyzeFood();
  }

  Future<void> pickCamera() => _pickImage(ImageSource.camera);
  Future<void> pickGallery() => _pickImage(ImageSource.gallery);

  // ======================
  // ANALYZE FOOD (also used by the "Try again" button)
  // ======================
  Future<void> analyzeFood() async {
    if (isProcessing) return; // ignore double taps
    if (!_hasImage) return;
    setState(() => isProcessing = true);

    try {
      late final FoodAnalysisResult data;

      if (selectedImage != null) {
        data = await controller.analyze(selectedImage!);
        await controller.saveResult(data, selectedImage!.path, []);
      } else {
        data = await controller.analyzeBytes(selectedImageBytes!);
        await controller.saveResult(
          data,
          'web_scan_${DateTime.now().millisecondsSinceEpoch}',
          [],
        );
      }

      if (!mounted) return;
      setState(() {
        result = data;
        errorMessage = null;
        isProcessing = false;
      });
    } catch (e) {
      debugPrint('analyzeFood error: $e'); // full details stay in the console
      if (!mounted) return;
      setState(() {
        errorMessage = _friendlyError(e);
        isProcessing = false;
      });
    }
  }

  /// Turns a raw exception into a short, human message.
  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();

    if (e is TimeoutException ||
        msg.contains('timeout') ||
        msg.contains('timed out')) {
      return 'Analysis took too long. Check your connection and try again.';
    }
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('clientexception') ||
        msg.contains('network')) {
      return 'No internet connection. Check your connection and try again.';
    }
    if (msg.contains('429') || msg.contains('quota')) {
      return 'Too many requests right now. Please wait a minute and try again.';
    }
    if (msg.contains('403') || msg.contains('api key')) {
      return 'The AI service rejected the request. The API key may be missing or wrong.';
    }
    if (msg.contains('503') || msg.contains('overloaded')) {
      return 'The AI service is busy right now. Please try again in a moment.';
    }
    return "Couldn't analyze this image. Please try again.";
  }

  // ======================
  // ERROR CARD + TRY AGAIN
  // ======================
  Widget _buildErrorCard(bool isDark) {
    final textColor = isDark ? Colors.red.shade100 : Colors.red.shade900;

    return Semantics(
      liveRegion: true, // screen readers announce the error when it appears
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                // Disabled while working, so it can't be tapped twice.
                onPressed: isProcessing ? null : analyzeFood,
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(isProcessing ? 'Analyzing...' : 'Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.green.shade700.withValues(alpha: 0.65),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================
  // RESULT CARD
  // ======================
  Widget _buildResultCard(bool isDark) {
    final r = result!;
    final scoreColor = r.healthScore >= 7
        ? Colors.green
        : r.healthScore >= 4
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Food name + health score ───────────────
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.foodName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: scoreColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${r.healthScore}/10',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            'Serving: ${r.servingSize}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),

          const SizedBox(height: 20),

          // ── Calories ──────────────────────────────
          Center(
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: r.calories.toDouble()),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    '${value.round()}',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 94, 76, 175),
                    ),
                  ),
                ),
                Text(
                  'Estimated Calories',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Nutrition breakdown ───────────────────
          _sectionTitle('Nutrition Breakdown', isDark),
          const SizedBox(height: 10),
          _buildNutritionGrid(r.nutrition, isDark),

          const SizedBox(height: 20),

          // ── Allergens ─────────────────────────────
          _sectionTitle('Allergens', isDark),
          const SizedBox(height: 8),
          r.allergens.isEmpty
              ? _infoPill('None detected', Colors.green, isDark)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: r.allergens
                      .map((a) => _infoPill(a, Colors.red, isDark))
                      .toList(),
                ),

          const SizedBox(height: 20),

          // ── Diet tags ─────────────────────────────
          if (r.dietTags.isNotEmpty) ...[
            _sectionTitle('Diet Tags', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: r.dietTags
                  .map((t) => _infoPill(t, Colors.blue, isDark))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // ── Ingredients ───────────────────────────
          _sectionTitle('Ingredients', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: r.ingredients
                .map((e) => Chip(
                      label: Text(e, style: const TextStyle(fontSize: 12)),
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF1F8F4),
                    ))
                .toList(),
          ),

          const SizedBox(height: 20),

          // ── Health notes ──────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF263238) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.healthNotes,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _infoPill(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNutritionGrid(NutritionInfo n, bool isDark) {
    final items = [
      ('Protein', '${n.proteinG.toStringAsFixed(1)}g', Colors.blue),
      ('Carbs', '${n.carbsG.toStringAsFixed(1)}g', Colors.orange),
      ('Fat', '${n.fatG.toStringAsFixed(1)}g', Colors.red),
      ('Fiber', '${n.fiberG.toStringAsFixed(1)}g', Colors.green),
      ('Sugar', '${n.sugarG.toStringAsFixed(1)}g', Colors.pink),
      ('Sodium', '${n.sodiumMg.toStringAsFixed(0)}mg', Colors.purple),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: items.map((item) {
        final (label, value, color) = item;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        title: Text(
          'Food Scanner',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
        backgroundColor: isDark ? const Color(0xFF1B3B2B) : Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Food',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Upload a photo to analyze nutrition, allergens & more.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Upload buttons ─────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: pickCamera,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green),
                              color: isDark ? const Color(0xFF2A2A2A) : null,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFFE8F5E9),
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.green),
                                ),
                                SizedBox(height: 10),
                                Text('Take Photo',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text('Use camera',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: pickGallery,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green),
                              color: isDark ? const Color(0xFF2A2A2A) : null,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFFE8F5E9),
                                  child: Icon(Icons.image, color: Colors.green),
                                ),
                                SizedBox(height: 10),
                                Text('Gallery',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text('JPG, PNG',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      selectedImage!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                if (selectedImage == null && selectedImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      selectedImageBytes!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 15),

                // Shown only when the analysis failed. Keeps the same photo
                // so "Try again" doesn't need a new pick.
                if (errorMessage != null && _hasImage) _buildErrorCard(isDark),

                if (result != null) _buildResultCard(isDark),
              ],
            ),
          ),
          // Full-screen loader for the first attempt. During a retry the
          // spinner lives inside the "Try again" button instead.
          if (isProcessing && errorMessage == null)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Analyzing food...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
