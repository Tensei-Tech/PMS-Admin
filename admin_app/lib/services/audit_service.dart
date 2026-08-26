import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  AuditService._();

  static Future<void> logAction({
    required String action,
    required String targetUserId,
    required String details,
  }) async {
    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'super_admin';

      await FirebaseFirestore.instance.collection('audit_logs').add({
        'adminUid': adminUid,
        'action': action.toUpperCase(),
        'targetUserId': targetUserId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-blocking log write failure
    }
  }
}
