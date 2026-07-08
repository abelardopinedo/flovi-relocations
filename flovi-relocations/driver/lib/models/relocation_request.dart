class RelocationRequest {
  final String id;
  final String origin;
  final String destination;
  final DateTime moveDate;
  final String? notes;
  final String status;
  final String? dispatcherId;
  final String? driverId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RelocationRequest({
    required this.id,
    required this.origin,
    required this.destination,
    required this.moveDate,
    this.notes,
    required this.status,
    this.dispatcherId,
    this.driverId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RelocationRequest.fromJson(Map<String, dynamic> json) {
    return RelocationRequest(
      id: json['id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      moveDate: DateTime.parse(json['move_date'] as String),
      notes: json['notes'] as String?,
      status: json['status'] as String,
      dispatcherId: json['dispatcher_id'] as String?,
      driverId: json['driver_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'move_date': moveDate.toIso8601String().split('T').first,
      'notes': notes,
      'status': status,
      'dispatcher_id': dispatcherId,
      'driver_id': driverId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
