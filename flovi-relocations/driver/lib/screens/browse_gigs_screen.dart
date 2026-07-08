import 'package:flutter/material.dart';

import '../models/relocation_request.dart';
import '../services/auth_service.dart';
import '../services/requests_service.dart';

/// Read-only list of open (unbooked) relocation gigs, shown as the driver's
/// home screen after signing in. Updates live via [RequestsService].
class BrowseGigsScreen extends StatefulWidget {
  const BrowseGigsScreen({super.key});

  @override
  State<BrowseGigsScreen> createState() => _BrowseGigsScreenState();
}

class _BrowseGigsScreenState extends State<BrowseGigsScreen> {
  final _requestsService = RequestsService();

  @override
  void dispose() {
    _requestsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Gigs'),
        actions: [
          IconButton(
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _requestsService,
        builder: (context, _) {
          final requests = _requestsService.openRequests;

          if (_requestsService.isLoading && requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_requestsService.error != null && requests.isEmpty) {
            return _ErrorState(onRetry: _requestsService.fetchOpenRequests);
          }

          if (requests.isEmpty) {
            return _EmptyState(onRefresh: _requestsService.fetchOpenRequests);
          }

          return RefreshIndicator(
            onRefresh: _requestsService.fetchOpenRequests,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) => _GigCard(request: requests[index]),
            ),
          );
        },
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  const _GigCard({required this.request});

  final RelocationRequest request;

  @override
  Widget build(BuildContext context) {
    final notes = request.notes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.origin} → ${request.destination}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(_formatDate(request.moveDate)),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No open gigs right now.\nPull down to refresh.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Something went wrong loading gigs.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
