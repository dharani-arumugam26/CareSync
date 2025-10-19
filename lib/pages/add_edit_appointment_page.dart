import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart'; // ✅ use service, not main.dart

class AddEditAppointmentPage extends StatefulWidget {
  final Map<String, dynamic>? appointment;
  const AddEditAppointmentPage({Key? key, this.appointment}) : super(key: key);

  @override
  State<AddEditAppointmentPage> createState() => _AddEditAppointmentPageState();
}

class _AddEditAppointmentPageState extends State<AddEditAppointmentPage> {
  final doctorController = TextEditingController();
  final clinicController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      doctorController.text = widget.appointment!['doctor_name'] ?? '';
      clinicController.text = widget.appointment!['clinic_name'] ?? '';
      phoneController.text = widget.appointment!['phone'] ?? '';
      notesController.text = widget.appointment!['notes'] ?? '';
      selectedDate = DateTime.tryParse(widget.appointment!['date'] ?? '');
      final timeParts = (widget.appointment!['time'] ?? '00:00').split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }

  @override
  void dispose() {
    doctorController.dispose();
    clinicController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (doctorController.text.trim().isEmpty ||
        clinicController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final data = {
      'doctor_name': doctorController.text.trim(),
      'clinic_name': clinicController.text.trim(),
      'phone': phoneController.text.trim(),
      'date': selectedDate!.toIso8601String().split('T')[0],
      'time':
          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
      'notes': notesController.text.trim(),
    };

    int appointmentId;
    if (widget.appointment != null && widget.appointment!['id'] != null) {
      appointmentId = widget.appointment!['id'] as int;
      await DBHelper.updateAppointment(appointmentId, data);
    } else {
      appointmentId = await DBHelper.insertAppointment(data);
    }

    // ✅ Schedule notification via NotificationService
    await NotificationService().scheduleAppointmentReminder(
      appointmentId,
      doctorController.text,
      selectedDate!,
      selectedTime!,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.appointment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Appointment' : 'Add Appointment'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: doctorController,
                decoration: const InputDecoration(labelText: 'Doctor Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clinicController,
                decoration: const InputDecoration(labelText: 'Clinic Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number *'),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(selectedDate != null
                    ? 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'
                    : 'Select Date *'),
                onTap: _pickDate,
              ),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.blue),
                title: Text(selectedTime != null
                    ? 'Time: ${selectedTime!.format(context)}'
                    : 'Select Time *'),
                onTap: _pickTime,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Update Appointment' : 'Save Appointment',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
