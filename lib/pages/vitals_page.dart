import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'add_edit_vital_page.dart';

class VitalsPage extends StatefulWidget {
  const VitalsPage({Key? key}) : super(key: key);

  @override
  State<VitalsPage> createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> {
  List<Map<String, dynamic>> vitals = [];
  Map<String, double> averages = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    final rows = await DBHelper.getVitals();
    final avg = await DBHelper.getVitalAverages();
    setState(() {
      vitals = rows;
      averages = avg;
      loading = false;
    });
  }

  Future<void> _deleteVital(int id) async {
    await DBHelper.deleteVital(id);
    _loadVitals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vitals Log"),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Averages
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Averages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("BP: ${averages['avg_systolic']?.toStringAsFixed(1) ?? '0'}/${averages['avg_diastolic']?.toStringAsFixed(1) ?? '0'} mmHg"),
                        Text("Sugar: ${averages['avg_sugar']?.toStringAsFixed(1) ?? '0'} mg/dL"),
                        Text("Weight: ${averages['avg_weight']?.toStringAsFixed(1) ?? '0'} kg"),
                        Text("Pulse: ${averages['avg_pulse']?.toStringAsFixed(1) ?? '0'} bpm"),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                // Logs
                Expanded(
                  child: vitals.isEmpty
                      ? const Center(child: Text("No vitals logged yet. Tap + to add."))
                      : ListView.builder(
                          itemCount: vitals.length,
                          itemBuilder: (context, index) {
                            final v = vitals[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text("BP: ${v['systolic']}/${v['diastolic']} | Sugar: ${v['sugar']} mg/dL"),
                                subtitle: Text("Weight: ${v['weight']} kg | Pulse: ${v['pulse']} bpm\nDate: ${v['created_at']}"),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteVital(v['id']),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 100), 
              child: FloatingActionButton(
                onPressed: () async {
                  final saved = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddEditVitalPage()),
                  );
                  if (saved == true) _loadVitals();
                },
                child: const Icon(Icons.add),
                backgroundColor: Colors.blue,
              ),
            ),
    );
  }
}