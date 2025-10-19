import 'package:flutter/material.dart';
import 'package:caresync/database/db_helper.dart';

class VitalsCard extends StatefulWidget {
  const VitalsCard({Key? key}) : super(key: key);

  @override
  _VitalsCardState createState() => _VitalsCardState();
}

class _VitalsCardState extends State<VitalsCard> {
  Map<String, dynamic>? latestVitals;

  @override
  void initState() {
    super.initState();
    _fetchVitals();
  }

  Future<void> _fetchVitals() async {
    final data = await DBHelper.instance.getLatestVitals();
    setState(() {
      latestVitals = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: latestVitals == null
            ? const Text("No vitals logged yet")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Latest Vitals",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("BP: ${latestVitals!['systolic']}/${latestVitals!['diastolic']} mmHg"),
                  Text("Sugar: ${latestVitals!['sugar']} mg/dL"),
                  Text("Pulse: ${latestVitals!['pulse']} bpm"),
                  Text("Weight: ${latestVitals!['weight']} kg"),
                ],
              ),
      ),
    );
  }
}
