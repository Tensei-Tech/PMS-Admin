// lib/utils/case_utils.dart

/// Central utility for consistent case status and chargesheet / CC number evaluation across PMS Admin Console.
class CaseUtils {
  CaseUtils._();

  /// Determines if a case is DISPOSED based on the presence of a Chargesheet Number or CC Number.
  /// - A case is "DISPOSED" if a chargesheet number or CC number has been assigned.
  /// - A case is "PENDING" if neither is assigned (awaiting chargesheet / CC number).
  static bool isDisposed(Map<String, dynamic> data) {
    // 1. Direct chargesheet fields
    final csNum = data['chargesheetNumber'] ??
        data['chargeSheetNumber'] ??
        data['chargesheetNo'] ??
        data['chargesheet_number'] ??
        data['chargesheet'];
    if (_isValidNumber(csNum)) {
      return true;
    }

    // 2. Direct CC (Court Case / Case Closing) fields
    final ccNum = data['ccNumber'] ??
        data['ccNo'] ??
        data['courtCaseNumber'] ??
        data['courtCaseNo'] ??
        data['caseClosingNumber'] ??
        data['cc_number'];
    if (_isValidNumber(ccNum)) {
      return true;
    }

    // 3. Nested court map
    if (data['court'] is Map) {
      final court = data['court'] as Map;
      final courtCs = court['chargeSheetNumber'] ?? court['chargesheetNumber'] ?? court['chargesheetNo'];
      if (_isValidNumber(courtCs)) {
        return true;
      }
      final courtCc = court['ccNumber'] ?? court['ccNo'] ?? court['courtCaseNumber'];
      if (_isValidNumber(courtCc)) {
        return true;
      }
    }

    // 4. Final report chargeSheeted field
    final csed = data['chargeSheeted'];
    if (_isValidNumber(csed) &&
        csed.toString().trim().toLowerCase() != 'no' &&
        csed.toString().trim().toLowerCase() != 'false') {
      return true;
    }

    // 5. Explicit status fallback (if marked chargesheeted/disposed)
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    if (status == 'chargesheet filed' ||
        status == 'chargesheeted' ||
        status == 'disposed' ||
        status == 'closed' ||
        status == 'resolved') {
      return true;
    }

    if (data['isDisposed'] == true) {
      return true;
    }

    return false;
  }

  /// Determines if a case is PENDING (not yet chargesheeted / no CC number assigned).
  static bool isPending(Map<String, dynamic> data) => !isDisposed(data);

  /// Returns user-facing status label: 'Disposed' or 'Pending'.
  static String getStatusLabel(Map<String, dynamic> data) {
    return isDisposed(data) ? 'Disposed' : 'Pending';
  }

  /// Returns the chargesheet number, CC number, or formatted fallback identifier.
  static String? getChargesheetOrCcNumber(Map<String, dynamic> data, String docId) {
    if (!isDisposed(data)) return null;

    final csNum = data['chargesheetNumber'] ??
        data['chargeSheetNumber'] ??
        data['chargesheetNo'] ??
        data['chargesheet_number'];
    if (_isValidNumber(csNum)) {
      return csNum.toString().trim();
    }

    final ccNum = data['ccNumber'] ?? data['ccNo'] ?? data['courtCaseNumber'];
    if (_isValidNumber(ccNum)) {
      return 'CC: ${ccNum.toString().trim()}';
    }

    if (data['court'] is Map) {
      final court = data['court'] as Map;
      final courtCs = court['chargeSheetNumber'] ?? court['chargesheetNumber'];
      if (_isValidNumber(courtCs)) {
        return courtCs.toString().trim();
      }
      final courtCc = court['ccNumber'] ?? court['courtCaseNumber'];
      if (_isValidNumber(courtCc)) {
        return 'CC: ${courtCc.toString().trim()}';
      }
    }

    final fallback = docId.length >= 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();
    return 'CS-$fallback';
  }

  static bool _isValidNumber(dynamic val) {
    if (val == null) return false;
    final s = val.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'N/A' || s == 'None' || s == '—') {
      return false;
    }
    return true;
  }
}
