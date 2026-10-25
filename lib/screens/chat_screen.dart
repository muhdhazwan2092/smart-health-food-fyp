import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // TimeoutException
import 'package:flutter/services.dart'; // Clipboard
import 'package:flutter_markdown/flutter_markdown.dart';

import '../themes/app_theme.dart';

class ChatScreenPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const ChatScreenPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<ChatScreenPage> createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Gemini API configuration
  // TODO: move this to a secure location (e.g. --dart-define or a backend
  // proxy) before shipping — never commit a real API key to source control.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final String _modelEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          "Hi! I'm your nutrition assistant. Ask me about food, calories, or healthy eating. Type a question or tap a suggestion below.",
      'isUser': false,
    },
  ];

  // Starter suggestions (shown first, then replaced by context-aware ones)
  static const List<String> _starterQuestions = [
    'How many calories in an avocado?',
    'Best protein sources?',
    'Is brown rice healthier?',
    'How much water daily?',
    'Healthy breakfast ideas',
    'Foods for weight loss',
  ];

  List<String> _suggestions = List.of(_starterQuestions);
  final Set<String> _askedQuestions = {};

  // Attached to the newest bot message so we can scroll to the START of it.
  final GlobalKey _latestBotKey = GlobalKey();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Scrolls so the top of the newest bot reply is visible (not its bottom).
  void _scrollToLatestReply() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _latestBotKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    final question = message.trim();
    if (question.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'text': question, 'isUser': true});
      _askedQuestions.add(question.toLowerCase());
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final reply = await _getGeminiResponse(question);
      if (!mounted) return;

      setState(() {
        _messages.add({'text': reply.answer, 'isUser': false});
        _suggestions = _buildSuggestions(reply.followUps);
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text':
              'Sorry, that took too long. Please check your connection and try again.',
          'isUser': false,
        });
        _isLoading = false;
      });
    } catch (e) {
      // Log details for developers, but never show raw errors (they can
      // contain URLs / API keys) to the user.
      debugPrint('Gemini error: $e');
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text':
              "Sorry, I couldn't get an answer right now. Please try again in a moment.",
          'isUser': false,
        });
        _isLoading = false;
      });
    }

    _scrollToLatestReply();
  }

  void _handleTextFieldSubmit() {
    if (_isLoading) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _sendMessage(text);
  }

  /// Follow-ups from the model first, then unused starter questions.
  List<String> _buildSuggestions(List<String> followUps) {
    final fresh = _starterQuestions
        .where((q) => !_askedQuestions.contains(q.toLowerCase()));
    return {
      ...followUps.where((q) => !_askedQuestions.contains(q.toLowerCase())),
      ...fresh,
    }.toList();
  }

  /// Splits "FOLLOWUPS: a | b | c" off the end of the model's reply.
  ({String answer, List<String> followUps}) _parseReply(String raw) {
    final match = RegExp(
      r'^[\s*#]*FOLLOWUPS:[\s*]*(.+)$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(raw);

    if (match == null) return (answer: raw.trim(), followUps: const []);

    final followUps = match
        .group(1)!
        .replaceAll('*', '')
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length <= 40)
        .take(3)
        .toList();

    final answer = raw.replaceRange(match.start, match.end, '').trim();
    return (answer: answer, followUps: followUps);
  }

  Future<({String answer, List<String> followUps})> _getGeminiResponse(
      String userMessage) async {
    final endpoint = '$_modelEndpoint?key=$_apiKey';

    final prompt = '''
You are a friendly, professional nutrition and food safety assistant.

Rules:
- Start with the direct answer in ONE short sentence (example: "A medium avocado has about 240 calories."). No greeting and no filler.
- Then, only if useful, add up to 4 short bullet points with key details (macros, serving size, benefits or concerns, allergens).
- Keep the whole reply under 120 words.
- Use simple Markdown only (bold and bullet lists). Do NOT use headings, tables or horizontal rules.
- Values are estimates; mention when they vary by size or preparation.
- Finish with one last line in exactly this format, with 3 short follow-up questions (max 6 words each) related to the topic:
FOLLOWUPS: question one | question two | question three

User question: $userMessage
''';

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      debugPrint('API body: ${response.body}');
      throw Exception('API Error (${response.statusCode})');
    }

    final jsonBody = jsonDecode(response.body);
    final candidates = jsonBody['candidates'] as List?;

    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response generated');
    }

    final text =
        (candidates[0]?['content']?['parts']?[0]?['text'] as String?) ?? '';

    if (text.isEmpty) {
      throw Exception('Empty response received');
    }

    return _parseReply(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF0F1F17) : AppColors.bg;
    final panelColor = isDarkMode ? const Color(0xFF1B3B2B) : Colors.white;
    final mutedText = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Nutrition Chat',
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
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
            tooltip: 'Toggle Dark Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show typing indicator for last item when loading
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator(isDarkMode);
                }

                final message = _messages[index];
                final isUser = message['isUser'] as bool;
                final isLatestBot = !isUser && index == _messages.length - 1;

                return _buildMessageBubble(
                  message['text'] as String,
                  isUser,
                  isDarkMode,
                  key: isLatestBot ? _latestBotKey : null,
                  canCopy: !isUser && index > 0, // not for the welcome message
                );
              },
            ),
          ),

          // Quick question chips (context-aware, with a fade on the right
          // edge so it is obvious the row scrolls)
          if (!_isLoading && _suggestions.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.9, 1.0],
                ).createShader(rect),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 32),
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final q = _suggestions[index];
                    return ActionChip(
                      label: Text(
                        q,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.87)
                              : AppColors.ink,
                        ),
                      ),
                      backgroundColor: isDarkMode
                          ? const Color(0xFF2C4A3A)
                          : AppColors.accentSoft.withOpacity(0.55),
                      side: BorderSide(
                        color: isDarkMode
                            ? AppColors.primaryLight.withOpacity(0.5)
                            : AppColors.primary.withOpacity(0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: tagRadius(r: 20, sharp: 6),
                      ),
                      onPressed: () => _sendMessage(q),
                    );
                  },
                ),
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: panelColor,
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.grey)
                      .withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          // Stay enabled while loading so the keyboard does
                          // not collapse; sending is blocked in code instead.
                          textInputAction: TextInputAction.send,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.87)
                                : AppColors.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: _isLoading
                                ? 'Waiting for answer...'
                                : 'Ask about nutrition...',
                            hintStyle: TextStyle(color: mutedText),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? const Color(0xFF2C4A3A)
                                : AppColors.bg,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            suffixIcon: _messageController.text.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Clear',
                                    icon: Icon(Icons.clear,
                                        color: mutedText, size: 20),
                                    onPressed: () {
                                      _messageController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) => setState(() {}),
                          onSubmitted: (_) => _handleTextFieldSubmit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isLoading
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : (isDarkMode
                                    ? [
                                        AppColors.primaryLight,
                                        AppColors.primary
                                      ]
                                    : [
                                        AppColors.primary,
                                        AppColors.primaryLight
                                      ]),
                          ),
                        ),
                        child: IconButton(
                          tooltip: 'Send message',
                          onPressed: _isLoading ? null : _handleTextFieldSubmit,
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nutrition values are estimates, not medical advice.',
                    style: TextStyle(fontSize: 11, color: mutedText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String text,
    bool isUser,
    bool isDarkMode, {
    Key? key,
    bool canCopy = false,
  }) {
    final botTextColor =
        isDarkMode ? Colors.white.withOpacity(0.92) : AppColors.ink;
    final botNameColor =
        isDarkMode ? const Color(0xFF9BE0B5) : AppColors.primaryDark;

    return Align(
      key: key,
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.85),
        ),
        decoration: BoxDecoration(
          color: isUser
              ? (isDarkMode ? AppColors.primaryLight : AppColors.primary)
              : (isDarkMode ? const Color(0xFF1B3B2B) : Colors.white),
          // Subtle outline so the bot bubble stands out from the dark background
          border: (!isUser && isDarkMode)
              ? Border.all(color: Colors.white.withOpacity(0.10))
              : null,
          // Bubbles keep the app's tag motif: sharp corner on the side
          // pointing toward the sender.
          borderRadius: isUser
              ? const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_outlined, size: 14, color: botNameColor),
                    const SizedBox(width: 4),
                    Text(
                      'Nutrition Assistant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: botNameColor,
                      ),
                    ),
                  ],
                ),
              ),

            // Bot replies are rendered as Markdown (bold, bullets, ...)
            // instead of showing raw **, ### and --- symbols.
            if (isUser)
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            else
              MarkdownBody(
                data: text,
                styleSheet:
                    MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(color: botTextColor, fontSize: 16, height: 1.4),
                  strong: TextStyle(
                    color: botTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  listBullet: TextStyle(color: botTextColor, fontSize: 16),
                  blockSpacing: 8,
                  listIndent: 16,
                ),
              ),

            if (isUser)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),

            if (canCopy)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Copy answer',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  color: botNameColor,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDarkMode) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1B3B2B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? Colors.white.withOpacity(0.87) : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Thinking...',
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.87)
                    : AppColors.inkSoft,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
