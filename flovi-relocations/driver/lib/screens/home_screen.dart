import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = user?.userMetadata?['full_name'] as String?;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver App'),
        actions: [
          IconButton(
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              name ?? email,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (name != null && email.isNotEmpty)
              Text(email, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
