import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/requests_service.dart';
import 'browse_gigs_screen.dart';
import 'my_gigs_screen.dart';

/// Shown after sign-in: an app bar (with sign-out) plus a Material 3 bottom
/// navigation bar switching between Browse Gigs and My Gigs. Both tabs share
/// a single [RequestsService] instance so a booking made on one tab is
/// immediately reflected on the other.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _requestsService = RequestsService();
  int _selectedIndex = 0;

  static const _titles = ['Available Gigs', 'My Gigs'];

  @override
  void dispose() {
    _requestsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          BrowseGigsScreen(requestsService: _requestsService),
          MyGigsScreen(requestsService: _requestsService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Browse'),
          NavigationDestination(
            icon: Icon(Icons.event_available),
            label: 'My Gigs',
          ),
        ],
      ),
    );
  }
}
