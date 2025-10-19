import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'add_edit_medication_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({Key? key}) : super(key: key);

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  bool loading = true;

  Map<String, List<Map<String, dynamic>>> groupedMeds = {
    "Morning": [],
    "Afternoon": [],
    "Evening": [],
    "Night": [],
  };

  @override
  void initState() {
    super.initState();
    loadMeds();
  }

  Future<void> loadMeds() async {
    setState(() => loading = true);
    final data = await DBHelper.getMedications();

    Map<String, List<Map<String, dynamic>>> tempGrouped = {
      "Morning": [],
      "Afternoon": [],
      "Evening": [],
      "Night": [],
    };

    for (var med in data) {
      final rows = await DBHelper.getMedicationTimes(med['id']);

      for (var r in rows) {
        final parts = (r['time'] as String).split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final timeOfDay = TimeOfDay(hour: hour, minute: minute);
        final formattedTime = timeOfDay.format(context);

        // 🔹 create a clean object with only what we need
        final medEntry = {
          "id": med['id'],
          "name": med['name'],
          "dosage": med['dosage'],
          "frequency": med['frequency'],
          "reminder_time": formattedTime, 
        };

        // group
        if (hour >= 5 && hour < 12) {
          tempGrouped["Morning"]!.add(medEntry);
        } else if (hour >= 12 && hour < 17) {
          tempGrouped["Afternoon"]!.add(medEntry);
        } else if (hour >= 17 && hour < 21) {
          tempGrouped["Evening"]!.add(medEntry);
        } else {
          tempGrouped["Night"]!.add(medEntry);
        }
      }
    }

    setState(() {
      groupedMeds = tempGrouped;
      loading = false;
    });
  }

  Future<void> _openAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditMedicationPage()),
    );
    if (result == true) await loadMeds();
  }

  Future<void> _openEditPage(Map<String, dynamic> medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditMedicationPage(medication: medication)),
    );
    if (result == true) await loadMeds();
  }

  Future<void> _deleteMedication(int id) async {
    await DBHelper.deleteMedication(id);
    await loadMeds();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Medications"),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : groupedMeds.values.every((list) => list.isEmpty)
              ? const Center(
                  child: Text(
                    "No medications added yet",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: groupedMeds.entries
                      .where((entry) => entry.value.isNotEmpty)
                      .map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white   // White in dark mode
                                  : Colors.black,  // Black in light mode
                            ),
                          ),
                        ),
                        ...entry.value.map((med) {
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            elevation: 5,
                            margin:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.medication,
                                  color: Colors.blue),
                              title: Text(
                                med['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "${med['dosage'] ?? ''} | ${med['reminder_time'] ?? ''} | ${med['frequency'] ?? ''}",
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () async =>
                                    _deleteMedication(med['id']),
                              ),
                              onTap: () => _openEditPage(med),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          onPressed: _openAddPage,
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
