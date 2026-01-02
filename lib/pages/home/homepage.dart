import 'package:flutter/material.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';
import 'hometab.dart';
import 'process_tab.dart';
import 'completed_tab.dart';
import 'profile_tab.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;

  List<Widget> pages = [
    HomeTab(),
    ProcessTab(),
    CompletedTab(),
    ProfileTab(),
  ];

  void onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // --- This is the main widget from the package ---
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTap,
        unselectedItemColor: Colors.grey.shade500,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n?.home ?? "Home"),
          BottomNavigationBarItem(
              icon: const Icon(Icons.warning_rounded),
              label: l10n?.safetyMap ?? "Safety Map"),
          BottomNavigationBarItem(
              icon: const Icon(Icons.travel_explore_rounded),
              label: l10n?.trips ?? "Trips"),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n?.profile ?? "Profile"),
        ],
      ),
      body: pages[_currentIndex],
    );
  }
}
