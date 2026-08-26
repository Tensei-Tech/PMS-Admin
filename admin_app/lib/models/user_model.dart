// lib/models/user_model.dart
// Domain 1 (PIN Hardening): removed plaintext `pin` field.
// Domain 3 (RBAC): added `role` field — defaults to 'officer'.
// PIN hash/salt are NEVER stored in UserModel; they live only in flutter_secure_storage.

/// Lifecycle states for officer accounts.
class UserAccountStatus {
  UserAccountStatus._();

  static const String active = 'active';
  static const String archived = 'archived';
  static const String pendingApproval = 'pending_approval';
  static const String pending = 'pending';
  static const String rejected = 'rejected';
}

class UserModel {
  final String uid;
  final String name;
  final String badgeNumber;
  final String designation;
  final String email;
  final String phone;
  final String stationName;
  final String stationAddress;
  final String stationLandline;
  final String govtId;
  final String photoUrl;
  final String? idCardUrl;
  final String role; // 'officer' | 'supervisor' | 'admin' — set by admin only
  final List<String> additionalStations; // Extra stations added by CP-level officers
  /// `active` (default) | `archived` | `pending_approval` | `rejected`
  final String accountStatus;
  /// District / commissionerate name (structured; backfilled from stationAddress).
  final String? district;
  /// When true, junior ranks may view full station case dashboard (PI/API grant).
  final bool stationCaseViewGranted;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.badgeNumber,
    required this.designation,
    required this.email,
    required this.phone,
    required this.stationName,
    required this.stationAddress,
    required this.stationLandline,
    required this.govtId,
    this.photoUrl = '',
    this.idCardUrl,
    this.role = 'officer', // Default: least-privilege on registration
    this.additionalStations = const [],
    this.accountStatus = UserAccountStatus.active,
    this.district,
    this.stationCaseViewGranted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'badgeNumber': badgeNumber,
      'designation': designation,
      'email': email,
      'phone': phone,
      'stationName': stationName,
      'stationAddress': stationAddress,
      'stationLandline': stationLandline,
      'govtId': govtId,
      'photoUrl': photoUrl,
      if (idCardUrl != null && idCardUrl!.trim().isNotEmpty)
        'idCardUrl': idCardUrl,
      'role': role,
      'additionalStations': additionalStations,
      'district': district ?? '',
      'accountStatus': accountStatus,
      'status': accountStatus,
      if (stationCaseViewGranted) 'stationCaseViewGranted': true,
      // NOTE: PIN hash/salt are NEVER written to Firestore via this model.
      // They are managed exclusively in flutter_secure_storage by AuthProvider.
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      uid: docId ?? map['uid'] ?? '',
      name: map['name'] ?? map['fullName'] ?? map['displayName'] ?? '',
      badgeNumber: map['badgeNumber'] ?? map['badge_number'] ?? map['badgeNo'] ?? '',
      designation: map['designation'] ?? map['rank'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['phoneNumber'] ?? '',
      stationName: map['stationName'] ?? map['station'] ?? map['assignedStation'] ?? '',
      stationAddress: map['stationAddress'] ?? '',
      stationLandline: map['stationLandline'] ?? '',
      govtId: map['govtId'] ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['photoURL'] as String? ?? map['avatar'] as String? ?? '',
      idCardUrl: map['idCardUrl'] as String?,
      role: map['role'] ?? 'officer',
      additionalStations: (map['additionalStations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      accountStatus:
          map['accountStatus'] as String? ?? map['status'] as String? ?? UserAccountStatus.active,
      district: map['district'] as String?,
      stationCaseViewGranted: map['stationCaseViewGranted'] == true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
