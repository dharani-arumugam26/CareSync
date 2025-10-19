// services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  Future<void> init() async {
    //Initialize timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleMedicationReminder(
    int id,
    String medName,
    String dosage,
    TimeOfDay time,
  ) async {
    const String channelId = 'meds_bell_channel';
    const String channelName = 'Medication Reminders (Bell)';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Reminder notifications for medications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('bell_tone'),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Medication Reminder',
      'Take $medName - $dosage',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }


  // Optional: Test notification method
  Future<void> scheduleTestNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Test Reminder',
      'This is a test medication reminder',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel',
          'Medication Notifications',
          channelDescription: 'Reminders for meds',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print(' Test notification scheduled in 5 seconds');
  }

  Future<void> scheduleAppointmentReminder(
    int appointmentId,
    String doctorName,
    DateTime date,
    TimeOfDay time,
  ) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print("Appointment time is in the past. Skipping notification.");
      return;
    }

    final notifId = appointmentId * 100; // ensure unique

    const String channelId = 'appointments_bell_channel';
    const String channelName = 'Appointment Reminders (Bell)';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Reminder notifications for appointments',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('bell_tone'), // Always Bell
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notifId,
      'Appointment Reminder',
      'You have an appointment with $doctorName',
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print("Scheduled appointment '$doctorName' at $scheduledDate with ID $notifId");
  }
}