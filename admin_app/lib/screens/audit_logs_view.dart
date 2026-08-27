import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm:$ss';
    } else if (ts is String) {
      final dt = DateTime.tryParse(ts);
      if (dt != null) {
        final y = dt.year;
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        final ss = dt.second.toString().padLeft(2, '0');
        return '$y-$m-$d $hh:$mm:$ss';
      }
    }
    return 'Just now';
  }

  String _resolveUserName({
    required Map<String, dynamic> logData,
    required Map<String, Map<String, dynamic>> usersMap,
  }) {
    final adminUid = (logData['adminUid'] ?? logData['userId'] ?? '').toString().trim();
    final targetUserId = (logData['targetUserId'] ?? '').toString().trim();
    final details = (logData['details'] ?? '').toString();

    // 1. Direct Lookup by adminUid in Firestore Users map
    if (adminUid.isNotEmpty && usersMap.containsKey(adminUid)) {
      final userDoc = usersMap[adminUid]!;
      final name = (userDoc['name'] ?? userDoc['fullName'])?.toString().trim();
      if (name != null && name.isNotEmpty && name != 'super_admin') {
        return name;
      }
      final email = userDoc['email']?.toString().trim();
      if (email != null && email.isNotEmpty) {
        if (email == 'master.admin@pms.gov.in' || email == 'admin@police.gov.in') return 'Master Admin';
        return email;
      }
    }

    // 2. Direct Lookup by targetUserId in Firestore Users map
    if (targetUserId.isNotEmpty && usersMap.containsKey(targetUserId)) {
      final userDoc = usersMap[targetUserId]!;
      final name = (userDoc['name'] ?? userDoc['fullName'])?.toString().trim();
      if (name != null && name.isNotEmpty && name != 'super_admin') {
        return name;
      }
      final email = userDoc['email']?.toString().trim();
      if (email != null && email.isNotEmpty) {
        if (email == 'master.admin@pms.gov.in' || email == 'admin@police.gov.in') return 'Master Admin';
        return email;
      }
    }

    // 3. Check if details contain email or admin references
    if (details.contains('master.admin@pms.gov.in') || details.contains('admin@police.gov.in') || details.toLowerCase().contains('master admin')) {
      // Find admin user document if exists in map
      for (final u in usersMap.values) {
        if (u['email'] == 'master.admin@pms.gov.in' || u['email'] == 'admin@police.gov.in' || u['role'] == 'super_admin') {
          final adminName = (u['name'] ?? u['fullName'])?.toString().trim();
          if (adminName != null && adminName.isNotEmpty && adminName != 'super_admin') {
            return adminName;
          }
        }
      }
      return 'Master Admin';
    }

    // 4. Extract any email inside details to match against users
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final match = emailRegex.firstMatch(details);
    if (match != null) {
      final extractedEmail = match.group(0)!.toLowerCase();
      for (final u in usersMap.values) {
        if ((u['email'] ?? '').toString().toLowerCase() == extractedEmail) {
          final name = (u['name'] ?? u['fullName'])?.toString().trim();
          if (name != null && name.isNotEmpty) return name;
        }
      }
      if (extractedEmail == 'master.admin@pms.gov.in' || extractedEmail == 'admin@police.gov.in') return 'Master Admin';
      return extractedEmail;
    }

    // 5. Fallback if adminUid is super_admin / admin
    if (adminUid == 'super_admin' || adminUid == 'admin') {
      return 'Master Admin';
    }

    return 'Unknown User';
  }

  Widget _buildActionBadge(String action) {
    Color bg;
    Color fg;
    Color border;

    final upper = action.toUpperCase();
    if (upper.contains('2FA') || upper.contains('APPROVED') || upper.contains('RESTORED') || upper.contains('SUCCESS')) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      border = const Color(0xFFA7F3D0);
    } else if (upper.contains('REJECTED') || upper.contains('ARCHIVED') || upper.contains('FAILED') || upper.contains('ERROR')) {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
      border = const Color(0xFFFECACA);
    } else if (upper.contains('EDITED') || upper.contains('UPDATE') || upper.contains('AUTH')) {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1D4ED8);
      border = const Color(0xFFBFDBFE);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      border = const Color(0xFFCBD5E1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        upper,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildUserCell(String userName) {
    final initials = userName.trim().isNotEmpty
        ? userName.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase()).take(2).join()
        : 'U';

    final isMasterAdmin = userName == 'Master Admin';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: isMasterAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          child: Text(
            initials.isNotEmpty ? initials : 'U',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
              color: isMasterAdmin ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          userName,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Admin Activity Log',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: Color(0xFF1D4ED8)),
                        SizedBox(width: 5),
                        Text(
                          'Audit Trail',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-time immutable stream of administrative actions, officer approvals, and security events',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 18),

          // Search Bar
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by action, details, user name...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Main Responsive Content Area with Live Users & Audit Logs
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                final usersMap = <String, Map<String, dynamic>>{};
                if (usersSnapshot.hasData) {
                  for (final uDoc in usersSnapshot.data!.docs) {
                    usersMap[uDoc.id] = uDoc.data();
                  }
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('audit_logs')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading audit logs: ${snapshot.error}',
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                        ),
                      );
                    }

                    final allDocs = snapshot.data?.docs ?? [];

                    // Filter logs
                    final filteredDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final action = (data['action'] ?? '').toString().toUpperCase();
                      final details = (data['details'] ?? '').toString().toLowerCase();
                      final resolvedUser = _resolveUserName(logData: data, usersMap: usersMap).toLowerCase();

                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        if (!action.toLowerCase().contains(query) &&
                            !details.contains(query) &&
                            !resolvedUser.contains(query)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_toggle_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No audit logs match your search',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try clearing filters or checking back later as new admin actions occur.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 960;

                        if (isDesktop) {
                          return _buildDesktopTable(filteredDocs, usersMap);
                        } else {
                          return _buildMobileCardList(filteredDocs, usersMap);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🖥️ Desktop Full-Width Data Table: Columns = Action, Details, User
  Widget _buildDesktopTable(List<QueryDocumentSnapshot> docs, Map<String, Map<String, dynamic>> usersMap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 32,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 70,
                    columns: const [
                      DataColumn(
                        label: Text('Action', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155))),
                      ),
                      DataColumn(
                        label: Text('Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155))),
                      ),
                      DataColumn(
                        label: Text('User', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155))),
                      ),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = _formatTimestamp(data['timestamp']);
                      final action = (data['action'] ?? 'UNKNOWN').toString();
                      final details = (data['details'] ?? '').toString();
                      final userName = _resolveUserName(logData: data, usersMap: usersMap);

                      return DataRow(
                        cells: [
                          DataCell(_buildActionBadge(action)),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  details,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  timestamp,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          DataCell(_buildUserCell(userName)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 📱 Tablet & Mobile Responsive Card List
  Widget _buildMobileCardList(List<QueryDocumentSnapshot> docs, Map<String, Map<String, dynamic>> usersMap) {
    return ListView.separated(
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final timestamp = _formatTimestamp(data['timestamp']);
        final action = (data['action'] ?? 'UNKNOWN').toString();
        final details = (data['details'] ?? '').toString();
        final userName = _resolveUserName(logData: data, usersMap: usersMap);

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Action Badge + Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionBadge(action),
                    Text(
                      timestamp,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  details,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Footer row: User Name
                Row(
                  children: [
                    const Text('User: ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    const SizedBox(width: 4),
                    _buildUserCell(userName),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
