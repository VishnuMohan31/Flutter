// Notification Service - Handles all notifications and reminders
// This manages scheduling, showing, and canceling notifications

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry_model.dart';
import '../models/reminder_model.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  // Initialize notification service
  Future<void> initialize() async {
    try {
      print('🔔 Initializing notification service...');

      // Step 1: Initialize timezone database FIRST (before any notification operations)
      print('🌍 Step 1: Initializing timezone database...');
      try {
        tz.initializeTimeZones();
        print('✅ Timezone database initialized');
      } catch (e) {
        print('❌ Failed to initialize timezone database: $e');
      }

      // Step 2: Set timezone to IST (India Standard Time)
      print('🕐 Step 2: Setting timezone to IST...');
      try {
        // Try IST timezones in order of preference
        final location = tz.getLocation('Asia/Kolkata');
        tz.setLocalLocation(location);
        print('✅ Timezone set to IST (Asia/Kolkata)');
      } catch (e) {
        print('⚠️ Could not set IST timezone: $e');
        print('   Using system default timezone');
      }

      // Step 3: Clear any corrupted notification data (fixes "Missing type parameter" error)
      print('🧹 Step 3: Clearing any corrupted notification data...');
      await _clearCorruptedNotificationData();
      print('✅ Step 3 complete');

      // Step 4: Initialize notification plugin
      print('📱 Step 4: Initializing notification plugin...');
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('✅ Notification plugin initialized: $initialized');

      // Step 5: Create notification channel for Android
      print('📢 Step 5: Creating notification channel...');
      await _createNotificationChannel();
      print('✅ Notification channel created');

      // Step 6: Request permissions
      print('🔐 Step 6: Requesting permissions...');
      final permissionsGranted = await _requestPermissions();
      print('✅ Permissions granted: $permissionsGranted');

      print('✅ Notification service ready!');
    } catch (e, stackTrace) {
      print('❌ Error initializing notifications: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Force clear SharedPreferences data (most aggressive method)
  Future<void> _forceClearSharedPreferencesData() async {
    try {
      print('🧹 Force clearing ALL notification-related SharedPreferences data...');
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();
      
      // Get all keys that might be related to notifications
      final keysToRemove = allKeys.where((key) => 
        key.startsWith('flutter_local_notifications') ||
        key.startsWith('dexterous.com.flutterlocalnotifications') ||
        key.contains('flutterlocalnotifications') ||
        key.contains('scheduled_notification') ||
        key.contains('pending_notification') ||
        key.contains('notification') ||
        key.toLowerCase().contains('notif')
      ).toList();
      
      print('🔍 Found ${keysToRemove.length} potential notification keys');
      
      // Remove all keys
      for (var key in keysToRemove) {
        try {
          final removed = await prefs.remove(key);
          if (removed) {
            print('   ✓ Removed: $key');
          }
        } catch (e) {
          print('   ✗ Failed to remove $key: $e');
        }
      }
      
      // Force commit
      await prefs.reload();
      
      // Additional delay to ensure Android processes the changes
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('✅ SharedPreferences cleared');
    } catch (e) {
      print('⚠️ Error force clearing SharedPreferences: $e');
    }
  }

  // Clear corrupted notification data to fix "Missing type parameter" error
  Future<void> _clearCorruptedNotificationData() async {
    try {
      print('🧹 Clearing potentially corrupted notification data...');
      
      // Step 1: Clear ALL SharedPreferences data related to notifications FIRST
      // This must happen BEFORE any plugin operations to prevent reflection errors
      try {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        
        // The plugin stores data with various key patterns
        final keysToRemove = allKeys.where((key) => 
          key.startsWith('flutter_local_notifications') ||
          key.startsWith('dexterous.com.flutterlocalnotifications') ||
          key.startsWith('com.dexterous.flutterlocalnotifications') ||
          key.contains('flutterlocalnotifications') ||
          key.contains('scheduled_notification') ||
          key.contains('pending_notification') ||
          key.contains('notification_')
        ).toList();
        
        print('🔍 Found ${keysToRemove.length} notification-related keys to remove');
        
        for (var key in keysToRemove) {
          try {
            await prefs.remove(key);
            print('   ✓ Removed key: $key');
          } catch (e) {
            print('   ✗ Failed to remove key $key: $e');
          }
        }
        
        if (keysToRemove.isNotEmpty) {
          print('✅ Cleared ${keysToRemove.length} notification-related keys from SharedPreferences');
        } else {
          print('ℹ️ No notification keys found in SharedPreferences');
        }
        
        // Force commit the changes
        await prefs.reload();
        
      } catch (prefsError) {
        print('⚠️ Could not clear SharedPreferences: $prefsError');
      }
      
      // Step 2: Wait for SharedPreferences to fully commit
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 3: Try to cancel all notifications through the plugin
      // This should now work without reflection errors
      try {
        await _notifications.cancelAll();
        print('✅ All existing notifications cancelled via plugin');
      } catch (e) {
        print('⚠️ Error cancelling notifications via plugin: $e');
        // Don't fail - continue with initialization
      }
      
      print('✅ Notification data clearing completed');
    } catch (e) {
      print('⚠️ Error clearing notification data: $e');
      // Continue anyway - initialization will handle it
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'mindscribe_reminders',
        'Reminders',
        description: 'Notifications for diary entries and events',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('✅ Notification channel created');
      }
    } catch (e) {
      print('❌ Error creating notification channel: $e');
    }
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      // Android 13+ requires runtime permission
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        print('📱 Android notification permission: $granted');
        return granted ?? false;
      }

      // iOS permissions
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('📱 iOS notification permission: $granted');
        return granted ?? false;
      }

      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to entry details
    // Notification tapped: ${response.payload}
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String? sound,
  }) async {
    try {
      print('🔔 Attempting to schedule notification...');
      print('   ID: $id');
      print('   Title: $title');
      print('   Scheduled Time: $scheduledTime');
      print('   Current Time: ${DateTime.now()}');

      // Ensure ID is positive (required for notifications)
      final notificationId = id > 0 ? id : id.abs() + 1;
      if (notificationId != id) {
        print('⚠️ Adjusted notification ID from $id to $notificationId (must be positive)');
      }

      // Check if scheduled time is in the future
      if (scheduledTime.isBefore(DateTime.now())) {
        print('❌ Cannot schedule notification in the past');
        print('   Scheduled: $scheduledTime');
        print('   Current: ${DateTime.now()}');
        return;
      }

      // Convert to timezone aware datetime
      tz.TZDateTime tzScheduledTime;
      try {
        // Try to use tz.local first
        tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
        print('   TZ Scheduled Time (tz.local): $tzScheduledTime');
      } catch (e) {
        print('⚠️ tz.local failed: $e');
        // Try to get a specific timezone
        try {
          final location = tz.getLocation('Asia/Kolkata');
          tzScheduledTime = tz.TZDateTime(
            location,
            scheduledTime.year,
            scheduledTime.month,
            scheduledTime.day,
            scheduledTime.hour,
            scheduledTime.minute,
            scheduledTime.second,
          );
          print('   TZ Scheduled Time (Asia/Kolkata): $tzScheduledTime');
        } catch (e2) {
          print('⚠️ Asia/Kolkata failed: $e2');
          // Last resort: use UTC
          final location = tz.UTC;
          tzScheduledTime = tz.TZDateTime(
            location,
            scheduledTime.year,
            scheduledTime.month,
            scheduledTime.day,
            scheduledTime.hour,
            scheduledTime.minute,
            scheduledTime.second,
          );
          print('   TZ Scheduled Time (UTC): $tzScheduledTime');
        }
      }

      // Android notification details with custom sound support
      AndroidNotificationDetails androidDetails;
      if (sound != null && sound != 'default' && sound.isNotEmpty) {
        print('   🔊 Using custom sound: $sound');
        androidDetails = AndroidNotificationDetails(
          'mindscribe_reminders',
          'Reminders',
          channelDescription: 'Notifications for diary entries and events',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(sound),
        );
      } else {
        print('   🔊 Using default sound');
        androidDetails = const AndroidNotificationDetails(
          'mindscribe_reminders',
          'Reminders',
          channelDescription: 'Notifications for diary entries and events',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );
      }

      // iOS notification details with custom sound support
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: sound != null && sound != 'default' && sound.isNotEmpty ? '$sound.aiff' : null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        // Ensure payload is a simple string (not null, not complex object)
        // Empty strings can cause issues, so use null instead
        // Also ensure payload is not too long (max 1024 chars for Android)
        String? safePayload;
        if (payload != null && payload.isNotEmpty) {
          safePayload = payload.length > 1024 ? payload.substring(0, 1024) : payload;
        }
        
        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: safePayload,
          matchDateTimeComponents: null,
        );

        print('✅ Notification scheduled successfully!');
        print('   ID: $notificationId');
        print('   Title: $title');
        print('   Scheduled for: $scheduledTime');
        print('   TZ Scheduled for: $tzScheduledTime');

        // Verify it was scheduled
        try {
          final pending = await _notifications.pendingNotificationRequests();
          print('📋 Total pending notifications: ${pending.length}');
          for (var p in pending) {
            print('   - ID: ${p.id}, Title: ${p.title}');
          }
        } catch (e) {
          print('⚠️ Could not verify pending notifications: $e');
          // Don't fail if verification fails
        }
      } catch (scheduleError) {
        print('❌ Error in zonedSchedule: $scheduleError');
        
        // Check if it's the "Missing type parameter" error
        final errorString = scheduleError.toString().toLowerCase();
        if (errorString.contains('missing type parameter') || 
            errorString.contains('type parameter') ||
            errorString.contains('runtimeexception') ||
            errorString.contains('platformexception')) {
          print('⚠️ Detected corrupted notification data error');
          print('💡 Attempting automatic recovery...');
          
          // Try to recover by clearing corrupted data
          try {
            await _clearCorruptedNotificationData();
            print('✅ Corrupted data cleared');
            print('💡 Please try scheduling the notification again');
          } catch (recoveryError) {
            print('❌ Recovery failed: $recoveryError');
          }
        }
        
        rethrow;
      }
    } catch (e, stackTrace) {
      print('❌ Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-throw so the UI can catch it
    }
  }

  // Schedule notification for entry
  Future<void> scheduleEntryNotification(
    EntryModel entry,
    Reminder reminder,
  ) async {
    // Ensure reminder has an ID
    if (reminder.id == null) {
      print('❌ Cannot schedule notification: Reminder has no ID');
      return;
    }

    // Check if reminder time is in the future
    if (reminder.reminderTime.isBefore(DateTime.now())) {
      print('⚠️ Skipping past reminder: ${reminder.reminderTime}');
      return;
    }

    await scheduleNotification(
      id: reminder.id!,
      title: '📝 ${entry.title}',
      body: entry.content.isEmpty
          ? 'Reminder for your entry'
          : (entry.content.length > 100
              ? '${entry.content.substring(0, 100)}...'
              : entry.content),
      scheduledTime: reminder.reminderTime,
      payload: entry.id,
      sound: reminder.soundName,
    );
  }

  // Schedule multiple reminders for entry
  Future<void> scheduleMultipleReminders(
    EntryModel entry,
    List<Reminder> reminders,
  ) async {
    if (reminders.isEmpty) {
      print('ℹ️ No reminders to schedule');
      return;
    }
    
    print('📅 Scheduling ${reminders.length} reminder(s) for entry: ${entry.title}');
    
    for (var i = 0; i < reminders.length; i++) {
      final reminder = reminders[i];
      print('\n📌 Processing reminder ${i + 1}/${reminders.length}:');
      print('   ID: ${reminder.id}');
      print('   Time: ${reminder.reminderTime}');
      print('   Recurring: ${reminder.isRecurring}');
      print('   Rule: ${reminder.recurrenceRule}');
      print('   Sound: ${reminder.soundName ?? "default"}');
      print('   Active: ${reminder.isActive}');
      
      if (!reminder.isActive) {
        print('   ⏭️ Skipping inactive reminder');
        continue;
      }
      
      try {
        // For recurring reminders, schedule next 30 occurrences
        if (reminder.isRecurring && reminder.recurrenceRule != null && reminder.recurrenceRule != 'none') {
          print('   🔄 This is a RECURRING reminder');
          await _scheduleRecurringReminder(entry, reminder);
        } else {
          // For one-time reminders, schedule only if in future
          print('   📍 This is a ONE-TIME reminder');
          if (reminder.reminderTime.isAfter(DateTime.now())) {
            await scheduleEntryNotification(entry, reminder);
            print('   ✅ One-time reminder scheduled');
          } else {
            print('   ⏭️ Skipping past reminder time');
          }
        }
      } catch (e) {
        print('   ❌ Failed to schedule reminder ${reminder.id}: $e');
        // Continue with other reminders even if one fails
      }
    }
    
    print('\n✅ Finished scheduling all reminders\n');
  }
  
  // Schedule recurring reminder (next 30 occurrences)
  Future<void> _scheduleRecurringReminder(
    EntryModel entry,
    Reminder reminder,
  ) async {
    if (reminder.id == null) {
      print('❌ Cannot schedule recurring reminder: No ID');
      return;
    }
    
    if (reminder.recurrenceRule == null || reminder.recurrenceRule == 'none') {
      print('❌ Cannot schedule recurring reminder: No recurrence rule');
      return;
    }
    
    print('📅 Scheduling recurring reminder: ${reminder.recurrenceRule}');
    print('   Base ID: ${reminder.id}');
    print('   Start time: ${reminder.reminderTime}');
    print('   Sound: ${reminder.soundName ?? "default"}');
    
    DateTime currentTime = reminder.reminderTime;
    int scheduled = 0;
    int attempted = 0;
    const maxOccurrences = 30; // Schedule next 30 occurrences
    const maxAttempts = 100; // Prevent infinite loops
    
    // Schedule up to 30 future occurrences
    while (scheduled < maxOccurrences && attempted < maxAttempts) {
      attempted++;
      
      // Only schedule if time is in the future
      if (currentTime.isAfter(DateTime.now())) {
        // Use unique ID for each occurrence: baseId + occurrence number
        // Using larger multiplier to avoid ID conflicts
        final occurrenceId = reminder.id! + (scheduled * 100000);
        
        try {
          print('   Scheduling occurrence ${scheduled + 1}/$maxOccurrences at $currentTime (ID: $occurrenceId)');
          
          await scheduleNotification(
            id: occurrenceId,
            title: '📝 ${entry.title}',
            body: entry.content.isEmpty
                ? 'Reminder for your entry'
                : (entry.content.length > 100
                    ? '${entry.content.substring(0, 100)}...'
                    : entry.content),
            scheduledTime: currentTime,
            payload: entry.id,
            sound: reminder.soundName,
          );
          scheduled++;
          print('   ✅ Occurrence ${scheduled} scheduled successfully');
        } catch (e) {
          print('   ⚠️ Failed to schedule occurrence ${scheduled + 1}: $e');
          // Continue trying other occurrences
        }
      } else {
        print('   ⏭️ Skipping past time: $currentTime');
      }
      
      // Calculate next occurrence
      try {
        switch (reminder.recurrenceRule) {
          case 'daily':
            currentTime = DateTime(
              currentTime.year,
              currentTime.month,
              currentTime.day + 1,
              currentTime.hour,
              currentTime.minute,
            );
            break;
          case 'weekly':
            currentTime = DateTime(
              currentTime.year,
              currentTime.month,
              currentTime.day + 7,
              currentTime.hour,
              currentTime.minute,
            );
            break;
          case 'monthly':
            // Handle month overflow properly
            int nextMonth = currentTime.month + 1;
            int nextYear = currentTime.year;
            if (nextMonth > 12) {
              nextMonth = 1;
              nextYear++;
            }
            // Handle day overflow (e.g., Jan 31 -> Feb 28)
            int nextDay = currentTime.day;
            final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
            if (nextDay > daysInNextMonth) {
              nextDay = daysInNextMonth;
            }
            currentTime = DateTime(
              nextYear,
              nextMonth,
              nextDay,
              currentTime.hour,
              currentTime.minute,
            );
            break;
          default:
            print('❌ Unknown recurrence rule: ${reminder.recurrenceRule}');
            return;
        }
      } catch (e) {
        print('❌ Error calculating next occurrence: $e');
        break;
      }
    }
    
    if (scheduled == 0) {
      print('⚠️ No occurrences were scheduled (all times were in the past)');
    } else {
      print('✅ Successfully scheduled $scheduled recurring occurrences');
    }
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    try {
      if (id > 0) {
        await _notifications.cancel(id);
        print('✅ Notification $id cancelled');
      } else {
        print('⚠️ Invalid notification ID: $id');
      }
    } catch (e) {
      print('❌ Error cancelling notification $id: $e');
      // Don't throw - allow deletion to continue even if cancel fails
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('⚠️ Error cancelling all notifications: $e');
    }
  }

  // Clear corrupted notification data (public method for manual fixes)
  Future<void> clearCorruptedNotificationData() async {
    await _clearCorruptedNotificationData();
  }

  // Complete reset of notification system (nuclear option)
  // Use this if notifications are completely broken
  Future<void> resetNotificationSystem() async {
    try {
      print('🔄 Performing complete notification system reset...');
      
      // Step 1: Cancel all notifications
      try {
        await _notifications.cancelAll();
        print('✅ Step 1: All notifications cancelled');
      } catch (e) {
        print('⚠️ Step 1: Error cancelling notifications: $e');
      }
      
      // Step 2: Clear all SharedPreferences data (aggressive)
      await _forceClearSharedPreferencesData();
      await _clearCorruptedNotificationData();
      print('✅ Step 2: SharedPreferences cleared');
      
      // Step 3: Wait for cleanup to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 4: Re-initialize the notification system
      await initialize();
      print('✅ Step 4: Notification system re-initialized');
      
      print('✅ Complete notification system reset completed');
    } catch (e) {
      print('❌ Error during notification system reset: $e');
      rethrow;
    }
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      print('🔔 Showing immediate notification...');
      print('   ID: $id');
      print('   Title: $title');
      print('   Body: $body');

      const androidDetails = AndroidNotificationDetails(
        'mindscribe_reminders',
        'Reminders',
        channelDescription: 'Notifications for diary entries and events',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('✅ Immediate notification shown successfully');
    } catch (e) {
      print('❌ Error showing immediate notification: $e');
    }
  }

  // Test notification - shows immediately
  Future<void> testNotification() async {
    await showImmediateNotification(
      id: 999999,
      title: '🎉 Test Notification',
      body: 'If you see this, notifications are working!',
    );
  }

  // Get pending notifications with error handling
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      
      // Check if it's the "Missing type parameter" error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('missing type parameter') || 
          errorString.contains('type parameter') ||
          errorString.contains('platformexception')) {
        print('⚠️ Detected corrupted notification data');
        print('💡 Attempting automatic recovery...');
        
        // Try to recover
        try {
          await _clearCorruptedNotificationData();
          print('✅ Corrupted data cleared - please try again');
        } catch (recoveryError) {
          print('❌ Recovery failed: $recoveryError');
        }
      }
      
      return [];
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }

    return true; // Assume enabled for iOS
  }

  // Check if exact alarms are allowed (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final canSchedule = await androidImpl.canScheduleExactNotifications();
        print('📱 Can schedule exact alarms: $canSchedule');
        return canSchedule ?? false;
      }

      return true;
    } catch (e) {
      print('❌ Error checking exact alarm permission: $e');
      return false;
    }
  }

  // Request exact alarm permission (Android 12+)
  Future<void> requestExactAlarmPermission() async {
    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        await androidImpl.requestExactAlarmsPermission();
        print('✅ Exact alarm permission requested');
      }
    } catch (e) {
      print('❌ Error requesting exact alarm permission: $e');
    }
  }
  
  // Request battery optimization exemption
  Future<void> requestBatteryOptimizationExemption() async {
    try {
      print('💡 To ensure notifications work when app is closed:');
      print('   1. Go to Settings → Apps → MindScribe');
      print('   2. Battery → Unrestricted');
      print('   3. Or disable battery optimization');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
