// lib/models/transfer_request_model.dart
// Transfer request documents for officer posting changes (Phase 2).

class TransferRequestStatus {
  TransferRequestStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  /// Statuses that block submitting a new request.
  static const List<String> activeBlocking = [
    pending,
  ];
}

class TransferRequest {
  const TransferRequest({
    required this.id,
    required this.requestedByUid,
    required this.requestedByEmail,
    required this.requestedByName,
    required this.fromStationName,
    required this.fromDesignation,
    required this.fromUnitType,
    required this.fromState,
    required this.fromDistrict,
    required this.toStationName,
    required this.toDesignation,
    required this.toUnitType,
    required this.toState,
    required this.toDistrict,
    required this.status,
    this.requesterNote = '',
    this.approvedByUid,
    this.rejectedByUid,
    this.rejectionReason,
    this.approvedAt,
    this.rejectedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String requestedByUid;
  final String requestedByEmail;
  final String requestedByName;
  final String fromStationName;
  final String fromDesignation;
  final String fromUnitType;
  final String fromState;
  final String fromDistrict;
  final String toStationName;
  final String toDesignation;
  final String toUnitType;
  final String toState;
  final String toDistrict;
  final String status;
  final String requesterNote;
  final String? approvedByUid;
  final String? rejectedByUid;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive =>
      TransferRequestStatus.activeBlocking.contains(status);

  Map<String, dynamic> toMap() {
    return {
      'requestedByUid': requestedByUid,
      'requestedByEmail': requestedByEmail,
      'requestedByName': requestedByName,
      'fromStationName': fromStationName,
      'fromDesignation': fromDesignation,
      'fromUnitType': fromUnitType,
      'fromState': fromState,
      'fromDistrict': fromDistrict,
      'toStationName': toStationName,
      'toDesignation': toDesignation,
      'toUnitType': toUnitType,
      'toState': toState,
      'toDistrict': toDistrict,
      'status': status,
      if (requesterNote.isNotEmpty) 'requesterNote': requesterNote,
      if (approvedByUid != null) 'approvedByUid': approvedByUid,
      if (rejectedByUid != null) 'rejectedByUid': rejectedByUid,
      if (rejectionReason != null && rejectionReason!.isNotEmpty)
        'rejectionReason': rejectionReason,
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (rejectedAt != null) 'rejectedAt': rejectedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory TransferRequest.fromMap(Map<String, dynamic> map, String docId) {
    return TransferRequest(
      id: docId,
      requestedByUid: map['requestedByUid'] as String? ?? '',
      requestedByEmail: map['requestedByEmail'] as String? ?? '',
      requestedByName: map['requestedByName'] as String? ?? '',
      fromStationName: map['fromStationName'] as String? ?? '',
      fromDesignation: map['fromDesignation'] as String? ?? '',
      fromUnitType: map['fromUnitType'] as String? ?? '',
      fromState: map['fromState'] as String? ?? '',
      fromDistrict: map['fromDistrict'] as String? ?? '',
      toStationName: map['toStationName'] as String? ?? '',
      toDesignation: map['toDesignation'] as String? ?? '',
      toUnitType: map['toUnitType'] as String? ?? '',
      toState: map['toState'] as String? ?? '',
      toDistrict: map['toDistrict'] as String? ?? '',
      status: map['status'] as String? ?? TransferRequestStatus.pending,
      requesterNote: map['requesterNote'] as String? ?? '',
      approvedByUid: map['approvedByUid'] as String?,
      rejectedByUid: map['rejectedByUid'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      approvedAt: _parseTimestamp(map['approvedAt']),
      rejectedAt: _parseTimestamp(map['rejectedAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
