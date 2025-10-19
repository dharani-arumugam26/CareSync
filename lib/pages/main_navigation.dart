import 'package:flutter/material.dart';
import 'home_page.dart';
import 'medications_page.dart';
import 'appointments_page.dart';
import 'vitals_page.dart';
import 'emergency_contacts_page.dart'; 
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  final Function(bool)? onToggleTheme;
  
  const MainNavigation({
    super.key, 
    this.onToggleTheme,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      MedicationsPage(),
      AppointmentsPage(),
      VitalsPage(),
      EmergencyContactsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
              borderRadius: BorderRadius.circular(50),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey[400],
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 20,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 20),
                  activeIcon: Icon(Icons.home, size: 26),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.medication_outlined, size: 20),
                  activeIcon: Icon(Icons.medication, size: 26),
                  label: 'Medications',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined, size: 20),
                  activeIcon: Icon(Icons.calendar_today, size: 26),
                  label: 'Appointments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border, size: 20),
                  activeIcon: Icon(Icons.favorite, size: 26),
                  label: 'Vitals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.contact_phone, size: 20),
                  activeIcon: Icon(Icons.contact_phone, size: 26),
                  label: 'Emergency',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
