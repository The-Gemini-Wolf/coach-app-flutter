import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Appointments page (coming next).'),
      ),
    );
  }
}
