import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/db_helper.dart';
import 'reminders_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/vitals_card.dart';
import 'widgets/quote_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nextMedication = "No Medications";
  String nextAppointment = "No Appointments";

  // 🔹 Favorite contact
  List<Map<String, dynamic>> favContacts = [];
  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFavoriteContact();
  }

  Future<void> _loadData() async {
    final db = DBHelper.instance;

    // Get upcoming medications
    final upcomingMeds = await db.getUpcomingMedications();
    if (!mounted) return;
    if (upcomingMeds.isNotEmpty) {
      setState(() {
        nextMedication = upcomingMeds.map((m) {
          final timeStr = m['time'];
          final parsedTime = DateFormat("HH:mm").parse(timeStr);
          final formattedTime = DateFormat.jm().format(parsedTime); 
          return "${m['name']} at $formattedTime";
        }).join("\n");
      });
    }

    // Get next appointment
    final appts = await db.getNextAppointment();
    if (appts.isNotEmpty) {
      setState(() {
        final parsedTime = DateFormat("HH:mm").parse(appts[0]['time']);
        final formattedTime = DateFormat.jm().format(parsedTime);
        nextAppointment =
            "${appts[0]['doctor_name']} at ${appts[0]['date']} $formattedTime";
      });
    }
  }

  Future<void> _loadFavoriteContact() async {
    final contacts = await DBHelper.instance.getFavoriteContact();
    setState(() {
      favContacts = contacts;
    });
  }

  Future<void> _callNumber(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Greeting
          Text(
            "Hi, ${FirebaseAuth.instance.currentUser?.displayName ?? "User"}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),

          // Today’s date
          Text(
            "${DateFormat('EEEE, MMM d').format(DateTime.now())}",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 20),

          const QuoteSection(),

          // Quick cards for next medication & appointment
          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  context,
                  Icons.medication,
                  "Upcoming Med",
                  nextMedication,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickCard(
                  context,
                  Icons.calendar_today,
                  "Upcoming Appt",
                  nextAppointment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🔹 Favorite Emergency Contact Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Text(
                  "Favorite Contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white   // white in dark mode
                        : Colors.black,  // black in light mode
                  ),
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DBHelper.instance.getFavoriteContact(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final contacts = snapshot.data!;
                  if (contacts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No favorite emergency contacts set"),
                    );
                  }
                  return Column(
                    children: contacts.map((c) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(
                            c['contact_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            c['phone'],
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () {
                              final Uri callUri = Uri(scheme: 'tel', path: c['phone']);
                              launchUrl(callUri);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),

          const VitalsCard(),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildQuickCard(
      BuildContext context, IconData icon, String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
