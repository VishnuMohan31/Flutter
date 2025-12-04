# Implementation Plan - Voice-to-Text & TTS Notifications

## Overview

This implementation plan breaks down the voice-to-text and text-to-speech features into manageable, incremental tasks. Each task builds on previous ones, ensuring a solid foundation before adding complexity.

---

## Task List

- [x] 1. Setup and Dependencies

  - Add required packages to pubspec.yaml
  - Configure Android permissions in AndroidManifest.xml
  - Configure iOS permissions in Info.plist
  - Test package installation
  - _Requirements: All_

- [ ] 2. Create SpeechService Foundation
  - [x] 2.1 Create speech_service.dart file with singleton pattern

    - Implement basic structure with STT and TTS sections
    - Add initialization methods
    - Add dispose method
    - _Requirements: 1.1, 2.1_

  - [x] 2.2 Implement STT permission handling

    - Add checkMicrophonePermission method
    - Add requestMicrophonePermission method
    - Handle permission denied scenarios
    - _Requirements: 3.1, 3.2_

  - [ ] 2.3 Write property test for permission handling
    - **Property 9: Permission Denial Handling**
    - **Validates: Requirements 3.2, 8.1**

  - [x] 2.4 Implement STT initialization


    - Initialize speech_to_text package
    - Handle initialization errors
    - Add isAvailable check
    - _Requirements: 1.1, 9.1_

  - [ ]* 2.5 Write property test for STT initialization
    - **Property 1: STT Initialization**
    - **Validates: Requirements 9.1**

- [ ] 3. Implement Voice-to-Text Core Functionality
  - [x] 3.1 Implement startListening method


    - Configure speech recognizer with callbacks
    - Handle onResult callback
    - Handle onError callback
    - Add locale support
    - _Requirements: 1.1, 1.3_

  - [x] 3.2 Implement stopListening method

    - Stop speech recognizer
    - Clean up resources
    - Handle stop errors
    - _Requirements: 1.3_

  - [x] 3.3 Add isListening state management

    - Track recording state
    - Notify listeners of state changes
    - _Requirements: 1.2_

  - [ ]* 3.4 Write property test for STT conversion
    - **Property 3: Speech-to-Text Conversion**
    - **Validates: Requirements 1.3, 1.4, 9.2**

  - [ ]* 3.5 Write property test for STT error handling
    - **Property 4: STT Error Handling**
    - **Validates: Requirements 1.5, 8.2**

- [x] 4. Create VoiceInputWidget UI Component

  - [x] 4.1 Create voice_input_widget.dart file


    - Create StatefulWidget structure
    - Add controller and fieldName parameters
    - Add callback parameters
    - _Requirements: 5.1, 5.2_



  - [ ] 4.2 Implement microphone button UI
    - Add microphone icon button
    - Style button appropriately
    - Add accessibility labels
    - _Requirements: 5.1, 5.2, 10.1_

  - [ ]* 4.3 Write property test for accessibility
    - **Property 14: Accessibility Labels**


    - **Validates: Requirements 10.1**

  - [ ] 4.4 Implement recording dialog UI
    - Create dialog with animated waveform
    - Add real-time transcription display

    - Add stop/cancel buttons
    - Add timer display
    - _Requirements: 5.3, 5.4_

  - [ ] 4.5 Implement state management for recording
    - Handle idle state

    - Handle recording state
    - Handle processing state
    - Handle error state
    - _Requirements: 5.3, 5.5_

  - [ ] 4.6 Connect VoiceInputWidget to SpeechService
    - Call startListening on button tap
    - Display transcription in real-time
    - Insert final text into controller
    - Handle errors gracefully

    - _Requirements: 1.1, 1.4, 1.5_

  - [ ]* 4.7 Write property test for button triggers recording
    - **Property 2: Microphone Button Triggers Recording**
    - **Validates: Requirements 1.1, 1.2**


- [x] 5. Integrate Voice Input into Add/Edit Screen

  - [ ] 5.1 Add VoiceInputWidget to title field
    - Place microphone button next to title field


    - Connect to title controller
    - Test functionality
    - _Requirements: 5.1_


  - [ ] 5.2 Add VoiceInputWidget to content field
    - Place microphone button next to content field
    - Connect to content controller
    - Test functionality
    - _Requirements: 5.2_




  - [x] 5.3 Add visual feedback for recording

    - Show recording indicator
    - Add haptic feedback
    - Show success animation
    - _Requirements: 5.4, 5.5_


  - [ ]* 5.4 Write unit tests for voice input integration
    - Test button visibility
    - Test text insertion
    - Test error handling
    - _Requirements: 1.1, 1.4, 1.5_


