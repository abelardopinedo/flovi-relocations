import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/relocation_request.dart';
import 'auth_service.dart';
import 'supabase_client.dart';

const _table = 'relocation_requests';
const _openStatus = 'open';
const _bookedStatus = 'booked';

enum BookingOutcome { success, alreadyBooked, failure }

/// Result of a [RequestsService.bookRequest] attempt.
class BookingResult {
  const BookingResult._(this.outcome, [this.error]);

  const BookingResult.success() : this._(BookingOutcome.success);

  const BookingResult.alreadyBooked() : this._(BookingOutcome.alreadyBooked);

  const BookingResult.failure(Object error) : this._(BookingOutcome.failure, error);

  final BookingOutcome outcome;
  final Object? error;
}

/// Keeps an up-to-date list of open (unbooked) relocation requests, backed
/// by an initial fetch plus a Realtime subscription. Notifies listeners
/// whenever [openRequests], [isLoading], or [error] changes.
class RequestsService extends ChangeNotifier {
  RequestsService() {
    _subscribeToChanges();
    fetchOpenRequests();
  }

  final Map<String, RelocationRequest> _openRequestsById = {};
  RealtimeChannel? _channel;

  bool isLoading = true;
  Object? error;

  List<RelocationRequest> get openRequests {
    final requests = _openRequestsById.values.toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  Future<void> fetchOpenRequests() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final rows = await supabase
          .from(_table)
          .select()
          .eq('status', _openStatus)
          .order('created_at', ascending: false);

      _openRequestsById
        ..clear()
        ..addEntries(
          rows
              .map((row) => RelocationRequest.fromJson(row))
              .map((request) => MapEntry(request.id, request)),
        );
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Books [requestId] for the current driver, but only if it is still
  /// 'open' at the time the update reaches the database. The `.eq('status',
  /// 'open')` condition makes this atomic: if another driver booked it a
  /// moment earlier, this update matches 0 rows instead of overwriting theirs.
  Future<BookingResult> bookRequest(String requestId) async {
    final driverId = AuthService.instance.currentUser?.id;
    if (driverId == null) {
      return const BookingResult.failure('Not signed in');
    }

    try {
      final updated = await supabase
          .from(_table)
          .update({
            'driver_id': driverId,
            'status': _bookedStatus,
          })
          .eq('id', requestId)
          .eq('status', _openStatus)
          .select();

      if (updated.isEmpty) {
        return const BookingResult.alreadyBooked();
      }

      _openRequestsById.remove(requestId);
      notifyListeners();
      return const BookingResult.success();
    } catch (e) {
      return BookingResult.failure(e);
    }
  }

  void _subscribeToChanges() {
    _channel = supabase
        .channel('public:$_table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          callback: _handleChange,
        )
        .subscribe();
  }

  void _handleChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        final request = RelocationRequest.fromJson(payload.newRecord);
        if (request.status == _openStatus) {
          _openRequestsById[request.id] = request;
        } else {
          _openRequestsById.remove(request.id);
        }
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _openRequestsById.remove(id);
        }
      case PostgresChangeEvent.all:
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      supabase.removeChannel(channel);
    }
    super.dispose();
  }
}
