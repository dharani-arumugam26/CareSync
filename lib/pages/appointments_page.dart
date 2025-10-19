import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/db_helper.dart';
import 'add_edit_appointment_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final data = await DBHelper.getAppointments();
    setState(() {
      appointments = data;
    });
  }

  Future<void> _deleteAppointment(int id) async {
    await DBHelper.deleteAppointment(id);
    _loadAppointments();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment deleted')),
    );
  }

  void _navigateToAddEdit([Map<String, dynamic>? appointment]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAppointmentPage(appointment: appointment),
      ),
    );
    if (result == true) _loadAppointments();
  }

  /// Launches the dialer with the doctor's number
  void _callDoctor(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot make the call')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.blue,
      ),
      body: appointments.isEmpty
          ? const Center(child: Text('No appointments added yet'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final app = appointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text('${app['doctor_name']} (${app['clinic_name']})'),
                    subtitle: Text(
                      "Phone: ${app['phone']}\n"
                      "${app['date']} at ${app['time']}\n"
                      "${app['notes'] ?? ''}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () => _callDoctor(app['phone']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAppointment(app['id']),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToAddEdit(app),
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100), 
        child: FloatingActionButton(
          onPressed: () => _navigateToAddEdit(),
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
