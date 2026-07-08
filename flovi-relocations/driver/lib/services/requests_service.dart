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

/// Keeps up-to-date lists of open (unbooked) and the current driver's booked
/// relocation requests, backed by an initial fetch plus a shared Realtime
/// subscription. Notifies listeners whenever either list, or their
/// loading/error state, changes. Meant to be shared by both the Browse and
/// My Gigs tabs so a booking made on one is instantly reflected on the other.
class RequestsService extends ChangeNotifier {
  RequestsService() {
    _subscribeToChanges();
    fetchOpenRequests();
    fetchMyBookedRequests();
  }

  final Map<String, RelocationRequest> _openRequestsById = {};
  final Map<String, RelocationRequest> _myBookedRequestsById = {};
  RealtimeChannel? _channel;

  bool isLoading = true;
  Object? error;

  bool isLoadingMyBookings = true;
  Object? myBookingsError;

  List<RelocationRequest> get openRequests {
    final requests = _openRequestsById.values.toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  List<RelocationRequest> get myBookedRequests {
    final requests = _myBookedRequestsById.values.toList();
    requests.sort((a, b) => a.moveDate.compareTo(b.moveDate));
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

  Future<void> fetchMyBookedRequests() async {
    final driverId = AuthService.instance.currentUser?.id;

    isLoadingMyBookings = true;
    myBookingsError = null;
    notifyListeners();

    try {
      if (driverId == null) {
        _myBookedRequestsById.clear();
        return;
      }

      final rows = await supabase
          .from(_table)
          .select()
          .eq('status', _bookedStatus)
          .eq('driver_id', driverId)
          .order('move_date', ascending: true);

      _myBookedRequestsById
        ..clear()
        ..addEntries(
          rows
              .map((row) => RelocationRequest.fromJson(row))
              .map((request) => MapEntry(request.id, request)),
        );
    } catch (e) {
      myBookingsError = e;
    } finally {
      isLoadingMyBookings = false;
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
      final booked = RelocationRequest.fromJson(updated.first);
      _myBookedRequestsById[booked.id] = booked;
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
        _applyToOpenRequests(request);
        _applyToMyBookedRequests(request);
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _openRequestsById.remove(id);
          _myBookedRequestsById.remove(id);
        }
      case PostgresChangeEvent.all:
        break;
    }
    notifyListeners();
  }

  void _applyToOpenRequests(RelocationRequest request) {
    if (request.status == _openStatus) {
      _openRequestsById[request.id] = request;
    } else {
      _openRequestsById.remove(request.id);
    }
  }

  void _applyToMyBookedRequests(RelocationRequest request) {
    final currentDriverId = AuthService.instance.currentUser?.id;
    final isMine =
        request.status == _bookedStatus && request.driverId == currentDriverId;

    if (isMine) {
      _myBookedRequestsById[request.id] = request;
    } else {
      _myBookedRequestsById.remove(request.id);
    }
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
