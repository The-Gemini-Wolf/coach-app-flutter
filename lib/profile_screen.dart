import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
    const ProfileScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            'Account',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Sign In'),
                            subtitle: const Text('Coming Soon (Google/Apple sign-in)'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                        ),
                        const SizedBox(height:24),
                        const Text(
                            'Premium',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                            leading: const Icon(Icons.star),
                            title: const Text('Upgrade to Premium'),
                            subtitle: const Text('Custom EOD time & More'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                        ),
                    ],
                ),
            ),
        );
    }
}