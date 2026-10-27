import 'package:flutter/material.dart';

import '../models/food_history_item.dart';
import '../services/supabase_service.dart';

class HistoryScreenPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const HistoryScreenPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<HistoryScreenPage> createState() => _HistoryScreenPageState();
}

class _HistoryScreenPageState extends State<HistoryScreenPage> {
  final _service = SupabaseService();
  final _searchController = TextEditingController();

  List<FoodHistoryItem> foodHistory = [];
  bool isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= FETCH =================
  Future<void> fetchHistory() async {
    setState(() => isLoading = true);
    try {
      final items = await _service.fetchHistory();
      debugPrint('Fetched ${items.length} items');
      if (!mounted) return;
      setState(() {
        foodHistory = items;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchHistory error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Couldn't load your history. Pull down to try again.")),
      );
    }
  }

  // ================= DELETE =================
  Future<void> deleteItem(String id) async {
    try {
      await _service.deleteHistory(id);
      if (!mounted) return;
      setState(() => foodHistory.removeWhere((e) => e.id == id));
    } catch (e) {
      debugPrint('deleteItem error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  }

  // ================= SEARCH =================
  // Matches the food name or the date text (for example "24/10").
  List<FoodHistoryItem> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return foodHistory;
    return foodHistory.where((e) {
      return e.foodName.toLowerCase().contains(q) ||
          formatDate(e.timestamp).contains(q);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  // Shows the matching part of the name in bold with a soft highlight.
  Widget _highlightedName(String text, TextStyle base, bool isDark) {
    final q = _query.trim();
    if (q.isEmpty) return Text(text, style: base);

    final index = text.toLowerCase().indexOf(q.toLowerCase());
    if (index < 0 || index + q.length > text.length) {
      return Text(text, style: base);
    }

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + q.length),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              backgroundColor: isDark
                  ? const Color(0xFF81C784).withValues(alpha: 0.35)
                  : const Color(0xFFFFF59D),
            ),
          ),
          TextSpan(text: text.substring(index + q.length)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value),
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search food or date (e.g. 24/10)',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1B3B2B) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: border(borderColor),
          enabledBorder: border(borderColor),
          focusedBorder: border(Colors.green.shade600, 1.8),
        ),
      ),
    );
  }

  Widget _buildNoResults(bool isDark) {
    final muted = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: muted),
            const SizedBox(height: 12),
            Text(
              'No results for "${_query.trim()}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different food name or date.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _clearSearch,
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final results = _results;
    final isSearching = _query.trim().isNotEmpty;
    final muted = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );

    Widget body;
    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (foodHistory.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined, size: 52, color: muted),
            const SizedBox(height: 12),
            Text(
              'No food history yet',
              style: TextStyle(fontSize: 16, color: muted),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          _buildSearchBar(isDark),
          if (isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  liveRegion: true, // screen readers announce the count
                  child: Text(
                    results.length == 1
                        ? '1 result'
                        : '${results.length} results',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? _buildNoResults(isDark)
                : RefreshIndicator(
                    onRefresh: fetchHistory,
                    child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      // Extra bottom space so the floating button never
                      // covers the delete icon of the last item.
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: _highlightedName(
                                item.foodName, titleStyle, isDark),
                            subtitle: Text(
                              '${formatDate(item.timestamp)} • ${item.calories} cal',
                              style: TextStyle(color: muted),
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => deleteItem(item.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1B3B2B) : Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: fetchHistory,
          ),
        ],
      ),
      body: body,
    );
  }

  // ================= HELPERS =================
  String formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
