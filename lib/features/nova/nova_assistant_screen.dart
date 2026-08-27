import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';
import '../pro/pro_plan_provider.dart';
import '../pro/pro_upgrade_screen.dart';

class NovaMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<NovaActionResult> executedActions;
  final bool isError;

  const NovaMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.executedActions = const [],
    this.isError = false,
  });
}

class NovaAssistantScreen extends ConsumerStatefulWidget {
  const NovaAssistantScreen({super.key});

  @override
  ConsumerState<NovaAssistantScreen> createState() => _NovaAssistantScreenState();
}

class _NovaAssistantScreenState extends ConsumerState<NovaAssistantScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _pulseController;

  final List<NovaMessage> _messages = [];
  bool _isProcessing = false;

  final List<String> _quickPrompts = [
    'Night Mode: Display off & mute',
    'Set master volume to 30%',
    'Check PC battery and load',
    'Turn OFF Wi-Fi and Bluetooth',
    'Turn ON Display and unmute',
    'Lock Windows Workspace',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Initial greeting
    _messages.add(
      NovaMessage(
        text: 'Nova Tactical AI online. Standing by for hardware, media, and power protocols.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
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

  Future<void> _handleSend([String? presetText]) async {
    final text = (presetText ?? _inputController.text).trim();
    if (text.isEmpty || _isProcessing) return;

    final proState = ref.read(proPlanProvider);
    if (!proState.isPro && (proState.geminiApiKey == null || proState.geminiApiKey!.isEmpty)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
      );
      return;
    }

    _inputController.clear();
    setState(() {
      _messages.add(
        NovaMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isProcessing = true;
    });
    _scrollToBottom();

    final gemini = ref.read(geminiServiceProvider);
    final response = await gemini.processCommand(text);

    if (mounted) {
      setState(() {
        _messages.add(
          NovaMessage(
            text: response.text,
            isUser: false,
            timestamp: DateTime.now(),
            executedActions: response.executedActions,
            isError: response.isError,
          ),
        );
        _isProcessing = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final proState = ref.watch(proPlanProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isProcessing ? const Color(0xFFFFD600) : colors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isProcessing ? const Color(0xFFFFD600) : colors.primary)
                            .withOpacity(0.5 + 0.4 * _pulseController.value),
                        blurRadius: 10 * _pulseController.value,
                        spreadRadius: 2 * _pulseController.value,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'NOVA AI',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.primary, width: 0.8),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.orbitron(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _isProcessing ? 'PROCESSING PROTOCOL...' : 'GEMINI NEURAL CO-PILOT',
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: colors.primary, size: 22),
            tooltip: 'Pro Configuration',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pro API Key Warning Banner if missing
            if (!proState.isPro && (proState.geminiApiKey == null || proState.geminiApiKey!.isEmpty))
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.5), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded, color: Color(0xFFFFD600), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap here to add your Gemini API Key to enable Nova AI voice & text controls.',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFD600),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFD600), size: 12),
                    ],
                  ),
                ),
              ),

            // Messages Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _NovaMessageBubble(message: msg);
                },
              ),
            ),

            // Quick Tactical Chips
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    backgroundColor: colors.surfaceContainer,
                    side: BorderSide(color: colors.primary.withOpacity(0.4), width: 0.8),
                    label: Text(
                      prompt,
                      style: GoogleFonts.rajdhani(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    onPressed: () => _handleSend(prompt),
                  );
                },
              ),
            ),

            // Input Command Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                border: Border(
                  top: BorderSide(color: colors.outlineVariant.withOpacity(0.6), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 13,
                        color: colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Command Nova: "Set volume 40%", "Night mode"...',
                        hintStyle: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: colors.onSurfaceVariant.withOpacity(0.5),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: colors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: colors.primary, width: 1.4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 20),
                      onPressed: _isProcessing ? null : () => _handleSend(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovaMessageBubble extends StatelessWidget {
  final NovaMessage message;

  const _NovaMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                const AlienEmblem(size: 16, hasGlow: false),
                const SizedBox(width: 6),
                Text(
                  'NOVA CO-PILOT',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ] else ...[
                Text(
                  'YOU',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? colors.primaryContainer.withOpacity(0.2)
                  : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUser
                    ? colors.primary.withOpacity(0.5)
                    : (message.isError ? colors.error : colors.primary.withOpacity(0.4)),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: isUser
                      ? GoogleFonts.shareTechMono(
                          fontSize: 13,
                          color: colors.onSurface,
                        )
                      : GoogleFonts.rajdhani(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: message.isError ? colors.error : colors.onSurface,
                          letterSpacing: 0.2,
                        ),
                ),
                if (message.executedActions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: message.executedActions.map((action) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.primary.withOpacity(0.6), width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, color: colors.primary, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              action.message,
                              style: GoogleFonts.shareTechMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
