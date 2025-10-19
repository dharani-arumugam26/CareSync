import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final db = DBHelper.instance;
    final todayReminders = await db.getRemindersForToday();
    setState(() {
      reminders = todayReminders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Reminders"), centerTitle: true),
      body: reminders.isEmpty
          ? const Center(child: Text("No reminders for today"))
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.alarm, color: Colors.blue),
                    title: Text(reminder["title"] ?? ""),
                    subtitle: Text(reminder["time"] ?? ""),
                  ),
                );
              },
            ),
    );
  }
}
