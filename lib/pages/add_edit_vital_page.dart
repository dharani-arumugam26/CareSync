import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class AddEditVitalPage extends StatefulWidget {
  final Map<String, dynamic>? vital; // optional for future editing
  const AddEditVitalPage({Key? key, this.vital}) : super(key: key);

  @override
  State<AddEditVitalPage> createState() => _AddEditVitalPageState();
}

class _AddEditVitalPageState extends State<AddEditVitalPage> {
  final bpSystolicController = TextEditingController();
  final bpDiastolicController = TextEditingController();
  final sugarController = TextEditingController();
  final weightController = TextEditingController();
  final pulseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.vital != null) {
      bpSystolicController.text = widget.vital!['bp_systolic']?.toString() ?? '';
      bpDiastolicController.text = widget.vital!['bp_diastolic']?.toString() ?? '';
      sugarController.text = widget.vital!['sugar']?.toString() ?? '';
      weightController.text = widget.vital!['weight']?.toString() ?? '';
      pulseController.text = widget.vital!['pulse']?.toString() ?? '';
    }
  }

  Future<void> _saveVital() async {
    if (bpSystolicController.text.isEmpty ||
        bpDiastolicController.text.isEmpty ||
        sugarController.text.isEmpty ||
        weightController.text.isEmpty ||
        pulseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final data = {
      'systolic': int.tryParse(bpSystolicController.text) ?? 0,
      'diastolic': int.tryParse(bpDiastolicController.text) ?? 0,
      'sugar': double.tryParse(sugarController.text) ?? 0.0,
      'weight': double.tryParse(weightController.text) ?? 0.0,
      'pulse': int.tryParse(pulseController.text) ?? 0,
      'created_at': DateTime.now().toString(),
    };


    await DBHelper.insertVital(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vital log saved")),
    );

    Navigator.of(context).pop(true); // return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vital != null ? "Edit Vital" : "Add Vital"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: bpSystolicController,
              decoration: const InputDecoration(labelText: "Blood Pressure (Systolic)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bpDiastolicController,
              decoration: const InputDecoration(labelText: "Blood Pressure (Diastolic)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sugarController,
              decoration: const InputDecoration(labelText: "Sugar (mg/dL)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: "Weight (kg)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pulseController,
              decoration: const InputDecoration(labelText: "Pulse (bpm)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveVital,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(widget.vital != null ? "Update Vital" : "Save Vital"),
            ),
          ],
        ),
      ),
    );
  }
}
