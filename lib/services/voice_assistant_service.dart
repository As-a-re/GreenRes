import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../localization/localization_service.dart';
import 'backend_api.dart';

/// Wraps TTS (speaking) and STT (listening) behind a single service so the
/// rest of the app doesn't need to know which packages/providers are
/// involved.
///
/// SPEECH QUALITY BY LANGUAGE:
/// - English uses the device's own TTS engine (flutter_tts) — reliable,
///   works offline, sounds like a normal phone voice.
/// - Twi routes through the backend's `/voice/twi-tts` proxy to GhanaNLP's
///   Khaya AI, a Twi-specific model built by Ghanaian NLP researchers —
///   the only credible path to native-sounding Twi speech, since no major
///   TTS provider (Google, Amazon, Azure, ElevenLabs) supports Twi/Akan.
///   This requires the backend operator to configure `KHAYA_API_KEY` (see
///   backend/.env.example). If it's not configured, or the network call
///   fails, this falls back to the device's TTS engine reading the Twi
///   text — which will likely be mispronounced, since most phones don't
///   have a Twi voice installed. That fallback is clearly a downgrade,
///   not a claim of equivalent quality.
class VoiceAssistantService {
  VoiceAssistantService._();
  static final VoiceAssistantService instance = VoiceAssistantService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _ttsReady = false;
  bool _sttReady = false;
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> init() async {
    if (!_ttsReady) {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    }
    if (!_sttReady) {
      try {
        _sttReady = await _stt.initialize(
          onError: (_) => _isListening = false,
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
            }
          },
        );
      } catch (_) {
        _sttReady = false;
      }
    }
  }

  Future<void> speak(String text) async {
    if (!_ttsReady) await init();
    final locale = LocalizationService.instance.locale;

    if (locale == AppLocale.twi) {
      final playedRealTwi = await _speakTwiViaKhayaAi(text);
      if (playedRealTwi) return;
      // Fall through to device TTS below as a best-effort downgrade.
    }

    await _tts.setLanguage(locale == AppLocale.twi ? 'ak-GH' : 'en-US');
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Attempts real Twi speech via the backend's Khaya AI proxy. Returns
  /// true if audio was fetched and playback started, false if the caller
  /// should fall back to device TTS.
  Future<bool> _speakTwiViaKhayaAi(String text) async {
    try {
      final bytes = await BackendApi.postForBytes('/voice/twi-tts', body: {'text': text});
      if (bytes == null || bytes.isEmpty) return false;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/twi_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(bytes, flush: true);

      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(file.path);
      unawaited(_audioPlayer.play());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    await _audioPlayer.stop();
  }

  /// Listens for a single spoken command and calls [onResult] with the
  /// recognized text (lowercased, trimmed), or with null if speech
  /// recognition isn't available on this device.
  Future<void> listenOnce(void Function(String? recognizedText) onResult) async {
    if (!_sttReady) await init();
    if (!_sttReady) {
      onResult(null);
      return;
    }

    _isListening = true;
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onResult(result.recognizedWords.trim().toLowerCase());
        }
      },
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }

  bool get speechAvailable => _sttReady;
}
