import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

final voiceMutedProvider = StateProvider<bool>((ref) => false);

class NovaVoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  final _recognizedTextController = StreamController<String>.broadcast();
  final _soundLevelController = StreamController<double>.broadcast();
  final _listeningStateController = StreamController<bool>.broadcast();
  final _speakingStateController = StreamController<bool>.broadcast();

  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  Stream<bool> get listeningStateStream => _listeningStateController.stream;
  Stream<bool> get speakingStateStream => _speakingStateController.stream;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSpeechAvailable => _isSpeechInitialized;

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
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _speakingStateController.add(false);
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
        },
        onStatus: (String status) {
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            _listeningStateController.add(false);
          }
        },
      );
      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Speech init error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
  }) async {
    final hasInit = await initSpeech();
    if (!hasInit) return;

    if (_isSpeaking) {
      await stopSpeaking();
    }

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

  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      _isListening = false;
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

      // Clean markdown, JSON brackets, and badge indicators from spoken text
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
    // Remove bracket notes like [Offline Tactical Core Engaged] or [Note: ...]
    s = s.replaceAll(RegExp(r'\[.*?\]'), '');
    // Remove markdown symbols (asterisks, backticks, hashes, bullet points)
    s = s.replaceAll(RegExp(r'[*_`#|>]'), '');
    // Replace multiple spaces/newlines
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _recognizedTextController.close();
    _soundLevelController.close();
    _listeningStateController.close();
    _speakingStateController.close();
  }
}

final novaVoiceServiceProvider = Provider<NovaVoiceService>((ref) {
  final service = NovaVoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});
