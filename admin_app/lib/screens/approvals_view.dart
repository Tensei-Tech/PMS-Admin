import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../utils/app_constants.dart';

class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key});

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView> {
  final Set<String> _selectedUsers = {};
  bool _isProcessingBulk = false;
  int _tabIndex = 0; // 0: Pending, 1: Rejected

  Future<void> _approveUser(BuildContext context, String docId, String name) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({
        'accountStatus': 'active',
        'status': 'active',
      });

      await AuditService.logAction(
        action: 'APPROVED',
        targetUserId: docId,
        details: 'Approved registration for $name',
      );

      if (context.mounted) {
        setState(() {
          _selectedUsers.remove(docId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved registration for $name'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            width: 400,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectUser(BuildContext context, String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Registration'),
        content: Text('Are you sure you want to reject the registration for "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .update({
          'accountStatus': 'rejected',
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });

        await AuditService.logAction(
          action: 'REJECTED',
          targetUserId: docId,
          details: 'Rejected registration for $name',
        );

        if (context.mounted) {
          setState(() {
            _selectedUsers.remove(docId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rejected registration for $name'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              width: 400,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _bulkApproveUsers() async {
    if (_selectedUsers.isEmpty) return;

    setState(() {
      _isProcessingBulk = true;
    });

    final count = _selectedUsers.length;
    final userIdsToApprove = List<String>.from(_selectedUsers);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final docId in userIdsToApprove) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(docId);
        batch.update(docRef, {
          'accountStatus': 'active',
          'status': 'active',
        });
      }

      await batch.commit();

      for (final docId in userIdsToApprove) {
        await AuditService.logAction(
          action: 'APPROVED',
          targetUserId: docId,
          details: 'Bulk approved registration',
        );
      }

      if (mounted) {
        setState(() {
          _selectedUsers.clear();
          _isProcessingBulk = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully approved $count officer(s)!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            width: 400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingBulk = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk approval failed: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      final dt = dateValue.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } else if (dateValue is String && dateValue.isNotEmpty) {
      final dt = DateTime.tryParse(dateValue);
      if (dt != null) {
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      return dateValue;
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Bulk Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Officer Registration Approvals',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review, approve, or re-evaluate officer access requests in real-time',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  if (_tabIndex == 0 && _selectedUsers.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isProcessingBulk ? null : _bulkApproveUsers,
                      icon: _isProcessingBulk
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.done_all),
                      label: Text('Approve Selected (${_selectedUsers.length})'),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Segmented Tab for Pending vs Rejected
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('Pending Approvals'),
                    icon: Icon(Icons.pending_actions_outlined, size: 18),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('Rejected Registrations'),
                    icon: Icon(Icons.person_off_outlined, size: 18),
                  ),
                ],
                selected: {_tabIndex},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _tabIndex = newSelection.first;
                    _selectedUsers.clear();
                  });
                },
              ),
              const SizedBox(height: 20),

              // Main List Stream
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading data: ${snapshot.error}',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      );
                    }

                    final allDocs = snapshot.data?.docs ?? [];
                    final docs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _tabIndex == 0
                          ? AppConstants.isPendingApproval(data)
                          : AppConstants.isRejectedOfficer(data);
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _tabIndex == 0 ? Icons.verified_outlined : Icons.check_circle_outline,
                              size: 64,
                              color: theme.colorScheme.primary.withAlpha(150),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _tabIndex == 0 ? 'No pending approvals 🎉' : 'No rejected registrations',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tabIndex == 0
                                  ? 'All officer registration requests have been processed.'
                                  : 'No officer accounts have been rejected in the system.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final allDocIds = docs.map((d) => d.id).toSet();

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                            ),
                            showCheckboxColumn: _tabIndex == 0,
                            onSelectAll: _tabIndex == 0
                                ? (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedUsers.addAll(allDocIds);
                                      } else {
                                        _selectedUsers.removeAll(allDocIds);
                                      }
                                    });
                                  }
                                : null,
                            columns: [
                              const DataColumn(
                                label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Badge / Govt ID', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Designation / Rank', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Station', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text(_tabIndex == 0 ? 'Applied Date' : 'Rejected Date', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;
                              final isSelected = _selectedUsers.contains(docId);

                              final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? 'Unknown').toString();
                              final badgeRaw = (data['badgeNumber'] ?? data['badge_number'] ?? data['badgeNo'])?.toString() ?? '';
                              final govtIdRaw = (data['govtId'] ?? '').toString();
                              final badgeOrGovtId = badgeRaw.isNotEmpty
                                  ? badgeRaw
                                  : (govtIdRaw.isNotEmpty ? govtIdRaw : 'N/A');

                              final designation = (data['designation'] ?? data['rank'] ?? 'N/A').toString();
                              final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Unassigned').toString();
                              final dateStr = _tabIndex == 0
                                  ? _formatDate(data['createdAt'] ?? data['appliedDate'] ?? data['timestamp'])
                                  : _formatDate(data['rejectedAt'] ?? data['updatedAt'] ?? data['createdAt']);

                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: _tabIndex == 0
                                    ? (selected) {
                                        setState(() {
                                          if (selected == true) {
                                            _selectedUsers.add(docId);
                                          } else {
                                            _selectedUsers.remove(docId);
                                          }
                                        });
                                      }
                                    : null,
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: _tabIndex == 0
                                              ? theme.colorScheme.primaryContainer
                                              : Colors.red.shade100,
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: _tabIndex == 0
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : Colors.red.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(badgeOrGovtId)),
                                  DataCell(
                                    Chip(
                                      label: Text(designation),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  DataCell(Text(station)),
                                  DataCell(Text(dateStr)),
                                  DataCell(
                                    _tabIndex == 0
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                                tooltip: 'Approve',
                                                onPressed: () => _approveUser(context, docId, name),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                                tooltip: 'Reject',
                                                onPressed: () => _rejectUser(context, docId, name),
                                              ),
                                            ],
                                          )
                                        : FilledButton.tonalIcon(
                                            icon: const Icon(Icons.refresh, size: 16),
                                            label: const Text('Re-Approve'),
                                            onPressed: () => _approveUser(context, docId, name),
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isProcessingBulk)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Approving selected officers...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