- [ ] 6. Checkpoint - Ensure Voice-to-Text Works
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement TTS Core Functionality

  - [ ] 7.1 Implement TTS initialization in SpeechService
    - Initialize flutter_tts package
    - Handle initialization errors
    - Add isAvailable check


    - _Requirements: 2.1_

  - [ ] 7.2 Implement speak method
    - Configure TTS with rate and pitch


    - Handle text input
    - Start speaking
    - Handle completion callback
    - _Requirements: 2.2, 2.3_

  - [ ] 7.3 Implement stop method
    - Stop TTS playback

    - Clean up resources

    - _Requirements: 2.7_

  - [ ] 7.4 Add isSpeaking state management
    - Track speaking state
    - Notify listeners of state changes
    - _Requirements: 2.8_


  - [ ] 7.5 Implement voice selection
    - Get available voices
    - Set selected voice
    - Save voice preference
    - _Requirements: 4.3_

  - [ ] 7.6 Implement rate and pitch control
    - Set speech rate
    - Set speech pitch
    - Save preferences


    - _Requirements: 4.2_


  - [ ]* 7.7 Write property test for TTS sequence
    - **Property 6: TTS Speaks Title Then Content**
    - **Validates: Requirements 2.2, 2.3**



- [ ] 8. Update Database Schema for TTS
  - [ ] 8.1 Create database migration script
    - Add ttsEnabled column to reminders table
    - Add ttsTitle column to reminders table
    - Add ttsBody column to reminders table
    - Increment database version



    - _Requirements: 6.1_

  - [ ] 8.2 Update Reminder model
    - Add ttsEnabled field


    - Add ttsTitle field
    - Add ttsBody field
    - Update toMap method
    - Update fromMap method
    - Update copyWith method
    - _Requirements: 6.1_

  - [ ]* 8.3 Write property test for TTS data persistence
    - **Property 10: TTS Data Persistence**
    - **Validates: Requirements 6.1**

- [x] 9. Extend NotificationService with TTS

  - [ ] 9.1 Add TTS trigger on notification fire
    - Detect when notification fires
    - Check if TTS is enabled in settings
    - Extract title and content from notification
    - Call SpeechService.speak
    - _Requirements: 2.1, 6.2, 6.3_

  - [ ]* 9.2 Write property test for TTS trigger
    - **Property 5: TTS Triggers on Notification**
    - **Validates: Requirements 2.1**

  - [ ]* 9.3 Write property test for settings check
    - **Property 11: TTS Settings Check**
    - **Validates: Requirements 6.2, 6.3**

  - [ ] 9.4 Implement TTS sequence (title then content)
    - Speak title first
    - Wait for title to complete
    - Speak content second
    - _Requirements: 2.2, 2.3_

  - [ ] 9.5 Add volume and silent mode handling
    - Check device volume settings
    - Check if device is in silent mode
    - Skip TTS if in silent mode (unless user overrides)
    - _Requirements: 2.4, 2.5_

  - [ ]* 9.6 Write property test for volume handling
    - **Property 7: TTS Respects Volume Settings**
    - **Validates: Requirements 2.4**

  - [ ]* 9.7 Write property test for silent mode
    - **Property 8: TTS Silent Mode Handling**
    - **Validates: Requirements 2.5**

  - [ ] 9.8 Update scheduleNotification to include TTS data
    - Pass title and content to notification payload
    - Store TTS enabled flag
    - _Requirements: 6.1_

- [ ] 10. Implement Background TTS Service
  - [ ] 10.1 Create TTSForegroundService for Android
    - Create foreground service class
    - Add service to AndroidManifest.xml
    - Implement service lifecycle methods
    - _Requirements: 7.1_

  - [ ] 10.2 Start foreground service when notification fires
    - Detect app is in background
    - Start foreground service
    - Show persistent notification
    - _Requirements: 7.1, 7.2_

  - [ ]* 10.3 Write property test for background service
    - **Property 12: Background TTS Service**
    - **Validates: Requirements 7.1**

  - [ ] 10.4 Implement TTS in foreground service
    - Initialize TTS in service
    - Speak title and content
    - Stop service when complete
    - _Requirements: 7.1, 7.3_

  - [ ] 10.5 Handle service interruptions
    - Handle service killed by system
    - Gracefully stop TTS
    - Clean up resources
    - _Requirements: 7.4_

- [ ] 11. Create Settings UI for Speech Features
  - [ ] 11.1 Create SpeechSettings model
    - Define all settings fields
    - Implement toJson/fromJson
    - Implement save/load methods
    - _Requirements: 3.3, 4.1_

  - [ ] 11.2 Add STT settings section
    - Add enable/disable toggle
    - Add language selection dropdown
    - Save settings to SharedPreferences
    - _Requirements: 3.3, 3.4_

  - [ ] 11.3 Add TTS settings section
    - Add enable/disable toggle
    - Add voice selection dropdown
    - Add speech rate slider
    - Add pitch slider (optional)
    - Add "Test TTS" button
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ] 11.4 Implement settings persistence
    - Load settings on app start
    - Save settings on change
    - Apply settings to SpeechService
    - _Requirements: 3.5, 4.5_

  - [ ]* 11.5 Write unit tests for settings
    - Test save/load
    - Test default values
    - Test validation
    - _Requirements: 3.3, 4.1_

