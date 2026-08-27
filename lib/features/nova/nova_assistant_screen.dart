import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/gemini_service.dart';
import '../../services/nova_voice_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';
import '../../widgets/nova_voice_wave_visualizer.dart';
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

  final List<NovaMessage> _messages = [];
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _liveSpeechText = '';
  double _soundLevel = 0.0;

  StreamSubscription? _soundSub;
  StreamSubscription? _listeningSub;
  StreamSubscription? _speakingSub;

  final List<String> _quickPrompts = [
    'NIGHT MODE',
    'CHECK TELEMETRY',
    'SET VOLUME 30%',
    'TURN OFF WI-FI & BT',
    'DIM DISPLAY',
    'LOCK WORKSPACE',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Initial greeting
    _messages.add(
      NovaMessage(
        text: 'Nova Tactical Voice & AI Co-Pilot online. Standing by for voice and text commands.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

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
        // Noise Gate: filter ambient background hiss below 2.0 dB
        final cleanLevel = level > 2.0 ? level : 0.0;
        setState(() {
          _soundLevel = cleanLevel;
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

    _speakingSub = voice.speakingStateStream.listen((isSpeaking) {
      if (mounted) {
        setState(() {
          _isSpeaking = isSpeaking;
        });
      }
    });
  }

  @override
  void dispose() {
    _soundSub?.cancel();
    _listeningSub?.cancel();
    _speakingSub?.cancel();
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
      backgroundColor: const Color(0xFF0C0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0F14),
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
                      'WINTROLLER NOVA',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
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
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _isListening
                      ? 'VOICE FREQUENCY SYNCED'
                      : (_isProcessing ? 'PROCESSING PROTOCOL...' : 'GEMINI NEURAL CO-PILOT'),
                  style: GoogleFonts.shareTechMono(
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
            // Pro API Key Notice Banner if missing
            if (!proState.isPro && (proState.geminiApiKey == null || proState.geminiApiKey!.isEmpty))
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.5), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: Color(0xFFFFD600), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Configure Gemini API Key in Pro Settings for unmetered direct access.',
                          style: GoogleFonts.shareTechMono(fontSize: 11, color: const Color(0xFFFFD600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 1. Stitch Shader Voice Wave Visualizer Card (SYS_VIZ)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: _toggleVoiceListening,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF13171F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isListening
                          ? const Color(0xFFFF3366).withOpacity(0.8)
                          : colors.primary.withOpacity(0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? const Color(0xFFFF3366) : colors.primary).withOpacity(0.15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // SYS_VIZ Top Left Label
                      Positioned(
                        top: 8,
                        left: 12,
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening
                                    ? (_soundLevel > 0 ? const Color(0xFF00FF66) : colors.primary)
                                    : colors.primary.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SYS_VIZ // VOICE WAVE HARMONICS',
                              style: GoogleFonts.orbitron(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: _isListening ? const Color(0xFF00FF66) : colors.primary.withOpacity(0.8),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Top Right Frequency Status
                      Positioned(
                        top: 8,
                        right: 12,
                        child: Text(
                          _isListening
                              ? (_soundLevel > 0 ? 'VOICE: ACTIVE' : 'MIC: LISTENING')
                              : (_isSpeaking ? 'TTS: SPEAKING' : 'STANDBY'),
                          style: GoogleFonts.shareTechMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _isListening
                                ? (_soundLevel > 0 ? const Color(0xFF00FF66) : colors.primary.withOpacity(0.7))
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // The 5-Harmonic Voice Wave Visualizer Canvas
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 8),
                        child: NovaVoiceWaveVisualizer(
                          soundLevel: _soundLevel,
                          isListening: _isListening,
                          isSpeaking: _isSpeaking,
                          primaryColor: const Color(0xFF00FF66),
                          height: 120,
                        ),
                      ),
                      // Bottom Centered Status Indicator
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            _isListening
                                ? (_liveSpeechText.isNotEmpty ? '🎙️ "$_liveSpeechText"' : 'LISTENING TO VOICE FREQUENCY...')
                                : 'TAP SCREEN OR MIC TO TRANSMIT VOICE PROTOCOL',
                            style: GoogleFonts.orbitron(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _isListening ? Colors.white : colors.primary.withOpacity(0.6),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Terminal Log Section (TERMINAL LOG [ACTIVE])
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: Row(
                children: [
                  Text(
                    'TERMINAL LOG [ACTIVE]',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: colors.primary.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'AUTO_SYNC ON',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 9.5,
                      color: colors.primary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _NovaTerminalMessage(
                    message: msg,
                    onSpeak: () {
                      ref.read(novaVoiceServiceProvider).speak(msg.text);
                    },
                  );
                },
              ),
            ),

            // 3. Quick Action Chips (Stitch HUD style)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF13171F),
                      side: BorderSide(color: colors.primary.withOpacity(0.4), width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      label: Text(
                        prompt,
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      onPressed: _isProcessing ? null : () => _handleSend(prompt),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // 4. Futuristic Bottom Input Bar with Mic & Send
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
                        hintText: 'TYPE COMMAND OR TAP MIC...',
                        hintStyle: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary.withOpacity(0.35),
                          letterSpacing: 0.8,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF13171F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary, width: 1.4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Glowing Futuristic Mic Button
                  GestureDetector(
                    onTap: _toggleVoiceListening,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFFF3366)
                            : const Color(0xFF13171F),
                        border: Border.all(
                          color: _isListening ? const Color(0xFFFF3366) : colors.primary,
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? const Color(0xFFFF3366) : colors.primary).withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.white : colors.primary,
                        size: 22,
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

class _NovaTerminalMessage extends StatelessWidget {
  final NovaMessage message;
  final VoidCallback? onSpeak;

  const _NovaTerminalMessage({
    required this.message,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm:ss').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isUser ? 'USR_CMD // $timeStr' : 'SYS_RES // $timeStr',
                style: GoogleFonts.shareTechMono(
                  fontSize: 10,
                  color: isUser ? colors.onSurfaceVariant.withOpacity(0.7) : colors.primary.withOpacity(0.8),
                  letterSpacing: 0.8,
                ),
              ),
              if (!isUser && onSpeak != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onSpeak,
                  child: Icon(Icons.volume_up_rounded, color: colors.primary.withOpacity(0.7), size: 14),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.86,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF161B22)
                  : const Color(0xFF0F141C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUser
                    ? colors.primary.withOpacity(0.3)
                    : (message.isError ? colors.error : colors.primary.withOpacity(0.6)),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? '> ${message.text}' : message.text,
                  style: isUser
                      ? GoogleFonts.shareTechMono(
                          fontSize: 13,
                          color: colors.onSurface,
                        )
                      : GoogleFonts.shareTechMono(
                          fontSize: 13,
                          color: message.isError ? colors.error : colors.primary,
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
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.primary.withOpacity(0.7), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, color: colors.primary, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              action.message.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
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
