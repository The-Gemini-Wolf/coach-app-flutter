import 'package:flutter/material.dart';
import 'lists_hub_screen.dart';
import 'profile_screen.dart';
import 'coach_home_screen.dart';
import 'main.dart'; // TodayScreen lives in main.dart right now

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const CoachHomeScreen(),
    const TodayScreen(),
    const ListsHubScreen(),
    const ProfileScreen(), // later: Appointments / Lists etc
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
        Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
