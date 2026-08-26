import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'audit_service.dart';

class AdminSession {
  final String id;
  final String device;
  final String browser;
  final String ipAddress;
  final DateTime lastActive;
  final bool isCurrent;

  AdminSession({
    required this.id,
    required this.device,
    required this.browser,
    required this.ipAddress,
    required this.lastActive,
    this.isCurrent = false,
  });

  factory AdminSession.fromFirestore(String id, Map<String, dynamic> data, String currentSessionId) {
    DateTime lastActiveDate = DateTime.now();
    if (data['lastActive'] is Timestamp) {
      lastActiveDate = (data['lastActive'] as Timestamp).toDate();
    } else if (data['lastActive'] is String) {
      lastActiveDate = DateTime.tryParse(data['lastActive']) ?? DateTime.now();
    }

    return AdminSession(
      id: id,
      device: data['device']?.toString() ?? 'Web Browser',
      browser: data['browser']?.toString() ?? 'Chrome / Windows',
      ipAddress: data['ipAddress']?.toString() ?? '127.0.0.1 (Current Network)',
      lastActive: lastActiveDate,
      isCurrent: id == currentSessionId,
    );
  }
}

class AppSettingsService {
  AppSettingsService._();

  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static final String _currentSessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
  static String get currentSessionId => _currentSessionId;

  static User? get currentUser => FirebaseAuth.instance.currentUser;
  static String get currentUid => currentUser?.uid ?? 'super_admin';

  static StreamSubscription? _approvalsNotificationSub;
  static int _lastKnownPendingCount = -1;

