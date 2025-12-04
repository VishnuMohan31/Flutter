# Design Document - Voice-to-Text & TTS Notifications

## Overview

This document describes the technical design for implementing voice-to-text input and text-to-speech notifications in MindScribe. The system will allow users to create entries by speaking and will read notification content aloud when reminders fire.

### Key Design Goals

1. **Modularity**: Separate concerns (STT, TTS, UI, Notifications)
2. **Reliability**: Graceful error handling and fallbacks
3. **Performance**: Fast initialization and low battery impact
4. **Accessibility**: Works with device accessibility features
5. **Maintainability**: Clean architecture, easy to test

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Add/Edit     │  │ Settings     │  │ Notification │     │
│  │ Screen       │  │ Screen       │  │ UI           │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼─────────────┐
│         │    Service Layer │                  │             │
│  ┌──────▼───────┐  ┌───────▼──────┐  ┌───────▼──────┐     │
│  │ Speech       │  │ Settings     │  │ Notification │     │
│  │ Service      │  │ Service      │  │ Service      │     │
│  │ (STT + TTS)  │  │              │  │              │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼─────────────┐
│         │    Platform Layer│                  │             │
│  ┌──────▼───────┐  ┌───────▼──────┐  ┌───────▼──────┐     │
│  │ Android STT  │  │ Shared       │  │ Android      │     │
│  │ Android TTS  │  │ Preferences  │  │ Notifications│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**UI Layer:**
- Displays voice input buttons
- Shows recording state
- Displays transcribed text
- Handles user interactions

**Service Layer:**
- `SpeechService`: Manages STT and TTS operations
- `SettingsService`: Manages user preferences
- `NotificationService`: Schedules and fires notifications with TTS

**Platform Layer:**
- Native Android/iOS speech recognition
- Native Android/iOS text-to-speech
- System notifications
- Shared preferences storage

---

## Components and Interfaces

### 1. SpeechService

**Purpose**: Centralized service for all speech operations (STT and TTS)

**Interface:**
```dart
class SpeechService {
  // Singleton instance
  static final SpeechService instance = SpeechService._init();
  
  // STT Methods
  Future<void> initialize();
  Future<bool> checkMicrophonePermission();
  Future<bool> requestMicrophonePermission();
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    String? localeId,
  });
  Future<void> stopListening();
  bool get isListening;
  
  // TTS Methods
  Future<void> initializeTTS();
  Future<void> speak(String text, {
    double rate = 1.0,
    double pitch = 1.0,
    String? voice,
  });
  Future<void> stop();
  bool get isSpeaking;
  Future<List<String>> getAvailableVoices();
  Future<void> setVoice(String voice);
  Future<void> setRate(double rate);
  
  // Cleanup
  Future<void> dispose();
}
```

**Dependencies:**
- `speech_to_text` package for STT
- `flutter_tts` package for TTS
- `permission_handler` for microphone permissions

---

### 2. VoiceInputWidget

**Purpose**: Reusable widget for voice input UI

**Interface:**
```dart
class VoiceInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String fieldName; // 'title' or 'content'
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  
  const VoiceInputWidget({
    required this.controller,
    required this.fieldName,
    this.onStart,
    this.onComplete,
  });
}
```

**UI States:**
- Idle: Shows microphone icon
- Recording: Shows animated waveform + stop button
- Processing: Shows loading indicator
- Error: Shows error message + retry button

---

### 3. TTSNotificationService

**Purpose**: Extends NotificationService to add TTS capabilities

**Interface:**
```dart
class TTSNotificationService {
  // Schedule notification with TTS data
  Future<void> scheduleNotificationWithTTS({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String? sound,
    bool enableTTS = true,
  });
  
  // Handle notification when it fires
  Future<void> onNotificationFired({
    required String title,
    required String body,
    required bool ttsEnabled,
  });
  
  // Background service for TTS
  Future<void> startTTSForegroundService();
  Future<void> stopTTSForegroundService();
}
```

---

### 4. SpeechSettingsModel

**Purpose**: Data model for speech settings

**Interface:**
```dart
class SpeechSettings {
  final bool sttEnabled;
  final bool ttsEnabled;
  final String sttLanguage;
  final String ttsVoice;
  final double ttsRate; // 0.5 to 2.0
  final double ttsPitch; // 0.5 to 2.0
  final bool ttsInSilentMode;
  
  SpeechSettings({
    this.sttEnabled = true,
    this.ttsEnabled = true,
    this.sttLanguage = 'en-US',
    this.ttsVoice = 'default',
    this.ttsRate = 1.0,
    this.ttsPitch = 1.0,
    this.ttsInSilentMode = false,
  });
  
  // Serialization
  Map<String, dynamic> toJson();
  factory SpeechSettings.fromJson(Map<String, dynamic> json);
  
  // Save/Load
  Future<void> save();
  static Future<SpeechSettings> load();
}
```

