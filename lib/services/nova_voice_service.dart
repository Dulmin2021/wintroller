import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

final voiceMutedProvider = StateProvider<bool>((ref) => false);
final wakeWordEnabledProvider = StateProvider<bool>((ref) => true);

class NovaVoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isWakeWordLoopActive = false;
  bool _isWakeWordMode = false;

  Timer? _wakeWordRestartTimer;

  final _recognizedTextController = StreamController<String>.broadcast();
  final _soundLevelController = StreamController<double>.broadcast();
  final _listeningStateController = StreamController<bool>.broadcast();
  final _speakingStateController = StreamController<bool>.broadcast();
  final _wakeWordTriggerController = StreamController<String?>.broadcast();

  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  Stream<bool> get listeningStateStream => _listeningStateController.stream;
  Stream<bool> get speakingStateStream => _speakingStateController.stream;
  Stream<String?> get wakeWordTriggerStream => _wakeWordTriggerController.stream;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSpeechAvailable => _isSpeechInitialized;
  bool get isWakeWordMode => _isWakeWordMode;

  NovaVoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.52);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.05); // Sleek cybernetic co-pilot tone

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakingStateController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingStateController.add(false);
        // After speaking ends, resume wake word loop if enabled
        if (_isWakeWordLoopActive) {
          _scheduleWakeWordRestart(const Duration(milliseconds: 400));
        }
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _speakingStateController.add(false);
        if (_isWakeWordLoopActive) {
          _scheduleWakeWordRestart(const Duration(milliseconds: 400));
        }
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<bool> initSpeech() async {
    if (_isSpeechInitialized) return true;

    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          return false;
        }
      }

      _isSpeechInitialized = await _speechToText.initialize(
        onError: (SpeechRecognitionError error) {
          debugPrint('STT error: ${error.errorMsg}');
          _isListening = false;
          _listeningStateController.add(false);
          if (_isWakeWordLoopActive && !_isSpeaking) {
            _scheduleWakeWordRestart(const Duration(milliseconds: 800));
          }
        },
        onStatus: (String status) {
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            _listeningStateController.add(false);
            if (_isWakeWordLoopActive && !_isSpeaking) {
              _scheduleWakeWordRestart(const Duration(milliseconds: 300));
            }
          }
        },
      );
      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Speech init error: $e');
      return false;
    }
  }

  void _scheduleWakeWordRestart(Duration delay) {
    _wakeWordRestartTimer?.cancel();
    _wakeWordRestartTimer = Timer(delay, () {
      if (_isWakeWordLoopActive && !_isListening && !_isSpeaking) {
        _startWakeWordListenSession();
      }
    });
  }

  // Active User Command Listening (Direct recording inside Nova screen)
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
  }) async {
    _wakeWordRestartTimer?.cancel();
    final hasInit = await initSpeech();
    if (!hasInit) return;

    if (_isSpeaking) {
      await stopSpeaking();
    }

    _isWakeWordMode = false;

    try {
      _isListening = true;
      _listeningStateController.add(true);

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _recognizedTextController.add(result.recognizedWords);
          onResult(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: (level) {
          _soundLevelController.add(level);
        },
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('startListening error: $e');
      _isListening = false;
      _listeningStateController.add(false);
    }
  }

  // Start Global Continuous "Hey Nova" Wake Word Daemon
  Future<void> startGlobalWakeWordMonitoring() async {
    _isWakeWordLoopActive = true;
    _startWakeWordListenSession();
  }

  Future<void> stopGlobalWakeWordMonitoring() async {
    _isWakeWordLoopActive = false;
    _wakeWordRestartTimer?.cancel();
    if (_isWakeWordMode && _isListening) {
      await stopListening();
    }
  }

  Future<void> _startWakeWordListenSession() async {
    final hasInit = await initSpeech();
    if (!hasInit || !_isWakeWordLoopActive || _isSpeaking) return;

    if (_isListening) return;

    _isWakeWordMode = true;

    try {
      _isListening = true;
      _listeningStateController.add(true);

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          final words = result.recognizedWords.toLowerCase().trim();
          _recognizedTextController.add(words);

          final wakeWordRegex = RegExp(r'\b(?:hey|hi|hello|ok|yo)?\s*nova\b', caseSensitive: false);
          if (wakeWordRegex.hasMatch(words)) {
            // Wake word detected!
            final match = wakeWordRegex.firstMatch(words)!;
            final remainder = words.substring(match.end).replaceAll(RegExp(r'^[,.\s]+'), '').trim();
            final followUp = remainder.isNotEmpty ? remainder : null;

            _wakeWordTriggerController.add(followUp);
          }
        },
        onSoundLevelChange: (level) {
          _soundLevelController.add(level);
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US',
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('wakeWordSession error: $e');
      _isListening = false;
      _listeningStateController.add(false);
      if (_isWakeWordLoopActive && !_isSpeaking) {
        _scheduleWakeWordRestart(const Duration(milliseconds: 1000));
      }
    }
  }

  Future<void> stopListening() async {
    try {
      _wakeWordRestartTimer?.cancel();
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      _isListening = false;
      _isWakeWordMode = false;
      _listeningStateController.add(false);
    } catch (e) {
      debugPrint('stopListening error: $e');
    }
  }

  Future<void> speak(String text, {bool isMuted = false}) async {
    if (isMuted || text.trim().isEmpty) return;

    try {
      if (!_isTtsInitialized) {
        await _initTts();
      }

      final cleanText = _sanitizeSpokenText(text);
      if (cleanText.isEmpty) return;

      if (_isSpeaking) {
        await _flutterTts.stop();
      }

      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingStateController.add(false);
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  String _sanitizeSpokenText(String raw) {
    var s = raw;
    s = s.replaceAll(RegExp(r'\[.*?\]'), '');
    s = s.replaceAll(RegExp(r'[*_`#|>]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  void dispose() {
    _wakeWordRestartTimer?.cancel();
    _speechToText.cancel();
    _flutterTts.stop();
    _recognizedTextController.close();
    _soundLevelController.close();
    _listeningStateController.close();
    _speakingStateController.close();
    _wakeWordTriggerController.close();
  }
}

final novaVoiceServiceProvider = Provider<NovaVoiceService>((ref) {
  final service = NovaVoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});