- [ ] 12. Implement Error Handling and Fallbacks
  - [ ] 12.1 Add STT error handling
    - Handle permission denied
    - Handle no speech detected
    - Handle network errors
    - Handle timeout
    - Show user-friendly error messages
    - _Requirements: 8.1, 8.2_

  - [ ] 12.2 Add TTS error handling
    - Handle TTS engine not available
    - Handle initialization failed
    - Handle playback failed
    - Fall back to standard notifications
    - _Requirements: 8.3_

  - [ ]* 12.3 Write property test for TTS fallback
    - **Property 13: TTS Fallback**
    - **Validates: Requirements 8.3**

  - [ ] 12.4 Add logging for debugging
    - Log all errors
    - Log initialization status
    - Log TTS triggers
    - _Requirements: 8.6_

- [ ] 13. Performance Optimization
  - [ ] 13.1 Implement lazy initialization
    - Only initialize STT when first used
    - Only initialize TTS when first used
    - Cache initialized instances
    - _Requirements: 9.1, 9.3_

  - [ ] 13.2 Implement resource cleanup
    - Release audio resources after use
    - Dispose services properly
    - Clear caches when not needed
    - _Requirements: 9.4_

  - [ ] 13.3 Add TTS duration limits
    - Limit TTS to 30 seconds max
    - Truncate long content if needed
    - _Requirements: 9.4_

  - [ ] 13.4 Implement TTS queue management
    - Queue multiple TTS requests
    - Process sequentially
    - Avoid overlapping audio
    - _Requirements: 2.6_

  - [ ]* 13.5 Test performance metrics
    - Measure STT initialization time
    - Measure TTS initialization time
    - Measure battery impact
    - _Requirements: 9.1, 9.2, 9.3, 9.5_

- [ ] 14. Add Visual Polish and Animations
  - [ ] 14.1 Add recording animations
    - Animated waveform during recording
    - Pulsing microphone icon
    - Smooth transitions
    - _Requirements: 5.3_

  - [ ] 14.2 Add success/error animations
    - Success checkmark animation
    - Error shake animation
    - Smooth fade in/out
    - _Requirements: 5.5_

  - [ ] 14.3 Add TTS visual indicators
    - Show "Speaking..." in notification
    - Add speaking icon
    - Update when TTS completes
    - _Requirements: 2.8, 6.4_

- [ ] 15. Final Testing and Bug Fixes
  - [ ] 15.1 Test on multiple Android versions
    - Test on Android 8.0
    - Test on Android 10
    - Test on Android 12+
    - _Requirements: All_

  - [ ] 15.2 Test with different TTS engines
    - Test with Google TTS
    - Test with Samsung TTS
    - Test with device default
    - _Requirements: 2.1, 4.3_

  - [ ] 15.3 Test background scenarios
    - Test with app closed
    - Test with screen locked
    - Test with Do Not Disturb enabled
    - _Requirements: 7.1, 2.5_

  - [ ] 15.4 Test accessibility features
    - Test with TalkBack enabled
    - Test with large text
    - Test with high contrast
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ] 15.5 Fix any bugs found during testing
    - Document bugs
    - Prioritize fixes
    - Implement fixes
    - Retest
    - _Requirements: All_

- [ ] 16. Final Checkpoint - Ensure All Features Work
  - Ensure all tests pass, ask the user if questions arise.

---

## Implementation Notes

### Task Dependencies

- Tasks 1-6 must be completed before starting tasks 7-16
- Task 8 (database migration) must be completed before task 9
- Task 10 (background service) depends on task 9
- Task 11 (settings) can be done in parallel with tasks 7-10
- Tasks 12-14 are polish and can be done after core functionality

### Testing Strategy

- Write property tests for core correctness properties
- Write unit tests for individual components
- Perform integration testing after each major milestone
- Perform manual testing on real devices
- Get user feedback before final release

### Time Estimates

- **Week 1**: Tasks 1-6 (Voice-to-Text)
- **Week 2**: Tasks 7-11 (Text-to-Speech + Settings)
- **Week 3**: Tasks 12-16 (Polish, Testing, Bug Fixes)

### Success Criteria

- ✅ Voice input works on title and content fields
- ✅ Speech-to-text conversion is accurate (>90%)
- ✅ TTS speaks title and content when notification fires
- ✅ TTS works in background (app closed)
- ✅ Settings allow full customization
- ✅ Error handling is graceful
- ✅ Performance meets targets
- ✅ All tests pass
- ✅ No critical bugs

---

**Document Version:** 1.0  
**Created:** December 3, 2025  
**Status:** Ready for Implementation