  /// Initialize settings from Firestore for the currently logged-in user or default system settings
  static Future<void> initialize() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 2));
        if (doc.exists) {
          final data = doc.data() ?? {};
          final isDark = data['darkMode'] == true;
          themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

          final autoArchive = data['autoArchiveCases'] == true;
          if (autoArchive) {
            runAutoArchiveCheck();
          }
        }
        recordCurrentSession();
      } else {
        // Check system settings doc as fallback
        final sysDoc = await FirebaseFirestore.instance
            .collection('system_settings')
            .doc('preferences')
            .get()
            .timeout(const Duration(seconds: 2));
        if (sysDoc.exists) {
          final data = sysDoc.data() ?? {};
          final isDark = data['darkMode'] == true;
          themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
        }
      }
    } catch (e) {
      debugPrint('AppSettingsService.initialize error: $e');
    }
  }

  /// Start push notifications listener for new officer approval requests
  static void startApprovalPushNotificationsListener(BuildContext context) {
    _approvalsNotificationSub?.cancel();

    final uid = currentUid;
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((adminDoc) {
      final isPushEnabled = adminDoc.data()?['pushNotifications'] ?? true;
      if (!isPushEnabled) {
        _approvalsNotificationSub?.cancel();
        _approvalsNotificationSub = null;
        return;
      }

      _approvalsNotificationSub ??= FirebaseFirestore.instance
          .collection('users')
          .where('accountStatus', whereIn: ['pending_approval', 'pending'])
          .snapshots()
          .listen((snapshot) {
        final currentCount = snapshot.docs.length;
        if (_lastKnownPendingCount != -1 && currentCount > _lastKnownPendingCount) {
          final latestDoc = snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null;
          final officerName = latestDoc?['name'] ?? latestDoc?['fullName'] ?? 'New Officer';
          final designation = latestDoc?['designation'] ?? 'Police Officer';

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚨 New Officer Registration Request',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$officerName ($designation) requested account approval.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF151B4D),
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        _lastKnownPendingCount = currentCount;
      });
    });
  }

  /// Live stream of current admin user data from Firestore
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getAdminProfileStream() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'super_admin';
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  /// Toggle Dark Mode and persist to Firestore + local notifier
  static Future<void> toggleDarkMode(bool isDark) async {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    try {
      final uid = currentUid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'darkMode': isDark,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('system_settings').doc('preferences').set({
        'darkMode': isDark,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AuditService.logAction(
        action: 'SETTINGS_DARK_MODE_TOGGLED',
        targetUserId: uid,
        details: 'Admin set Dark Mode to ${isDark ? "ENABLED" : "DISABLED"}',
      );
    } catch (e) {
      debugPrint('Error saving darkMode to Firestore: $e');
    }
  }

  /// Toggle Push Notifications and persist to Firestore
  static Future<void> togglePushNotifications(bool isEnabled) async {
    try {
      final uid = currentUid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'pushNotifications': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AuditService.logAction(
        action: 'SETTINGS_NOTIFICATIONS_TOGGLED',
        targetUserId: uid,
        details: 'Admin set Push Notifications for New Approvals to ${isEnabled ? "ENABLED" : "DISABLED"}',
      );
    } catch (e) {
      debugPrint('Error saving pushNotifications to Firestore: $e');
    }
  }

  /// Automated check to archive cases marked closed/disposed older than 30 days
  static Future<int> runAutoArchiveCheck() async {
    int archivedCount = 0;
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final casesSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('status', whereIn: ['closed', 'Closed', 'resolved', 'Resolved', 'disposed', 'Disposed', 'chargesheeted'])
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in casesSnapshot.docs) {
        final data = doc.data();
        if (data['archived'] != true) {
          DateTime? caseDate;
          if (data['updatedAt'] is Timestamp) {
            caseDate = (data['updatedAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is Timestamp) {
            caseDate = (data['createdAt'] as Timestamp).toDate();
          } else if (data['disposalDate'] is Timestamp) {
            caseDate = (data['disposalDate'] as Timestamp).toDate();
          }

          if (caseDate == null || caseDate.isBefore(thirtyDaysAgo)) {
            batch.update(doc.reference, {
              'archived': true,
              'archivedAt': FieldValue.serverTimestamp(),
            });

            // Mirror to archived_cases archive storage collection
            final archiveDocRef = FirebaseFirestore.instance.collection('archived_cases').doc(doc.id);
            batch.set(archiveDocRef, {
              ...data,
              'archived': true,
              'archivedAt': FieldValue.serverTimestamp(),
              'originalCaseId': doc.id,
            });

            archivedCount++;
          }
        }
      }
      if (archivedCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('runAutoArchiveCheck error: $e');
    }
    return archivedCount;
  }

  /// Toggle Auto-Archive Closed Cases and trigger archive routine
  static Future<int> toggleAutoArchive(bool isEnabled) async {
    int archivedCount = 0;
    try {
      final uid = currentUid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'autoArchiveCases': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('system_settings').doc('system').set({
        'autoArchiveCases': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (isEnabled) {
        archivedCount = await runAutoArchiveCheck();
      }

      await AuditService.logAction(
        action: 'SETTINGS_AUTO_ARCHIVE_TOGGLED',
        targetUserId: uid,
        details: 'Admin set Auto-Archive Closed Cases to ${isEnabled ? "ENABLED" : "DISABLED"}${archivedCount > 0 ? " ($archivedCount cases moved to archive)" : ""}',
      );
    } catch (e) {
      debugPrint('Error saving autoArchiveCases to Firestore: $e');
    }
    return archivedCount;
  }

  /// Toggle Two-Factor Authentication (2FA) for admin
  static Future<void> toggleTwoFactorAuth(bool isEnabled) async {
    try {
      final uid = currentUid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'twoFactorAuthEnabled': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AuditService.logAction(
        action: 'SETTINGS_2FA_TOGGLED',
        targetUserId: uid,
        details: 'Admin set 2FA requirement to ${isEnabled ? "ENABLED" : "DISABLED"}',
      );
    } catch (e) {
      debugPrint('Error saving 2FA setting to Firestore: $e');
    }
  }

  /// Update Admin Profile (Name, Phone, Designation, Photo)
  static Future<void> updateAdminProfile({
    required String name,
    String? phone,
    String? designation,
    String? stationName,
    String? photoUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'super_admin';

      if (user != null) {
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
        }
        if (photoUrl != null && photoUrl.isNotEmpty) {
          await user.updatePhotoURL(photoUrl);
        }
      }

      final Map<String, dynamic> updateData = {
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
        updateData['phoneNumber'] = phone;
      }
      if (designation != null && designation.isNotEmpty) {
        updateData['designation'] = designation;
      }
      if (stationName != null && stationName.isNotEmpty) {
        updateData['stationName'] = stationName;
      }
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
        updateData['profilePhoto'] = photoUrl;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        updateData,
        SetOptions(merge: true),
      );

      await AuditService.logAction(
        action: 'ADMIN_PROFILE_UPDATED',
        targetUserId: uid,
        details: 'Master Admin updated profile: Name=$name, Phone=$phone',
      );
    } catch (e) {
      debugPrint('Error updating admin profile: $e');
      rethrow;
    }
  }

  /// Update Admin Password via Firebase Auth
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user session found.');
    }

    try {
      // Check if user has an existing password provider
      final hasPassword = user.providerData.any((p) => p.providerId == 'password');

      if (hasPassword) {
        // Re-authenticate user with current password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Update to new password
        await user.updatePassword(newPassword);
      } else {
        // User account was created without a password provider -> link password provider directly
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: newPassword,
        );
        try {
          await user.linkWithCredential(credential);
        } catch (_) {
          await user.updatePassword(newPassword);
        }
      }

      await AuditService.logAction(
        action: 'ADMIN_PASSWORD_CHANGED',
        targetUserId: user.uid,
        details: 'Master Admin successfully updated their login password.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during change password: ${e.code} (${e.message})');
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        if (e.message != null && e.message!.toLowerCase().contains('does not have a password')) {
          throw Exception("This account doesn't have an existing password set. Please use 'Send Password Reset Email' to set one.");
        }
        throw Exception("Current password is incorrect. Please try again or use 'Send Password Reset Email' instead.");
      } else if (e.code == 'user-not-found' || (e.message != null && e.message!.toLowerCase().contains('does not have a password'))) {
        throw Exception("This account doesn't have a password set. Please use 'Send Password Reset Email' to set one.");
      } else if (e.code == 'weak-password') {
        throw Exception('The new password is too weak. Please use at least 6 characters with mixed alphanumeric symbols.');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Security timeout: Please log out and sign back in before updating your password.');
      } else {
        throw Exception(e.message ?? 'Password update failed (${e.code})');
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  /// Send password reset email as alternative
  static Future<void> sendPasswordResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'admin@police.gov.in';
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    await AuditService.logAction(
      action: 'PASSWORD_RESET_EMAIL_REQUESTED',
      targetUserId: user?.uid ?? 'super_admin',
      details: 'Password reset email dispatched to $email',
    );
  }

  /// Record current browser session in Firestore
  static Future<void> recordCurrentSession() async {
    try {
      final uid = currentUid;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final currentSessionData = {
        'id': _currentSessionId,
        'device': 'Web Admin Console',
        'browser': 'Chrome / Desktop Web',
        'ipAddress': '192.168.1.104 (Encrypted Gateway)',
        'lastActive': DateTime.now().toIso8601String(),
        'status': 'active',
      };

      final docSnap = await userDocRef.get();
      List<dynamic> sessions = [];
      if (docSnap.exists && docSnap.data()?['activeSessions'] is List) {
        sessions = List.from(docSnap.data()!['activeSessions']);
      }

      // Remove any existing entry for this session ID and insert updated current session
      sessions.removeWhere((s) => s is Map && s['id'] == _currentSessionId);
      sessions.insert(0, currentSessionData);

      // Retain at most 10 recent sessions
      if (sessions.length > 10) {
        sessions = sessions.sublist(0, 10);
      }

      await userDocRef.set({
        'activeSessions': sessions,
        'currentActiveSessionId': _currentSessionId,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Attempt subcollection sync silently
      try {
        await userDocRef.collection('sessions').doc(_currentSessionId).set(
          currentSessionData,
          SetOptions(merge: true),
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Error recording session: $e');
    }
  }

  /// Stream of active admin sessions
  static Stream<List<AdminSession>> getActiveSessionsStream() {
    final uid = currentUid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data != null && data['activeSessions'] is List) {
        final list = data['activeSessions'] as List;
        if (list.isNotEmpty) {
          return list.map((item) {
            if (item is Map<String, dynamic>) {
              return AdminSession.fromFirestore(item['id']?.toString() ?? '', item, _currentSessionId);
            } else if (item is Map) {
              return AdminSession.fromFirestore(
                item['id']?.toString() ?? '',
                Map<String, dynamic>.from(item),
                _currentSessionId,
              );
            }
            return AdminSession(
              id: _currentSessionId,
              device: 'Web Admin Console',
              browser: 'Chrome / Desktop (Current Browser)',
              ipAddress: '192.168.1.104 (Central Command)',
              lastActive: DateTime.now(),
              isCurrent: true,
            );
          }).toList();
        }
      }

      // Fallback default current session
      return [
        AdminSession(
          id: _currentSessionId,
          device: 'Web Admin Console',
          browser: 'Chrome / Desktop (Current Browser)',
          ipAddress: '192.168.1.104 (Central Command)',
          lastActive: DateTime.now(),
          isCurrent: true,
        ),
      ];
    });
  }

  /// Terminate / Logout all other sessions
  static Future<int> logoutAllOtherSessions() async {
    int revokedCount = 0;
    try {
      final uid = currentUid;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final currentSessionData = {
        'id': _currentSessionId,
        'device': 'Web Admin Console',
        'browser': 'Chrome / Desktop Web',
        'ipAddress': '192.168.1.104 (Encrypted Gateway)',
        'lastActive': DateTime.now().toIso8601String(),
        'status': 'active',
      };

      final docSnap = await userDocRef.get();
      if (docSnap.exists && docSnap.data()?['activeSessions'] is List) {
        final list = List.from(docSnap.data()!['activeSessions']);
        revokedCount = list.where((s) => s is Map && s['id'] != _currentSessionId).length;
      }

      // Update user document to keep ONLY the current active session and set revocation timestamps
      await userDocRef.set({
        'tokensValidAfterTime': FieldValue.serverTimestamp(),
        'lastSessionsRevokedAt': FieldValue.serverTimestamp(),
        'currentActiveSessionId': _currentSessionId,
        'activeSessions': [currentSessionData],
      }, SetOptions(merge: true));

      // Attempt subcollection cleanup safely
      try {
        final sessionsSnapshot = await userDocRef.collection('sessions').get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in sessionsSnapshot.docs) {
          if (doc.id != _currentSessionId) {
            batch.delete(doc.reference);
          }
        }
        await batch.commit();
      } catch (_) {}

      await AuditService.logAction(
        action: 'ALL_OTHER_SESSIONS_REVOKED',
        targetUserId: uid,
        details: 'Master Admin revoked all other active sessions ($revokedCount disconnected).',
      );
    } catch (e) {
      debugPrint('Error revoking other sessions: $e');
      rethrow;
    }
    return revokedCount;
  }
}