---

## Data Models

### Enhanced Reminder Model

```dart
class Reminder {
  final int? id;
  final String entryId;
  final DateTime reminderTime;
  final bool isRecurring;
  final String? recurrenceRule;
  final bool isActive;
  final String? soundName;
  
  // NEW: TTS fields
  final bool ttsEnabled;
  final String? ttsTitle;  // Store title for TTS
  final String? ttsBody;   // Store content for TTS
  
  Reminder({
    this.id,
    required this.entryId,
    required this.reminderTime,
    this.isRecurring = false,
    this.recurrenceRule,
    this.isActive = true,
    this.soundName,
    this.ttsEnabled = true,
    this.ttsTitle,
    this.ttsBody,
  });
}
```

### Database Schema Update

```sql
ALTER TABLE reminders ADD COLUMN ttsEnabled INTEGER DEFAULT 1;
ALTER TABLE reminders ADD COLUMN ttsTitle TEXT;
ALTER TABLE reminders ADD COLUMN ttsBody TEXT;
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: STT Initialization
*For any* device with microphone capability, when the speech service is initialized, it should successfully start the speech recognizer within 1 second.
**Validates: Requirements 9.1**

### Property 2: Microphone Button Triggers Recording
*For any* microphone button tap, the speech service should start recording and display a visual indicator.
**Validates: Requirements 1.1, 1.2**

### Property 3: Speech-to-Text Conversion
*For any* recorded audio input, when the user stops speaking, the system should convert the audio to text and insert it into the correct field within 2 seconds.
**Validates: Requirements 1.3, 1.4, 9.2**

### Property 4: STT Error Handling
*For any* speech recognition failure, the system should display an error message and provide a retry option without crashing.
**Validates: Requirements 1.5, 8.2**

### Property 5: TTS Triggers on Notification
*For any* reminder notification that fires with TTS enabled, the notification service should trigger the TTS service.
**Validates: Requirements 2.1**

### Property 6: TTS Speaks Title Then Content
*For any* TTS-enabled notification, the system should speak the title first, then the content, in that order.
**Validates: Requirements 2.2, 2.3**

### Property 7: TTS Respects Volume Settings
*For any* TTS playback, the system should use the device's current volume level.
**Validates: Requirements 2.4**

### Property 8: TTS Silent Mode Handling
*For any* notification when device is in silent mode, the system should display the notification but not play TTS audio.
**Validates: Requirements 2.5**

### Property 9: Permission Denial Handling
*For any* microphone permission denial, the system should hide voice input buttons and show a helpful message.
**Validates: Requirements 3.2, 8.1**

### Property 10: TTS Data Persistence
*For any* notification scheduled with TTS enabled, the system should store the title and content in the notification data.
**Validates: Requirements 6.1**

### Property 11: TTS Settings Check
*For any* notification that fires, the system should check TTS settings before attempting to speak.
**Validates: Requirements 6.2, 6.3**

### Property 12: Background TTS Service
*For any* notification that fires while the app is closed, the system should start a foreground service to handle TTS.
**Validates: Requirements 7.1**

### Property 13: TTS Fallback
*For any* TTS initialization failure, the system should fall back to standard notifications without crashing.
**Validates: Requirements 8.3**

### Property 14: Accessibility Labels
*For any* voice input button, when accessibility services are enabled, the button should have a proper accessibility label.
**Validates: Requirements 10.1**

---

## Error Handling

### STT Error Scenarios

| Error | Cause | Handling |
|-------|-------|----------|
| Permission Denied | User denied microphone access | Show message with steps to enable, hide voice buttons |
| No Speech Detected | User didn't speak | Show "No speech detected, please try again" |
| Network Error | Speech recognition requires network | Show "Network required for speech recognition" |
| Timeout | User spoke too long | Show "Speech too long, please speak in shorter segments" |
| Initialization Failed | Speech recognizer unavailable | Disable voice input, show error message |

### TTS Error Scenarios

| Error | Cause | Handling |
|-------|-------|----------|
| TTS Engine Not Available | No TTS engine installed | Fall back to standard notification, prompt to install TTS |
| Initialization Failed | TTS service unavailable | Fall back to standard notification |
| Playback Failed | Audio system busy | Retry once, then fall back to standard notification |
| Service Killed | System killed foreground service | Gracefully stop TTS, show notification |

---

## Testing Strategy

### Unit Tests

**SpeechService Tests:**
- Test STT initialization
- Test TTS initialization
- Test permission checking
- Test error handling
- Test cleanup/disposal

**VoiceInputWidget Tests:**
- Test button tap triggers recording
- Test visual state changes
- Test text insertion
- Test error display

**TTSNotificationService Tests:**
- Test notification scheduling with TTS data
- Test TTS trigger on notification fire
- Test settings check
- Test fallback behavior

### Property-Based Tests

**Property Test 1: STT Round Trip**
*For any* valid text input, if we speak it and convert to text, the result should match the original (within reasonable accuracy).
**Validates: Property 3**

**Property Test 2: TTS Sequence**
*For any* notification with title and content, TTS should always speak title before content.
**Validates: Property 6**

**Property Test 3: Permission State Consistency**
*For any* permission state (granted/denied), the UI should consistently show/hide voice buttons.
**Validates: Property 9**

**Property Test 4: TTS Data Persistence**
*For any* notification scheduled with TTS, retrieving it should return the same title and content.
**Validates: Property 10**

### Integration Tests

- Test end-to-end voice input flow
- Test end-to-end TTS notification flow
- Test background TTS service
- Test settings persistence
- Test error recovery

### Manual Testing

- Test on multiple devices (different Android versions)
- Test with different TTS engines (Google, Samsung, etc.)
- Test in various scenarios (locked screen, app closed, etc.)
- Test with accessibility features enabled
- Test battery impact over 24 hours

---

## Performance Considerations

### STT Performance

- **Initialization**: < 1 second
- **Start Recording**: < 500ms
- **Conversion**: < 2 seconds after speech stops
- **Memory**: < 50MB during recording

### TTS Performance

- **Initialization**: < 1 second
- **Start Speaking**: < 1 second after notification fires
- **Memory**: < 30MB during playback
- **Battery**: < 5% increase over 24 hours with 10 notifications

### Optimization Strategies

1. **Lazy Initialization**: Only initialize STT/TTS when needed
2. **Resource Cleanup**: Release audio resources immediately after use
3. **Caching**: Cache TTS engine initialization
4. **Background Limits**: Limit TTS duration to 30 seconds max
5. **Queue Management**: Queue multiple TTS requests instead of overlapping

---

## Security and Privacy

### Data Handling

- **No Audio Storage**: Audio is never saved to disk
- **No Network Transmission**: All processing happens on-device (when possible)
- **Permission Transparency**: Clear explanation of why microphone is needed
- **User Control**: Easy to disable voice features completely

### Privacy Considerations

- Respect Do Not Disturb settings
- Respect silent mode
- Don't speak sensitive content in public (user configurable)
- Clear indication when microphone is active

---

## Dependencies

### Required Packages

```yaml
dependencies:
  # Speech Recognition
  speech_to_text: ^6.6.0
  
  # Text-to-Speech
  flutter_tts: ^4.0.2
  
  # Permissions
  permission_handler: ^11.2.0
  
  # Existing
  flutter_local_notifications: ^17.2.4
  sqflite: ^2.4.1
  shared_preferences: ^2.2.2
