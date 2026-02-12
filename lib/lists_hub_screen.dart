import 'package:flutter/material.dart';

import 'appointments_screen.dart';
import 'shopping_list_screen.dart';
import 'cleaning_checklist_screen.dart';

class ListsHubScreen extends StatelessWidget {
  const ListsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lists & More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubTile(
            title: 'Appointments',
            icon: Icons.event,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _HubTile(
            title: 'Shopping List',
            icon: Icons.shopping_cart,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _HubTile(
            title: 'Cleaning Checklist',
            icon: Icons.cleaning_services,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CleaningChecklistScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
