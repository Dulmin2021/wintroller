import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/gemini_service.dart';
import '../../services/nova_voice_service.dart';
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

class _NovaAssistantScreenState extends ConsumerState<NovaAssistantScreen> with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _pulseController;
  late final AnimationController _waveController;

  final List<NovaMessage> _messages = [];
  bool _isProcessing = false;
  bool _isListening = false;
  String _liveSpeechText = '';
  double _soundLevel = 0.0;

  StreamSubscription? _soundSub;
  StreamSubscription? _listeningSub;

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
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Initial greeting
    _messages.add(
      NovaMessage(
        text: 'Nova Tactical Voice & AI Co-Pilot online. Standing by for voice and text commands.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    // Speak initial greeting if voice is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voice = ref.read(novaVoiceServiceProvider);
      final isMuted = ref.read(voiceMutedProvider);
      voice.speak('Nova Voice Co-Pilot online. Standing by.', isMuted: isMuted);
      _initVoiceSubscriptions();
    });
  }

  void _initVoiceSubscriptions() {
    final voice = ref.read(novaVoiceServiceProvider);
    _soundSub = voice.soundLevelStream.listen((level) {
      if (mounted) {
        setState(() {
          _soundLevel = level;
        });
      }
    });

    _listeningSub = voice.listeningStateStream.listen((isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
          if (!isListening) {
            _soundLevel = 0.0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _soundSub?.cancel();
    _listeningSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
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

  Future<void> _toggleVoiceListening() async {
    final voice = ref.read(novaVoiceServiceProvider);

    if (_isListening) {
      await voice.stopListening();
      if (_liveSpeechText.trim().isNotEmpty) {
        final textToSend = _liveSpeechText.trim();
        setState(() {
          _liveSpeechText = '';
        });
        _handleSend(textToSend);
      }
      return;
    }

    final proState = ref.read(proPlanProvider);
    if (!proState.isPro && (proState.geminiApiKey == null || proState.geminiApiKey!.isEmpty)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
      );
      return;
    }

    setState(() {
      _liveSpeechText = '';
    });

    await voice.startListening(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            _liveSpeechText = text;
          });
          if (isFinal && text.trim().isNotEmpty) {
            voice.stopListening();
            _handleSend(text.trim());
            setState(() {
              _liveSpeechText = '';
            });
          }
        }
      },
    );
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = (presetText ?? _inputController.text).trim();
    if (text.isEmpty || _isProcessing) return;

    final voice = ref.read(novaVoiceServiceProvider);
    if (_isListening) {
      await voice.stopListening();
    }

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
      _liveSpeechText = '';
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

      // Speak response aloud via TTS
      final isMuted = ref.read(voiceMutedProvider);
      voice.speak(response.text, isMuted: isMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final proState = ref.watch(proPlanProvider);
    final isVoiceMuted = ref.watch(voiceMutedProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary, size: 20),
          onPressed: () {
            ref.read(novaVoiceServiceProvider).stopSpeaking();
            ref.read(novaVoiceServiceProvider).stopListening();
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final statusColor = _isListening
                    ? const Color(0xFFFF3366)
                    : (_isProcessing ? const Color(0xFFFFD600) : colors.primary);
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.5 + 0.4 * _pulseController.value),
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
                      'NOVA VOICE AI',
                      style: GoogleFonts.orbitron(
                        fontSize: 15,
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
                  _isListening
                      ? 'LISTENING TO VOICE...'
                      : (_isProcessing ? 'PROCESSING PROTOCOL...' : 'GEMINI NEURAL CO-PILOT'),
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isListening
                        ? const Color(0xFFFF3366)
                        : (_isProcessing ? const Color(0xFFFFD600) : colors.onSurfaceVariant),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice Response Audio Mute / Unmute Toggle
          IconButton(
            icon: Icon(
              isVoiceMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: isVoiceMuted ? colors.onSurfaceVariant : colors.primary,
              size: 22,
            ),
            tooltip: isVoiceMuted ? 'Voice Responses Muted' : 'Voice Responses Active',
            onPressed: () {
              ref.read(voiceMutedProvider.notifier).state = !isVoiceMuted;
              if (!isVoiceMuted) {
                ref.read(novaVoiceServiceProvider).stopSpeaking();
              }
            },
          ),
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
                      const Icon(Icons.lock_clock_rounded, color: Color(0xFFFFD600), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Configure Gemini API Key in Pro Settings for unmetered direct access.',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFD600),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFD600), size: 16),
                    ],
                  ),
                ),
              ),

            // Top Holographic AI Core (Tap to toggle Voice Listening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: HudFrame(
                chamferSize: 10,
                borderColor: _isListening
                    ? const Color(0xFFFF3366)
                    : colors.primary.withOpacity(0.6),
                backgroundColor: colors.surfaceContainer.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleVoiceListening,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = _isListening
                              ? 1.0 + (_soundLevel.clamp(0.0, 10.0) / 25.0)
                              : (1.0 + 0.08 * _pulseController.value);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening
                                    ? const Color(0xFFFF3366).withOpacity(0.2)
                                    : colors.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: _isListening ? const Color(0xFFFF3366) : colors.primary,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                _isListening ? Icons.mic_rounded : Icons.psychology_rounded,
                                color: _isListening ? const Color(0xFFFF3366) : colors.primary,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isListening ? 'VOICE FREQUENCY ENGAGED' : 'NOVA TACTICAL PROTOCOLS',
                            style: GoogleFonts.orbitron(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _isListening ? const Color(0xFFFF3366) : colors.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            _isListening
                                ? (_liveSpeechText.isNotEmpty ? '"$_liveSpeechText"' : 'Speak command now...')
                                : 'Automated hardware, audio, brightness & power co-pilot',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 11,
                              color: _isListening ? colors.onSurface : colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                        color: _isListening ? const Color(0xFFFF3366) : colors.primary,
                        size: 22,
                      ),
                      tooltip: _isListening ? 'Stop Voice' : 'Start Voice Input',
                      onPressed: _toggleVoiceListening,
                    ),
                  ],
                ),
              ),
            ),

            // Live Voice Waveform Bar (shown while listening)
            if (_isListening)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3366).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.6), width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_none_rounded, color: Color(0xFFFF3366), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _liveSpeechText.isNotEmpty
                            ? _liveSpeechText
                            : 'Listening to your voice command...',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sound Wave Bars Animation
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (i) {
                        return AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            final h = 6.0 + ((i + 1) * 3.5) * (_waveController.value + (_soundLevel / 10.0)).clamp(0.2, 1.2);
                            return Container(
                              width: 3,
                              height: h.clamp(4.0, 20.0),
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3366),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),

            // Chat Messages Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _NovaMessageBubble(
                    message: msg,
                    onSpeak: () {
                      ref.read(novaVoiceServiceProvider).speak(msg.text);
                    },
                  );
                },
              ),
            ),

            // Quick Prompt Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      backgroundColor: colors.surfaceContainer,
                      side: BorderSide(color: colors.primary.withOpacity(0.4), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      label: Text(
                        prompt,
                        style: GoogleFonts.rajdhani(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      onPressed: _isProcessing ? null : () => _handleSend(prompt),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Bottom Input Bar with Mic & Send
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        hintText: 'Voice or text: "Volume 40%", "Night mode"...',
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
                  // Mic Button (Voice Input Toggle)
                  GestureDetector(
                    onTap: _toggleVoiceListening,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFFF3366)
                            : colors.surfaceContainer,
                        border: Border.all(
                          color: _isListening ? const Color(0xFFFF3366) : colors.primary,
                          width: 1.2,
                        ),
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: const Color(0xFFFF3366).withOpacity(0.5),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.white : colors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Send Button
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
  final VoidCallback? onSpeak;

  const _NovaMessageBubble({
    required this.message,
    this.onSpeak,
  });

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
                const SizedBox(width: 6),
                if (onSpeak != null)
                  GestureDetector(
                    onTap: onSpeak,
                    child: Icon(Icons.volume_up_rounded, color: colors.primary.withOpacity(0.7), size: 14),
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
              maxWidth: MediaQuery.of(context).size.width * 0.84,
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
