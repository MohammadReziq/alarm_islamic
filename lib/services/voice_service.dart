import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice recognition service with fuzzy Arabic dhikr matching
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  /// Initialize speech recognition
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      // Initialize speech-to-text
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint(
            '❌ SpeechToText Error: ${error.errorMsg} (Permanent: ${error.permanent})',
          );
          _isInitialized = false; // Reset on critical error
        },
        onStatus: (status) => debugPrint('🎤 SpeechToText Status: $status'),
        finalTimeout: const Duration(seconds: 10),
      );

      if (!_isInitialized) {
        debugPrint('❌ SpeechToText failed to initialize');
      } else {
        debugPrint('✅ SpeechToText initialized successfully');
      }
    } catch (e) {
      debugPrint('❌ VoiceService Init Exception: $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start listening for Arabic speech
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      final initialized = await init();
      if (!initialized) {
        throw Exception('Voice service not initialized');
      }
    }

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;

        // Call partial result callback
        if (onPartialResult != null) {
          onPartialResult(text);
        }

        // Check if text is valid even if partial
        if (isValidDhikr(text)) {
          // If valid, stop listening and return result immediately
          _speech.stop();
          onResult(text);
          return;
        }

        // Call final result callback
        if (result.finalResult) {
          onResult(text);
        }
      },
      localeId: 'ar-SA', // Arabic (Saudi Arabia)
      listenMode: ListenMode.dictation, // Optimized for longer phrases
      cancelOnError: false,
      partialResults: true,
      listenFor: const Duration(seconds: 60), // Longer timeout
      pauseFor: const Duration(seconds: 5), // Longer pause allowed
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Check if currently listening
  bool get isListening => _speech.isListening;

  /// Fuzzy keyword matching for dhikr validation
  ///
  /// Validates the spoken text against the required Dua
  ///
  /// Logic: Scoring System 🎯
  /// We check for presence of key roots. Each match gives +1 point.
  /// If Score >= 3, we accept it.
  bool isValidDhikr(String spokenText) {
    if (spokenText.trim().isEmpty) return false;

    final text = spokenText.trim().toLowerCase();
    int score = 0;

    // 1. Root: Hamd (الحمد)
    if (_containsKeyword(text, ['الحمد', 'حمد', 'احمد', 'شكر'])) score++;

    // 2. Root: Allah (لله)
    if (_containsKeyword(text, ['لله', 'الله', 'الاله'])) score++;

    // 3. Root: Hayy (أحيانا) -> Life
    if (_containsKeyword(text, [
      'أحيانا',
      'احيانا',
      'أحياني',
      'احياني',
      'حياة',
      'حيانا',
    ]))
      score++;

    // 4. Root: Mawt (أماتنا) -> Death
    if (_containsKeyword(text, ['أماتنا', 'اماتنا', 'اماتني', 'موت', 'مات']))
      score++;

    // 5. Root: Nushur (النشور) -> Resurrection
    if (_containsKeyword(text, ['النشور', 'نشور', 'ناشور', 'نشر'])) score++;

    // 6. Secondary words (Bonus)
    if (_containsKeyword(text, ['الذي', 'لذي'])) score++;
    if (_containsKeyword(text, ['بعدما', 'بعد'])) score++;
    if (_containsKeyword(text, ['وإليه', 'واليه', 'اليه'])) score++;

    print('Voice Score: $score for input: "$spokenText"');

    // Threshold: 3 significant matches are enough to confirm intent
    // Example: "الحمد لله ... النشور" = 3 points -> Pass
    return score >= 3;
  }

  /// Helper: Check if text contains any of the keywords (fuzzy)
  bool _containsKeyword(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Get validation feedback (for UI display)
  String getValidationFeedback(String spokenText) {
    if (spokenText.trim().isEmpty) {
      return 'قل: الحمد لله الذي أحيانا...';
    }

    final text = spokenText.trim().toLowerCase();

    final hasAlhamd = _containsKeyword(text, ['الحمد', 'حمد']);
    final hasAhyana = _containsKeyword(text, [
      'أحيانا',
      'أحياني',
      'احيانا',
      'احياني',
    ]);
    final hasNushur = _containsKeyword(text, ['النشور', 'نشور']);

    if (!hasAlhamd) {
      return 'ابدأ بـ "الحمد لله..."';
    }
    if (!hasAhyana) {
      return 'أكمل: "...الذي أحيانا..."';
    }
    if (!hasNushur) {
      return 'أكمل: "...وإليه النشور"';
    }

    return '✅ أحسنت!';
  }
}
