import 'package:flutter/material.dart';

import '../models/relocation_request.dart';
import '../services/requests_service.dart';

/// Read-only list of open (unbooked) relocation gigs, with one-tap booking.
/// Updates live via the shared [RequestsService] passed in from the parent
/// navigation shell.
class BrowseGigsScreen extends StatelessWidget {
  const BrowseGigsScreen({super.key, required this.requestsService});

  final RequestsService requestsService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: requestsService,
      builder: (context, _) {
        final requests = requestsService.openRequests;

        if (requestsService.isLoading && requests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (requestsService.error != null && requests.isEmpty) {
          return _ErrorState(onRetry: requestsService.fetchOpenRequests);
        }

        if (requests.isEmpty) {
          return _EmptyState(onRefresh: requestsService.fetchOpenRequests);
        }

        return RefreshIndicator(
          onRefresh: requestsService.fetchOpenRequests,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) => _GigCard(
              request: requests[index],
              requestsService: requestsService,
            ),
          ),
        );
      },
    );
  }
}

class _GigCard extends StatefulWidget {
  const _GigCard({required this.request, required this.requestsService});

  final RelocationRequest request;
  final RequestsService requestsService;

  @override
  State<_GigCard> createState() => _GigCardState();
}

class _GigCardState extends State<_GigCard> {
  bool _isBooking = false;

  Future<void> _handleBookPressed() async {
    final request = widget.request;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm booking'),
        content: Text(
          'Book this move from ${request.origin} to ${request.destination}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBooking = true);

    final result = await widget.requestsService.bookRequest(request.id);

    if (!mounted) return;
    setState(() => _isBooking = false);

    final messenger = ScaffoldMessenger.of(context);
    switch (result.outcome) {
      case BookingOutcome.success:
        messenger.showSnackBar(
          const SnackBar(content: Text('Gig booked!')),
        );
      case BookingOutcome.alreadyBooked:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Sorry, this gig was just booked by someone else.',
            ),
          ),
        );
        widget.requestsService.fetchOpenRequests();
      case BookingOutcome.failure:
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not book this gig. Please try again.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.request.notes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.request.origin} → ${widget.request.destination}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(_formatDate(widget.request.moveDate)),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _isBooking ? null : _handleBookPressed,
                child: _isBooking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Book'),
              ),
            ),
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
