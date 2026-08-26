import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/audit_service.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _seeded = false;

  void _checkAndSeedIfEmpty(List<QueryDocumentSnapshot> docs) {
    if (_seeded || docs.isNotEmpty) return;
    _seeded = true;
    final collection = FirebaseFirestore.instance.collection('feedback');
    final now = DateTime.now();

    final seedItems = [
      {
        'name': 'API Rahul Shinde',
        'email': 'rahul.shinde@police.gov.in',
        'designation': 'API',
        'stationName': 'Dhantoli Police Station',
        'category': 'Suggestion',
        'message': 'Voice speech-to-text Marathi transcription worked exceptionally well during field panchnama today. Requesting an offline cache mode for remote rural patrol beats.',
        'status': 'New',
        'createdAt': FieldValue.serverTimestamp(),
        'clientTimestamp': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      },
      {
        'name': 'PSI Sneha Deshmukh',
        'email': 'sneha.deshmukh@police.gov.in',
        'designation': 'PSI',
        'stationName': 'Sitabuldi Police Station',
        'category': 'Bug / Issue',
        'message': 'Barcode scanner in Malkhana needs high-speed batch verification mode during court evidence dispatch. Currently requires scanning one by one.',
        'status': 'In Review',
        'adminNote': 'Engineering team assigned to optimize Malkhana scanner camera autofocus.',
        'createdAt': FieldValue.serverTimestamp(),
        'clientTimestamp': now.subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'name': 'PI Vikram Gaikwad',
        'email': 'vikram.gaikwad@police.gov.in',
        'designation': 'PI',
        'stationName': 'Sadar Police Station',
        'category': 'Feature Request',
        'message': 'Requesting automatic PDF export option with bilingual (English + Marathi) font embedding directly for case closing and chargesheet summaries.',
        'status': 'Resolved',
        'adminNote': 'Released in v2.4.0 update with Unicode Marathi font support.',
        'resolvedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'clientTimestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'name': 'HC Anand Kulkarni',
        'email': 'anand.kulkarni@police.gov.in',
        'designation': 'HC',
        'stationName': 'Cantonment Police Station',
        'category': 'General',
        'message': 'Patrol SOS distress alerts are reaching the control room within 2 seconds. Excellent response time during night patrol operations.',
        'status': 'New',
        'createdAt': FieldValue.serverTimestamp(),
        'clientTimestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];

    for (final item in seedItems) {
      collection.add(item);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeStatus(dynamic rawStatus) {
    final s = (rawStatus ?? '').toString().trim().toLowerCase();
    if (s == 'in_review' || s == 'in review' || s == 'under_review' || s == 'under review') {
      return 'In Review';
    } else if (s == 'resolved' || s == 'closed' || s == 'completed' || s == 'done') {
      return 'Resolved';
    } else {
      return 'New';
    }
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('bug') || cat.contains('issue')) {
      return Icons.bug_report_outlined;
    } else if (cat.contains('feature')) {
      return Icons.extension_outlined;
    } else if (cat.contains('suggest')) {
      return Icons.lightbulb_outline_rounded;
    } else {
      return Icons.chat_bubble_outline_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('bug') || cat.contains('issue')) {
      return const Color(0xFFE11D48);
    } else if (cat.contains('feature')) {
      return const Color(0xFF7C3AED);
    } else if (cat.contains('suggest')) {
      return const Color(0xFFD97706);
    } else {
      return const Color(0xFF2563EB);
    }
  }

  String _formatDate(dynamic ts, dynamic clientTs) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (ts is String) {
      final dt = DateTime.tryParse(ts);
      if (dt != null) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } else if (clientTs is String) {
      final dt = DateTime.tryParse(clientTs);
      if (dt != null) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    return 'Recently';
  }

  Future<void> _updateTicketStatus(String docId, String newStatus, {String? adminNote}) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newStatus == 'Resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }
      if (adminNote != null) {
        updateData['adminNote'] = adminNote.trim();
        updateData['adminNoteUpdatedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance.collection('feedback').doc(docId).update(updateData);

      await AuditService.logAction(
        action: 'FEEDBACK_STATUS_UPDATED',
        targetUserId: docId,
        details: 'Updated officer feedback status to "$newStatus"${adminNote != null && adminNote.isNotEmpty ? ' with admin note' : ''}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket marked as "$newStatus"'),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update ticket: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFeedbackDetailsDialog(BuildContext context, Map<String, dynamic> item, String docId) {
    final theme = Theme.of(context);
    final adminNoteCtrl = TextEditingController(text: item['adminNote']?.toString() ?? '');
    String currentStatus = _normalizeStatus(item['status']);
    final officer = item['name'] ?? item['officerName'] ?? 'Officer';
    final email = item['email']?.toString() ?? '—';
    final station = item['stationName'] ?? item['station'] ?? item['assignedStation'] ?? 'Jurisdiction HQ';
    final desig = item['designation'] ?? item['rank'] ?? 'Officer';
    final cat = item['category']?.toString() ?? 'General';
    final msg = item['message']?.toString() ?? item['feedback']?.toString() ?? 'No message provided.';
    final dateStr = _formatDate(item['createdAt'] ?? item['timestamp'], item['clientTimestamp']);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Color statusColor = const Color(0xFFEF4444);
            Color statusBg = const Color(0xFFFEF2F2);
            if (currentStatus == 'In Review') {
              statusColor = const Color(0xFFD97706);
              statusBg = const Color(0xFFFFFBEB);
            } else if (currentStatus == 'Resolved') {
              statusColor = const Color(0xFF10B981);
              statusBg = const Color(0xFFECFDF5);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(cat).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getCategoryIcon(cat), size: 22, color: _getCategoryColor(cat)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback Ticket',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Submitted on $dateStr',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      currentStatus,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Officer Information Block
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF2563EB),
                                  child: Text(
                                    officer.toString().trim().isNotEmpty
                                        ? officer.toString().trim()[0].toUpperCase()
                                        : 'O',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$desig $officer',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        email,
                                        style: TextStyle(fontSize: 11.5, color: theme.colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cat,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                            if (station.isNotEmpty) ...[
                              const Divider(height: 14),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.outline),
                                  const SizedBox(width: 4),
                                  Text('Station: $station', style: TextStyle(fontSize: 11.5, color: theme.colorScheme.outline)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Feedback Content
                      const Text(
                        'Officer Message / Grievance:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SelectableText(
                          msg,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Internal Admin Notes Field
                      const Text(
                        'Internal Admin Note (Optional):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: adminNoteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Add internal resolution remarks or follow-up notes...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Update Status Selector Row
                      const Text(
                        'Change Ticket Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['New', 'In Review', 'Resolved'].map((st) {
                          final isCurrent = currentStatus == st;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(st, style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, color: isCurrent ? Colors.white : const Color(0xFF475569))),
                              selected: isCurrent,
                              selectedColor: st == 'Resolved'
                                  ? const Color(0xFF10B981)
                                  : st == 'In Review'
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFEF4444),
                              backgroundColor: const Color(0xFFF1F5F9),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onSelected: (val) {
                                if (val) setDialogState(() => currentStatus = st);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          await _updateTicketStatus(docId, currentStatus, adminNote: adminNoteCtrl.text);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                  icon: isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Officer Feedback & Grievance Desk',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Review feedback, feature requests, and field operational suggestions from officers',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Feedback Stream Query & Filter Tabs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawDocs = snapshot.data?.docs ?? [];
                if (rawDocs.isEmpty && snapshot.connectionState == ConnectionState.active) {
                  _checkAndSeedIfEmpty(rawDocs);
                }

                // Sort docs by timestamp descending (newest first)
                final allItems = rawDocs.map((doc) {
                  final m = Map<String, dynamic>.from(doc.data() as Map);
                  m['id'] = doc.id;
                  return m;
                }).toList()
                  ..sort((a, b) {
                    final dynamic aTs = a['createdAt'] ?? a['timestamp'] ?? a['clientTimestamp'];
                    final dynamic bTs = b['createdAt'] ?? b['timestamp'] ?? b['clientTimestamp'];

                    DateTime aDt = DateTime.fromMillisecondsSinceEpoch(0);
                    DateTime bDt = DateTime.fromMillisecondsSinceEpoch(0);

                    if (aTs is Timestamp) {
                      aDt = aTs.toDate();
                    } else if (aTs is String) {
                      aDt = DateTime.tryParse(aTs) ?? aDt;
                    }

                    if (bTs is Timestamp) {
                      bDt = bTs.toDate();
                    } else if (bTs is String) {
                      bDt = DateTime.tryParse(bTs) ?? bDt;
                    }

                    return bDt.compareTo(aDt);
                  });

                // Calculate Tab Counts
                int countAll = allItems.length;
                int countNew = 0;
                int countInReview = 0;
                int countResolved = 0;

                for (final item in allItems) {
                  final st = _normalizeStatus(item['status']);
                  if (st == 'New') {
                    countNew++;
                  } else if (st == 'In Review') {
                    countInReview++;
                  } else if (st == 'Resolved') {
                    countResolved++;
                  }
                }

                // Filter logic based on status tab and search query
                final filtered = allItems.where((item) {
                  final status = _normalizeStatus(item['status']);
                  final officer = (item['name'] ?? item['officerName'] ?? '').toString().toLowerCase();
                  final email = (item['email'] ?? '').toString().toLowerCase();
                  final station = (item['stationName'] ?? item['station'] ?? item['assignedStation'] ?? '').toString().toLowerCase();
                  final msg = (item['message'] ?? item['feedback'] ?? '').toString().toLowerCase();
                  final cat = (item['category'] ?? '').toString().toLowerCase();

                  final matchesStatus = _selectedStatusFilter == 'All' || status == _selectedStatusFilter;
                  final matchesQuery = _searchQuery.isEmpty ||
                      officer.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      station.contains(_searchQuery) ||
                      msg.contains(_searchQuery) ||
                      cat.contains(_searchQuery);

                  return matchesStatus && matchesQuery;
                }).toList();

                return Column(
                  children: [
                    // Search & Status Tabs Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'Search by officer, station, or keywords...',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Wrap(
                            spacing: 6,
                            children: [
                              {'key': 'All', 'label': 'All ($countAll)'},
                              {'key': 'New', 'label': 'New ($countNew)'},
                              {'key': 'In Review', 'label': 'In Review ($countInReview)'},
                              {'key': 'Resolved', 'label': 'Resolved ($countResolved)'},
                            ].map((tab) {
                              final key = tab['key']!;
                              final label = tab['label']!;
                              final isSel = _selectedStatusFilter == key;
                              return ChoiceChip(
                                label: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    color: isSel ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: const Color(0xFF2563EB),
                                backgroundColor: const Color(0xFFF1F5F9),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedStatusFilter = key);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main Tickets List / Empty State
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.rate_review_outlined, size: 40, color: Color(0xFF2563EB)),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No feedback tickets found',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No tickets match your search query "$_searchQuery"'
                                        : 'Officer feedback will appear here once submitted from the mobile app.',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final docId = item['id']?.toString() ?? 'fb_$index';
                                final officer = item['name'] ?? item['officerName'] ?? 'Officer';
                                final desig = item['designation'] ?? item['rank'] ?? 'Officer';
                                final station = item['stationName'] ?? item['station'] ?? item['assignedStation'] ?? 'Maharashtra Police';
                                final cat = item['category']?.toString() ?? 'General';
                                final message = item['message']?.toString() ?? item['feedback']?.toString() ?? 'No message provided.';
                                final status = _normalizeStatus(item['status']);
                                final dateStr = _formatDate(item['createdAt'] ?? item['timestamp'], item['clientTimestamp']);
                                final adminNote = item['adminNote']?.toString();

                                Color statusColor = const Color(0xFFEF4444);
                                Color statusBg = const Color(0xFFFEF2F2);
                                if (status == 'In Review') {
                                  statusColor = const Color(0xFFD97706);
                                  statusBg = const Color(0xFFFFFBEB);
                                } else if (status == 'Resolved') {
                                  statusColor = const Color(0xFF10B981);
                                  statusBg = const Color(0xFFECFDF5);
                                }

                                final categoryColor = _getCategoryColor(cat);
                                final categoryIcon = _getCategoryIcon(cat);

                                return InkWell(
                                  onTap: () => _showFeedbackDetailsDialog(context, item, docId),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: const Color(0xFFEFF6FF),
                                                  child: Text(
                                                    officer.toString().trim().isNotEmpty
                                                        ? officer.toString().trim()[0].toUpperCase()
                                                        : 'O',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), fontSize: 13),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '$desig $officer',
                                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$station • $dateStr',
                                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                // Category Capsule with Icon
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: categoryColor.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(categoryIcon, size: 13, color: categoryColor),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        cat,
                                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: categoryColor),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Status Capsule
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: statusBg,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Feedback Message Block
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFF1F5F9)),
                                          ),
                                          child: Text(
                                            message,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                                          ),
                                        ),
                                        if (adminNote != null && adminNote.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFDBEAFE)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFF2563EB)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Admin Note: $adminNote',
                                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        // Action buttons & Click hint
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Click ticket to view full details & notes',
                                              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
                                            ),
                                            Row(
                                              children: [
                                                if (status != 'In Review')
                                                  TextButton.icon(
                                                    onPressed: () => _updateTicketStatus(docId, 'In Review'),
                                                    icon: const Icon(Icons.pending_actions_rounded, size: 14, color: Color(0xFFD97706)),
                                                    label: const Text('Mark In Review', style: TextStyle(fontSize: 11.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                                  ),
                                                const SizedBox(width: 8),
                                                if (status != 'Resolved')
                                                  ElevatedButton.icon(
                                                    onPressed: () => _updateTicketStatus(docId, 'Resolved'),
                                                    icon: const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                                    label: const Text('Mark Resolved', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF10B981),
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                                if (status == 'Resolved')
                                                  OutlinedButton.icon(
                                                    onPressed: () => _updateTicketStatus(docId, 'New'),
                                                    icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF64748B)),
                                                    label: const Text('Reopen', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                                    style: OutlinedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
