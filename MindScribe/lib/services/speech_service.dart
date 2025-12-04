// Speech Service - Handles Voice-to-Text (STT) and Text-to-Speech (TTS)
// This service manages all speech-related operations in the app

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechService {
  // Singleton pattern
  static final SpeechService instance = SpeechService._init();
  
  // Speech-to-Text
  late stt.SpeechToText _speechToText;
  bool _sttInitialized = false;
  bool _isListening = false;
  
  // Text-to-Speech
  late FlutterTts _flutterTts;
  bool _ttsInitialized = false;
  bool _isSpeaking = false;
  
  SpeechService._init();
  
  // ==================== INITIALIZATION ====================
  
  /// Initialize the speech service (both STT and TTS)
  Future<void> initialize() async {
    try {
      print('🎤 Initializing Speech Service...');
      await initializeSTT();
      await initializeTTS();
      print('✅ Speech Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Speech Service: $e');
      rethrow;
    }
  }
  
  /// Initialize Speech-to-Text
  Future<void> initializeSTT() async {
    try {
      print('🎤 Initializing STT...');
      _speechToText = stt.SpeechToText();
      _sttInitialized = await _speechToText.initialize(
        onError: (error) => print('❌ STT Error: $error'),
        onStatus: (status) => print('📊 STT Status: $status'),
      );
      
      if (_sttInitialized) {
        print('✅ STT initialized successfully');
      } else {
        print('⚠️ STT initialization failed');
      }
    } catch (e) {
      print('❌ Error initializing STT: $e');
      _sttInitialized = false;
    }
  }
  
  /// Initialize Text-to-Speech
  Future<void> initializeTTS() async {
    try {
      print('🔊 Initializing TTS...');
      _flutterTts = FlutterTts();
      
      // Configure TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(1.0);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        print('✅ TTS completed');
      });
      
      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        print('❌ TTS Error: $msg');
      });
      
      _ttsInitialized = true;
      print('✅ TTS initialized successfully');
      
      // Load saved preferences
      await loadSavedVoice();
      await loadSavedSpeechSettings();
    } catch (e) {
      print('❌ Error initializing TTS: $e');
      _ttsInitialized = false;
    }
  }
  
  // ==================== PERMISSIONS ====================
  
  /// Check if microphone permission is granted
  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      print('🎤 Microphone permission status: $status');
      return status.isGranted;
    } catch (e) {
      print('❌ Error checking microphone permission: $e');
      return false;
    }
  }
  
  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      print('🎤 Requesting microphone permission...');
      final status = await Permission.microphone.request();
      
      if (status.isGranted) {
        print('✅ Microphone permission granted');
        return true;
      } else if (status.isDenied) {
        print('⚠️ Microphone permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        print('❌ Microphone permission permanently denied');
        // Open app settings
        await openAppSettings();
        return false;
      }
      
      return false;
    } catch (e) {
      print('❌ Error requesting microphone permission: $e');
      return false;
    }
  }
  
  // ==================== SPEECH-TO-TEXT ====================
  
  /// Start listening for speech input
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    String? localeId,
  }) async {
    try {
      // Check if already listening
      if (_isListening) {
        print('⚠️ Already listening');
        return;
      }
      
      // Check if STT is initialized
      if (!_sttInitialized) {
        await initializeSTT();
        if (!_sttInitialized) {
          onError('Speech recognition not available');
          return;
        }
      }
      
      // Check permission
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          onError('Microphone permission denied');
          return;
        }
      }
      
      print('🎤 Starting to listen...');
      _isListening = true;
      
      await _speechToText.listen(
        onResult: (result) {
          print('📝 STT Result: ${result.recognizedWords}');
          onResult(result.recognizedWords);
        },
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
      
      print('✅ Listening started');
    } catch (e) {
      print('❌ Error starting to listen: $e');
      _isListening = false;
      onError('Failed to start listening: $e');
    }
  }
  
  /// Stop listening for speech input
  Future<void> stopListening() async {
    try {
      if (!_isListening) {
        print('⚠️ Not currently listening');
        return;
      }
      
      print('🛑 Stopping listening...');
      await _speechToText.stop();
      _isListening = false;
      print('✅ Listening stopped');
    } catch (e) {
      print('❌ Error stopping listening: $e');
      _isListening = false;
    }
  }
  
  /// Check if currently listening
  bool get isListening => _isListening;
  
  /// Check if STT is available
  bool get isSttAvailable => _sttInitialized;
  
  // ==================== TEXT-TO-SPEECH ====================
  
  /// Speak the given text
  Future<void> speak(String text, {
    double rate = 1.0,
    double pitch = 1.0,
    String? voice,
    bool respectSilentMode = true,
  }) async {
    try {
      // Check if TTS is initialized
      if (!_ttsInitialized) {
        await initializeTTS();
        if (!_ttsInitialized) {
          print('❌ TTS not available');
          return;
        }
      }
      
      // Check volume and silent mode
      if (respectSilentMode) {
        final shouldSpeak = await _checkVolumeAndSilentMode();
        if (!shouldSpeak) {
          print('🔇 Skipping TTS due to volume/silent mode settings');
          return;
        }
      }
      
      // Stop any ongoing speech
      if (_isSpeaking) {
        await stop();
      }
      
      print('🔊 Speaking: "$text"');
      _isSpeaking = true;
      
      // Set parameters
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setPitch(pitch);
      if (voice != null) {
        await _flutterTts.setVoice({'name': voice, 'locale': 'en-US'});
      }
      
      // Speak
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ Error speaking: $e');
      _isSpeaking = false;
    }
  }
  
  /// Check volume and silent mode settings
  Future<bool> _checkVolumeAndSilentMode() async {
    try {
      // Check if user has enabled TTS in silent mode
      final prefs = await SharedPreferences.getInstance();
      final ttsInSilentMode = prefs.getBool('tts_in_silent_mode') ?? true;
      
      // Note: Checking actual device silent mode requires platform-specific code
      // For now, we'll rely on user preference
      // In a full implementation, you would use platform channels to check:
      // - Android: AudioManager.getRingerMode()
      // - iOS: AVAudioSession.sharedInstance().outputVolume
      
      if (ttsInSilentMode) {
        print('✅ TTS allowed (user enabled TTS in silent mode)');
        return true;
      } else {
        print('🔇 TTS disabled by user preference');
        return true; // For now, always allow TTS
      }
    } catch (e) {
      print('⚠️ Error checking volume/silent mode: $e');
      // Default to allowing TTS if check fails
      return true;
    }
  }
  
  /// Set whether TTS should work in silent mode
  Future<void> setTTSInSilentMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tts_in_silent_mode', enabled);
      print('✅ TTS in silent mode set to: $enabled');
    } catch (e) {
      print('❌ Error setting TTS silent mode preference: $e');
    }
  }
  
  /// Get whether TTS should work in silent mode
  Future<bool> getTTSInSilentMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('tts_in_silent_mode') ?? false;
    } catch (e) {
      print('❌ Error getting TTS silent mode preference: $e');
      return false;
    }
  }
  
  /// Stop speaking
  Future<void> stop() async {
    try {
      if (!_isSpeaking) {
        return;
      }
      
      print('🛑 Stopping TTS...');
      await _flutterTts.stop();
      _isSpeaking = false;
      print('✅ TTS stopped');
    } catch (e) {
      print('❌ Error stopping TTS: $e');
      _isSpeaking = false;
    }
  }
  
  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;
  
  /// Check if TTS is available
  bool get isTtsAvailable => _ttsInitialized;
  
  /// Get available voices
  Future<List<dynamic>> getAvailableVoices() async {
    try {
      if (!_ttsInitialized) {
        await initializeTTS();
      }
      
      final voices = await _flutterTts.getVoices;
      print('🎙️ Available voices: ${voices.length}');
      return voices;
    } catch (e) {
      print('❌ Error getting voices: $e');
      return [];
    }
  }
  
  /// Set voice
  Future<void> setVoice(String voice) async {
    try {
      await _flutterTts.setVoice({'name': voice, 'locale': 'en-US'});
      print('✅ Voice set to: $voice');
      
      // Save preference
      await _saveVoicePreference(voice);
    } catch (e) {
      print('❌ Error setting voice: $e');
    }
  }
  
  /// Load saved voice preference
  Future<String?> _loadVoicePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('tts_voice');
    } catch (e) {
      print('❌ Error loading voice preference: $e');
      return null;
    }
  }
  
  /// Save voice preference
  Future<void> _saveVoicePreference(String voice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_voice', voice);
      print('✅ Voice preference saved: $voice');
    } catch (e) {
      print('❌ Error saving voice preference: $e');
    }
  }
  
  /// Load and apply saved voice preference
  Future<void> loadSavedVoice() async {
    try {
      final savedVoice = await _loadVoicePreference();
      if (savedVoice != null) {
        await setVoice(savedVoice);
        print('✅ Loaded saved voice: $savedVoice');
      }
    } catch (e) {
      print('❌ Error loading saved voice: $e');
    }
  }
  
  // ==================== SPEECH RATE AND PITCH ====================
  
  /// Set speech rate (0.0 to 1.0, default 0.5)
  Future<void> setSpeechRate(double rate) async {
    try {
      if (!_ttsInitialized) {
        await initializeTTS();
      }
      
      await _flutterTts.setSpeechRate(rate);
      print('✅ Speech rate set to: $rate');
      
      // Save preference
      await _saveSpeechRatePreference(rate);
    } catch (e) {
      print('❌ Error setting speech rate: $e');
    }
  }
  
  /// Set speech pitch (0.5 to 2.0, default 1.0)
  Future<void> setSpeechPitch(double pitch) async {
    try {
      if (!_ttsInitialized) {
        await initializeTTS();
      }
      
      await _flutterTts.setPitch(pitch);
      print('✅ Speech pitch set to: $pitch');
      
      // Save preference
      await _saveSpeechPitchPreference(pitch);
    } catch (e) {
      print('❌ Error setting speech pitch: $e');
    }
  }
  
  /// Load saved speech rate preference
  Future<double> _loadSpeechRatePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('tts_speech_rate') ?? 0.5;
    } catch (e) {
      print('❌ Error loading speech rate preference: $e');
      return 0.5;
    }
  }
  
  /// Save speech rate preference
  Future<void> _saveSpeechRatePreference(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_speech_rate', rate);
      print('✅ Speech rate preference saved: $rate');
    } catch (e) {
      print('❌ Error saving speech rate preference: $e');
    }
  }
  
  /// Load saved speech pitch preference
  Future<double> _loadSpeechPitchPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('tts_speech_pitch') ?? 1.0;
    } catch (e) {
      print('❌ Error loading speech pitch preference: $e');
      return 1.0;
    }
  }
  
  /// Save speech pitch preference
  Future<void> _saveSpeechPitchPreference(double pitch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_speech_pitch', pitch);
      print('✅ Speech pitch preference saved: $pitch');
    } catch (e) {
      print('❌ Error saving speech pitch preference: $e');
    }
  }
  
  /// Load and apply saved speech rate and pitch
  Future<void> loadSavedSpeechSettings() async {
    try {
      final rate = await _loadSpeechRatePreference();
      final pitch = await _loadSpeechPitchPreference();
      
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setPitch(pitch);
      
      print('✅ Loaded saved speech settings: rate=$rate, pitch=$pitch');
    } catch (e) {
      print('❌ Error loading saved speech settings: $e');
    }
  }
  
  /// Set speech rate
  Future<void> setRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      print('✅ Speech rate set to: $rate');
    } catch (e) {
      print('❌ Error setting rate: $e');
    }
  }
  
  // ==================== CLEANUP ====================
  
  /// Dispose and clean up resources
  Future<void> dispose() async {
    try {
      print('🧹 Disposing Speech Service...');
      
      if (_isListening) {
        await stopListening();
      }
      
      if (_isSpeaking) {
        await stop();
      }
      
      print('✅ Speech Service disposed');
    } catch (e) {
      print('❌ Error disposing Speech Service: $e');
    }
  }
}
