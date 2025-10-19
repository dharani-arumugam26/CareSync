import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/db_helper.dart'; // adjust path if needed

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  // Map<groupId, { "id": int, "group_name": String, "contacts": List<Map> }>
  Map<int, Map<String, dynamic>> contacts = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    var dbContacts = await DBHelper.instance.getAllEmergencyContacts();
    setState(() {
      contacts = dbContacts;
    });
  }

  Future<void> _callNumber(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  Future<void> _sendSMS(String number) async {
    final Uri smsUri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  void _addGroup() {
    String groupName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Group'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Enter group name'),
          onChanged: (value) => groupName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (groupName.isNotEmpty) {
                await DBHelper.instance.insertEmergencyGroup(groupName);
                _loadContacts();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addContact(int groupId) {
    String name = '';
    String phone = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Name'),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: const InputDecoration(hintText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              onChanged: (value) => phone = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (name.isNotEmpty && phone.isNotEmpty) {
                await DBHelper.instance.insertEmergencyContact(groupId, name, phone);
                _loadContacts();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeContact(int contactId) async {
    await DBHelper.instance.deleteEmergencyContact(contactId);
    _loadContacts();
  }

  void _removeGroup(int groupId) async {
    await DBHelper.instance.deleteEmergencyGroup(groupId);
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: contacts.isEmpty
          ? const Center(child: Text('No groups yet. Tap + to add a group.'))
          : ListView(
              children: contacts.entries.map((entry) {
                final groupId = entry.key;
                final groupData = entry.value;
                final groupName = groupData['group_name'] as String;
                final groupContacts = groupData['contacts'] as List<Map<String, dynamic>>;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            groupName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeGroup(groupId),
                          ),
                        ],
                      ),
                      children: [
                        ...groupContacts.map((contact) {
                          return ListTile(
                            title: Text(contact['contact_name']),
                            subtitle: Text(contact['phone']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  onPressed: () => _callNumber(contact['phone']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.message, color: Colors.blue),
                                  onPressed: () => _sendSMS(contact['phone']),
                                ),
                                IconButton(
                                  icon: Icon(
                                    contact['isFavorite'] == 1 ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () async {
                                    await DBHelper.instance.setFavoriteContact(contact['id']);
                                    _loadContacts(); // refresh UI
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeContact(contact['id']),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Add Contact'),
                          onTap: () => _addContact(groupId),
                        ),
                        
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          onPressed: _addGroup,
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
          tooltip: 'Add Group',
        ),
      ),
    );
  }
}
