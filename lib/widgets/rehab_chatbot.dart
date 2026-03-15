import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../domain/models/session_model.dart';

// ── Public entry point ─────────────────────────────────────────────────────

void showRehabChatbot(BuildContext context, List<SessionModel> sessions) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChatSheet(sessions: sessions),
  );
}

// ── Bottom sheet shell ─────────────────────────────────────────────────────

class _ChatSheet extends StatelessWidget {
  final List<SessionModel> sessions;
  const _ChatSheet({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _ChatBody(sessions: sessions),
      ),
    );
  }
}

// ── Chat body ──────────────────────────────────────────────────────────────

class _ChatBody extends StatefulWidget {
  final List<SessionModel> sessions;
  const _ChatBody({required this.sessions});

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  static const _apiKey = 'AIzaSyDK9kEIIToblpmkI66Cp2z9V4eThDPqtV8';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];
  bool _thinking = false;

  // Suggested prompts shown before first message
  static const _suggestions = [
    'How is my recovery trending?',
    'What should I focus on this week?',
    'Explain my fall risk level',
    'Am I improving compared to last session?',
  ];

  @override
  void initState() {
    super.initState();
    // Greeting
    _messages.add(_Msg(
      role: 'assistant',
      text: widget.sessions.isEmpty
          ? "Hi! I'm your StepSure rehab assistant. Complete a session first and I'll be able to give you personalised insights."
          : "Hi! I've reviewed your ${widget.sessions.length} session${widget.sessions.length > 1 ? 's' : ''}. "
              "Your latest recovery score is ${widget.sessions.last.recoveryScore.toStringAsFixed(1)}/100. "
              "What would you like to know?",
    ));
  }

  // ── Context builder ──────────────────────────────────────────────────────

  String _buildSystemContext() {
    if (widget.sessions.isEmpty) {
      return 'The patient has no recorded sessions yet.';
    }

    final latest = widget.sessions.last;
    final best = widget.sessions
        .map((s) => s.recoveryScore)
        .reduce((a, b) => a > b ? a : b);
    final avg = widget.sessions
            .map((s) => s.recoveryScore)
            .reduce((a, b) => a + b) /
        widget.sessions.length;

    // Trend: compare last 3 sessions if available
    String trendText = 'Not enough sessions for trend analysis.';
    if (widget.sessions.length >= 3) {
      final recent = widget.sessions
          .sublist(widget.sessions.length - 3)
          .map((s) => s.recoveryScore)
          .toList();
      final trending = recent.last > recent.first ? 'improving' : 'declining';
      trendText =
          'Last 3 sessions: ${recent.map((s) => s.toStringAsFixed(1)).join(', ')} — $trending.';
    }

    final sessionSummaries = widget.sessions
        .asMap()
        .entries
        .map((e) =>
            'Session ${e.key + 1} (${e.value.sessionDate.toString().substring(0, 10)}): '
            'score=${e.value.recoveryScore.toStringAsFixed(1)}, '
            'cadence=${e.value.cadence.toStringAsFixed(0)}, '
            'symmetry=${e.value.symmetry.toStringAsFixed(1)}%, '
            'consistency=${e.value.strideConsistency.toStringAsFixed(1)}%, '
            'fallRisk=${e.value.fallRisk}')
        .join('\n');

    return '''
You are a warm, encouraging physiotherapy AI assistant inside the StepSure app.
You have access to the patient's full gait session history. Be specific — always reference actual numbers.
Keep responses concise (3–5 sentences max) unless the patient asks for detail.
Never recommend stopping rehabilitation. Always encourage consistency.

PATIENT SESSION DATA:
Total sessions: ${widget.sessions.length}
Best recovery score: ${best.toStringAsFixed(1)}/100
Average recovery score: ${avg.toStringAsFixed(1)}/100
Trend: $trendText

Latest session:
- Recovery Score: ${latest.recoveryScore.toStringAsFixed(1)}/100
- Fall Risk: ${latest.fallRisk.toUpperCase()}
- Cadence: ${latest.cadence.toStringAsFixed(1)} steps/min
- Symmetry: ${latest.symmetry.toStringAsFixed(1)}%
- Stride Consistency: ${latest.strideConsistency.toStringAsFixed(1)}%
- Stride Length: ${latest.strideLength.toStringAsFixed(2)} m
- Joint Deviation: ${latest.jointDeviation.toStringAsFixed(1)}%
- Duration: ${(latest.durationSeconds / 60).toStringAsFixed(1)} min

All sessions:
$sessionSummaries
''';
  }

  // ── Gemini call ───────────────────────────────────────────────────────────

  Future<String> _askGemini(String userMessage) async {
    // Build conversation history for multi-turn context
    final contents = <Map<String, dynamic>>[];

    // System context as first user turn (Gemini doesn't have system role)
    contents.add({
      'role': 'user',
      'parts': [{'text': _buildSystemContext()}],
    });
    contents.add({
      'role': 'model',
      'parts': [{'text': 'Understood. I have reviewed the patient data and am ready to help.'}],
    });

    // Add conversation history (skip greeting)
    for (final msg in _messages.skip(1)) {
      contents.add({
        'role': msg.role == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg.text}],
      });
    }

    // Add current message
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    // Retry logic for rate limits
    int retries = 0;
    const maxRetries = 3;
    while (retries < maxRetries) {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': contents,
              'generationConfig': {
                'temperature': 0.5,
                'maxOutputTokens': 512,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['candidates'][0]['content']['parts'][0]['text'] as String;
      } else if (response.statusCode == 429) {
        // Rate limited, wait and retry
        retries++;
        if (retries < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retries)); // Exponential backoff
          continue;
        }
      }
      throw Exception('${response.statusCode}');
    }
    throw Exception('429');
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    final input = text.trim();
    if (input.isEmpty || _thinking) return;

    _controller.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', text: input));
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final reply = await _askGemini(input);
      setState(() {
        _messages.add(_Msg(role: 'assistant', text: reply));
        _thinking = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Msg(
          role: 'assistant',
          text: e.toString().contains('429')
              ? "I'm receiving too many requests right now. Please wait a moment and try again."
              : "Sorry, I couldn't connect right now. Check your internet and try again.",
        ));
        _thinking = false;
      });
    }
    _scrollToBottom();
  }

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

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _messages.length == 1; // only greeting shown

    return Column(
      children: [
        // Handle bar
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A890), Color(0xFF0A7EA4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rehab Assistant',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Powered by Gemini',
                      style:
                          TextStyle(fontSize: 11, color: Color(0xFF00A890))),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _messages.length + (showSuggestions ? 1 : 0) + (_thinking ? 1 : 0),
            itemBuilder: (context, index) {
              // Suggestions row
              if (showSuggestions && index == 1) {
                return _SuggestionsRow(
                  suggestions: _suggestions,
                  onTap: _send,
                );
              }

              final adjustedIndex =
                  showSuggestions && index > 1 ? index - 1 : index;

              // Thinking bubble
              if (_thinking && adjustedIndex == _messages.length) {
                return const _ThinkingBubble();
              }

              return _MessageBubble(msg: _messages[adjustedIndex]);
            },
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(
              12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask about your recovery...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF2F4F6),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _send(_controller.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A890), Color(0xFF0A7EA4)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _Msg {
  final String role; // 'user' | 'assistant'
  final String text;
  _Msg({required this.role, required this.text});
}

class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A890), Color(0xFF0A7EA4)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF0A7EA4) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A890), Color(0xFF0A7EA4)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Interval(widget.delay / 1000, 1.0, curve: Curves.easeInOut),
    ));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FadeTransition(
          opacity: _anim,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF00A890),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _SuggestionsRow extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionsRow({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map((s) => GestureDetector(
                  onTap: () => onTap(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A890).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF00A890).withValues(alpha: 0.3)),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF00A890))),
                  ),
                ))
            .toList(),
      ),
    );
  }
}