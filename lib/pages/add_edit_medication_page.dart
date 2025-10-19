import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database/db_helper.dart';
import '../main.dart';
import '../services/notification_service.dart';

class AddEditMedicationPage extends StatefulWidget {
  final Map<String, dynamic>? medication;
  const AddEditMedicationPage({Key? key, this.medication}) : super(key: key);

  @override
  State<AddEditMedicationPage> createState() => _AddEditMedicationPageState();
}

class _AddEditMedicationPageState extends State<AddEditMedicationPage> {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController();

  String repeatOption = 'once';
  List<String> selectedDays = [];
  List<TimeOfDay> times = []; // multiple times

  String? selectedSound; // nullable string

  @override
  void initState() {
    super.initState();

    if (widget.medication != null) {
      nameController.text = widget.medication!['name'] ?? '';
      dosageController.text = widget.medication!['dosage'] ?? '';
      frequencyController.text = widget.medication!['frequency'] ?? '';
      repeatOption = widget.medication!['repeat'] ?? 'once';

      if (widget.medication!['custom_days'] != null) {
        selectedDays = (widget.medication!['custom_days'] as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // 🔹 Restore saved sound or default
      if (widget.medication != null && widget.medication!['sound'] != null) {
        selectedSound = widget.medication!['sound'];
      } else {
        selectedSound = ''; // Default system sound
      }


      _loadTimes(widget.medication!['id']);
    }
  }

  Future<void> _loadTimes(int medId) async {
    final rows = await DBHelper.getMedicationTimes(medId);
    setState(() {
      times = rows.map((r) {
        final parts = (r['time'] as String).split(':');
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => times.add(time));
    }
  }

  Future<void> _saveMedication() async {
    final name = nameController.text.trim();
    if (name.isEmpty || times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter all required fields')));
      return;
    }

    final medData = {
      'name': name,
      'dosage': dosageController.text.trim(),
      'frequency': frequencyController.text.trim(),
      'repeat': repeatOption,
      'custom_days': repeatOption == 'custom' ? selectedDays.join(',') : null,
      'sound': selectedSound, // 🔹 Save sound choice
    };

    int medId;
    if (widget.medication != null && widget.medication!['id'] != null) {
      medId = widget.medication!['id'] as int;
      await DBHelper.updateMedication(medId, medData);
      await DBHelper.deleteMedicationTimes(medId);
    } else {
      medId = await DBHelper.instance.insertMedication(medData);  
    }

    // Save all times and schedule notifications
    int notifId = medId * 100; // unique base per medication
    for (var t in times) {
      final timeStr = '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
      await DBHelper.insertMedicationTime(medId, timeStr);

      await _scheduleNotification(
        notifId++,
        name,
        t,
        repeatOption,
        selectedSound ?? '',   // ✅ just pass the string or '' if null
        customDays: selectedDays,
      );

    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(widget.medication != null
              ? 'Medication updated'
              : 'Medication added')),
    );

    Navigator.of(context).pop(true);
  }

  Future<void> _scheduleNotification(
    int id,
    String medName,
    TimeOfDay time,
    String repeat,
    String sound, { // 🔹 Added sound param
    List<String>? customDays,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'meds_channel',
      'Medication Reminders',
      channelDescription: 'Reminders for taking medications',
      importance: Importance.max,
      priority: Priority.high,
      sound: (sound.isNotEmpty)
          ? RawResourceAndroidNotificationSound(sound)  // custom
          : null,                                       // default system sound
      playSound: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    if (repeat == 'once') {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Medication Reminder',
        'Take $medName',
        scheduleDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else if (repeat == 'daily') {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Medication Reminder',
        'Take $medName',
        scheduleDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else if (repeat == 'weekly') {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Medication Reminder',
        'Take $medName',
        scheduleDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } else if (repeat == 'custom' && customDays != null) {
      for (var day in customDays) {
        final weekday = _dayStringToInt(day);
        final next = _nextInstanceOfWeekdayTime(weekday, time);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id++,
          'Medication Reminder',
          'Take $medName',
          next,
          notificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  int _dayStringToInt(String day) {
    switch (day) {
      case 'Mon': return DateTime.monday;
      case 'Tue': return DateTime.tuesday;
      case 'Wed': return DateTime.wednesday;
      case 'Thu': return DateTime.thursday;
      case 'Fri': return DateTime.friday;
      case 'Sat': return DateTime.saturday;
      case 'Sun': return DateTime.sunday;
      default: return DateTime.monday;
    }
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, TimeOfDay time) {
    tz.TZDateTime scheduled =
        tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime(
      tz.local,
      scheduled.year,
      scheduled.month,
      scheduled.day,
      time.hour,
      time.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medication != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Medication" : "Add Medication"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Medication Name *"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: "Dosage"),
              keyboardType: TextInputType.number, 
            ),

            const SizedBox(height: 10),
            TextField(
              controller: frequencyController,
              decoration: const InputDecoration(labelText: "Frequency"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Times:"),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Time"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: times.map((t) {
                return ListTile(
                  title: Text("⏰ ${t.format(context)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => times.remove(t));
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: repeatOption,
              decoration: const InputDecoration(labelText: "Repeat *"),
              items: const [
                DropdownMenuItem(value: "once", child: Text("One time only")),
                DropdownMenuItem(value: "daily", child: Text("Daily")),
                DropdownMenuItem(value: "weekly", child: Text("Weekly")),
                DropdownMenuItem(value: "custom", child: Text("Custom")),
              ],
              onChanged: (value) {
                setState(() => repeatOption = value!);
              },
            ),
            if (repeatOption == 'custom') const SizedBox(height: 10),
            if (repeatOption == 'custom')
              Wrap(
                spacing: 8,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((day) {
                  final isSelected = selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMedication,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child:
                  Text(isEdit ? "Update Medication" : "Save Medication"),
            ),
          ],
        ),
      ),
    );
  }
}