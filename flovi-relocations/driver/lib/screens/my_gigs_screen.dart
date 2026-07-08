import 'package:flutter/material.dart';

import '../models/relocation_request.dart';
import '../services/requests_service.dart';

/// Read-only list of the current driver's booked gigs. Updates live via the
/// shared [RequestsService] passed in from the parent navigation shell.
class MyGigsScreen extends StatelessWidget {
  const MyGigsScreen({super.key, required this.requestsService});

  final RequestsService requestsService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: requestsService,
      builder: (context, _) {
        final requests = requestsService.myBookedRequests;

        if (requestsService.isLoadingMyBookings && requests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (requestsService.myBookingsError != null && requests.isEmpty) {
          return _ErrorState(onRetry: requestsService.fetchMyBookedRequests);
        }

        if (requests.isEmpty) {
          return _EmptyState(onRefresh: requestsService.fetchMyBookedRequests);
        }

        return RefreshIndicator(
          onRefresh: requestsService.fetchMyBookedRequests,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) => _MyGigCard(request: requests[index]),
          ),
        );
      },
    );
  }
}

class _MyGigCard extends StatelessWidget {
  const _MyGigCard({required this.request});

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${request.origin} → ${request.destination}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                const _StatusBadge(),
              ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Booked',
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
                    "You haven't booked any gigs yet — browse available "
                    'gigs to get started.',
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
          const Text('Something went wrong loading your gigs.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
