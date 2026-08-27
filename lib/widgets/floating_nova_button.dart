import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_service.dart';
import '../services/nova_voice_service.dart';
import '../theme/app_colors.dart';
import 'alien_icons.dart';
import 'nova_voice_wave_visualizer.dart';

final floatingNovaButtonEnabledProvider = StateProvider<bool>((ref) => true);

class GlobalFloatingNovaButton extends ConsumerStatefulWidget {
  const GlobalFloatingNovaButton({super.key});

  @override
  ConsumerState<GlobalFloatingNovaButton> createState() => _GlobalFloatingNovaButtonState();
}

class _GlobalFloatingNovaButtonState extends ConsumerState<GlobalFloatingNovaButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Offset _position = const Offset(20, 520);
  bool _isDragging = false;
  bool _isExpanded = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _liveSpeechText = '';
  String _lastResponse = '';
  List<NovaActionResult> _executedActions = [];
  double _soundLevel = 0.0;
  Timer? _autoDismissTimer;

  StreamSubscription? _soundSub;
  StreamSubscription? _listeningSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _soundSub?.cancel();
    _listeningSub?.cancel();
    _autoDismissTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initSubscriptions() {
    final voice = ref.read(novaVoiceServiceProvider);
    _soundSub?.cancel();
    _soundSub = voice.soundLevelStream.listen((rawLevel) {
      if (mounted) {
        final cleanLevel = rawLevel > 2.0 ? rawLevel : 0.0;
        setState(() {
          _soundLevel = cleanLevel;
        });
      }
    });

    _listeningSub?.cancel();
    _listeningSub = voice.listeningStateStream.listen((listening) {
      if (mounted) {
        setState(() {
          _isListening = listening;
          if (!listening) {
            _soundLevel = 0.0;
          }
        });
      }
    });
  }

  Future<void> _startVoiceCapture() async {
    _autoDismissTimer?.cancel();
    final voice = ref.read(novaVoiceServiceProvider);

    setState(() {
      _isExpanded = true;
      _isListening = true;
      _liveSpeechText = '';
      _lastResponse = '';
      _executedActions = [];
    });

    _initSubscriptions();

    await voice.startListening(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            _liveSpeechText = text;
          });

          if (isFinal && text.trim().isNotEmpty) {
            voice.stopListening();
            _processCommand(text.trim());
          }
        }
      },
    );
  }

  Future<void> _processCommand(String text) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isListening = false;
    });

    final gemini = ref.read(geminiServiceProvider);
    final response = await gemini.processCommand(text);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastResponse = response.text;
        _executedActions = response.executedActions;
      });

      // Speak response aloud via TTS
      final voice = ref.read(novaVoiceServiceProvider);
      final isMuted = ref.read(voiceMutedProvider);
      voice.speak(response.text, isMuted: isMuted);

      // Automatically collapse after 3.5s so user is never blocked
      _autoDismissTimer?.cancel();
      _autoDismissTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted && _isExpanded && !_isListening && !_isProcessing) {
          _closeOverlay();
        }
      });
    }
  }

  void _closeOverlay() {
    _autoDismissTimer?.cancel();
    final voice = ref.read(novaVoiceServiceProvider);
    voice.stopListening();
    voice.stopSpeaking();

    setState(() {
      _isExpanded = false;
      _isListening = false;
      _isProcessing = false;
      _liveSpeechText = '';
      _lastResponse = '';
      _executedActions = [];
      _soundLevel = 0.0;
    });
  }

  void _onOrbTap() {
    HapticFeedback.mediumImpact();
    if (_isExpanded) {
      _closeOverlay();
    } else {
      _startVoiceCapture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(floatingNovaButtonEnabledProvider);
    if (!isEnabled) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Position setup
    if (_position == const Offset(20, 520) && screenSize.width > 100) {
      _position = Offset(screenSize.width - 72, screenSize.height - 190);
    }

    return Stack(
      children: [
        // 1. Full In-Place Cybernetic Voice HUD Overlay when active
        if (_isExpanded)
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1318),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isListening
                        ? const Color(0xFF00FF66)
                        : (_isProcessing ? const Color(0xFFFFD600) : colors.primary),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? const Color(0xFF00FF66) : colors.primary).withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar with Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening
                                    ? const Color(0xFF00FF66)
                                    : (_isProcessing ? const Color(0xFFFFD600) : colors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NOVA VOICE HUD',
                              style: GoogleFonts.orbitron(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: colors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isListening
                                    ? 'LISTENING'
                                    : (_isProcessing ? 'EXECUTING' : 'READY'),
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _closeOverlay,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.surfaceContainer,
                            ),
                            child: Icon(Icons.close_rounded, color: colors.onSurfaceVariant, size: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Stitch 5-Harmonic Sine Wave Visualizer
                    GestureDetector(
                      onTap: _isListening ? null : _startVoiceCapture,
                      child: Container(
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFF07090C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: NovaVoiceWaveVisualizer(
                            soundLevel: _soundLevel,
                            isListening: _isListening,
                            isSpeaking: false,
                            primaryColor: const Color(0xFF00FF66),
                            height: 75,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Speech Subtitle / Result Text
                    if (_liveSpeechText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🎙️ "$_liveSpeechText"',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (_lastResponse.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _lastResponse,
                          style: GoogleFonts.shareTechMono(
                            fontSize: 11.5,
                            color: colors.primary,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          'SPEAK YOUR DIRECTIVE (e.g. "Lock PC", "Volume 40%")...',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10,
                            color: colors.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                    // Executed action badges
                    if (_executedActions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _executedActions.map((action) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF66).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFF00FF66), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, color: Color(0xFF00FF66), size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  action.message.toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF00FF66),
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
            ),
          ),

        // 2. The Draggable Floating Nova Orb
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                final newX = (_position.dx + details.delta.dx).clamp(10.0, screenSize.width - 66.0);
                final newY = (_position.dy + details.delta.dy).clamp(60.0, screenSize.height - 120.0);
                _position = Offset(newX, newY);
              });
            },
            onPanEnd: (_) {
              setState(() {
                _isDragging = false;
                // Snap to closest edge
                final mid = screenSize.width / 2;
                final targetX = _position.dx < mid ? 12.0 : screenSize.width - 66.0;
                _position = Offset(targetX, _position.dy);
              });
            },
            onTap: _onOrbTap,
            child: Material(
              type: MaterialType.transparency,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowAlpha = _isExpanded
                      ? 0.8
                      : (_isDragging ? 0.6 : (0.25 + 0.35 * _pulseController.value));
                  final isGlowing = _isExpanded || _isListening;

                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGlowing ? const Color(0xFF00FF66).withOpacity(0.2) : const Color(0xFF0D1117),
                      border: Border.all(
                        color: isGlowing ? const Color(0xFF00FF66) : colors.primary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF66).withOpacity(glowAlpha),
                          blurRadius: 14 * (_isDragging ? 1.4 : _pulseController.value + 0.5),
                          spreadRadius: 1.5,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radar ring
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00FF66).withOpacity(0.4),
                              width: 0.8,
                            ),
                          ),
                        ),
                        // Alien Emblem or Mic Icon
                        Icon(
                          isGlowing ? Icons.mic_rounded : Icons.psychology_rounded,
                          color: isGlowing ? Colors.white : const Color(0xFF00FF66),
                          size: 24,
                        ),
                        // Mini "NOVA" badge
                        Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF66),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'NOVA',
                              style: GoogleFonts.orbitron(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