```

### Platform Requirements

**Android:**
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Permissions: RECORD_AUDIO, FOREGROUND_SERVICE

**iOS:**
- Minimum: iOS 12.0
- Permissions: Microphone, Speech Recognition

---

## Implementation Notes

### Phase 1: Voice-to-Text (Week 1)

1. Add `speech_to_text` package
2. Create `SpeechService` class
3. Add microphone buttons to add/edit screen
4. Implement `VoiceInputWidget`
5. Add permission handling
6. Add settings for STT
7. Test on multiple devices

### Phase 2: Text-to-Speech Notifications (Week 2)

1. Add `flutter_tts` package
2. Extend `NotificationService` with TTS
3. Update `Reminder` model with TTS fields
4. Migrate database schema
5. Implement background TTS service
6. Add TTS settings
7. Test notification TTS flow

### Phase 3: Polish & Testing (Week 3)

1. Add animations and visual feedback
2. Improve error messages
3. Add accessibility labels
4. Performance optimization
5. Battery testing
6. User acceptance testing
7. Bug fixes

---

## Future Enhancements

- Offline speech recognition
- Custom wake words
- Voice commands for navigation
- Emotion detection from voice
- Multi-language support
- Voice biometrics

---

**Document Version:** 1.0  
**Created:** December 3, 2025  
**Status:** Ready for Implementation
