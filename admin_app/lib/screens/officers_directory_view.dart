import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../widgets/officer_profile_dialog.dart';
import '../services/audit_service.dart';

class OfficersDirectoryView extends StatefulWidget {
  const OfficersDirectoryView({super.key});

  @override
  State<OfficersDirectoryView> createState() => _OfficersDirectoryViewState();
}

class _OfficersDirectoryViewState extends State<OfficersDirectoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDesignation;
  String? _selectedDistrict;
  bool _showArchived = false;
  List<QueryDocumentSnapshot> _currentFilteredDocs = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOfficerProfileDialog(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (ctx) => OfficerProfileDialog(doc: doc),
    );
  }

  void _showEditOfficerDialog(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditOfficerDialog(doc: doc),
    );
  }

  Future<void> _archiveOfficer(BuildContext context, String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Officer Account'),
        content: Text('Are you sure you want to archive "$name"? Their account will be deactivated and they will lose access to the app until you restore them from the Archived list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archive Officer'),
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
          'accountStatus': 'archived',
          'status': 'inactive',
          'isArchived': true,
          'activeSessions': [],
          'sessionRevokedAt': FieldValue.serverTimestamp(),
          'archivedAt': FieldValue.serverTimestamp(),
        });

        await AuditService.logAction(
          action: 'OFFICER_ARCHIVED',
          targetUserId: docId,
          details: 'Archived officer account for $name and revoked mobile app access',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Archived account for $name. Access has been revoked.'),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              width: 440,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to archive account: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreOfficer(BuildContext context, String docId, String name) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({
        'accountStatus': 'active',
        'status': 'active',
        'isArchived': false,
        'restoredAt': FieldValue.serverTimestamp(),
      });

      await AuditService.logAction(
        action: 'OFFICER_RESTORED',
        targetUserId: docId,
        details: 'Restored officer account for $name and re-enabled mobile app access',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored account for $name to Active Directory. Access is re-enabled.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            width: 440,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore account: $e'),
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

  Future<void> _exportToCSV(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No officer records to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final List<List<dynamic>> csvData = [
      [
        'Name',
        'Badge / Govt ID',
        'Designation',
        'Unit Type',
        'District',
        'Station',
        'Email',
        'Phone',
        'Join Date'
      ],
    ];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? '').toString();
      final badgeRaw = (data['badgeNumber'] ?? data['badge_number'] ?? data['badgeNo'])?.toString() ?? '';
      final govtIdRaw = (data['govtId'] ?? '').toString();
      final badgeOrGovtId = badgeRaw.isNotEmpty ? badgeRaw : govtIdRaw;
      final designation = (data['designation'] ?? data['rank'] ?? '').toString();
      final unitType = (data['unitType'] ?? '').toString();
      final district = (data['district'] ?? '').toString();
      final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? '').toString();
      final email = (data['email'] ?? '').toString();
      final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
      final joinDate = _formatDate(data['createdAt'] ?? data['appliedDate'] ?? data['timestamp']);

      csvData.add([
        name,
        badgeOrGovtId,
        designation,
        unitType,
        district,
        station,
        email,
        phone,
        joinDate,
      ]);
    }

    final String csvContent = const ListToCsvConverter().convert(csvData);
    final Uint8List bytes = Uint8List.fromList(utf8.encode(csvContent));

    try {
      await FileSaver.instance.saveFile(
        name: _showArchived ? 'archived_officers_export' : 'officers_export',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      await AuditService.logAction(
        action: 'OFFICERS_EXPORTED_CSV',
        targetUserId: 'system',
        details: 'Exported ${docs.length} ${_showArchived ? 'archived' : 'active'} officer record(s) to CSV',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${docs.length} officer(s) to CSV'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            width: 420,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showArchived ? 'Archived Officers' : 'Officers Directory',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showArchived
                        ? 'View and restore archived police personnel accounts'
                        : 'Directory of all active police personnel and station assignments',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Active Officers'),
                    icon: Icon(Icons.shield_outlined, size: 18),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Archived'),
                    icon: Icon(Icons.archive_outlined, size: 18),
                  ),
                ],
                selected: {_showArchived},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _showArchived = newSelection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Name, Badge, Email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('desig_$_selectedDesignation'),
                  initialValue: _selectedDesignation,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Designation',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Designations'),
                    ),
                    ...AppConstants.allDesignations.map((d) {
                      return DropdownMenuItem<String>(
                        value: d,
                        child: Text(d),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedDesignation = val;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('dist_$_selectedDistrict'),
                  initialValue: _selectedDistrict,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'District / City',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Districts'),
                    ),
                    ...AppConstants.getDistrictsForUnitType(null).map((dist) {
                      return DropdownMenuItem<String>(
                        value: dist,
                        child: Text(dist, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedDistrict = val;
                    });
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty || _selectedDesignation != null || _selectedDistrict != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedDesignation = null;
                      _selectedDistrict = null;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off, size: 18, color: Colors.redAccent),
                  label: const Text(
                    'Reset Filters',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _currentFilteredDocs.isEmpty
                    ? null
                    : () => _exportToCSV(_currentFilteredDocs),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export CSV'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading officers: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                final targetDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (AppConstants.isAdminUser(data)) return false; // Strictly exclude admin accounts

                  final accountStatus = (data['accountStatus'] ?? data['status'] ?? 'active').toString().trim().toLowerCase();

                  if (_showArchived) {
                    return accountStatus == 'archived' || accountStatus == 'inactive';
                  } else {
                    return accountStatus != 'pending_approval' &&
                        accountStatus != 'pending' &&
                        accountStatus != 'rejected' &&
                        accountStatus != 'archived' &&
                        accountStatus != 'inactive';
                  }
                }).toList();

                final filteredDocs = targetDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Search query filter (name, email, badgeNumber, govtId)
                  if (_searchQuery.isNotEmpty) {
                    final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    final badge = (data['badgeNumber'] ?? data['badge_number'] ?? data['badgeNo'] ?? '').toString().toLowerCase();
                    final govtId = (data['govtId'] ?? '').toString().toLowerCase();

                    final matchesSearch = name.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        badge.contains(_searchQuery) ||
                        govtId.contains(_searchQuery);

                    if (!matchesSearch) return false;
                  }

                  // Designation filter
                  if (_selectedDesignation != null && _selectedDesignation != 'All Designations') {
                    final desig = (data['designation'] ?? data['rank'] ?? '').toString().trim();
                    if (desig.toLowerCase() != _selectedDesignation!.toLowerCase()) {
                      return false;
                    }
                  }

                  // District filter
                  if (_selectedDistrict != null && _selectedDistrict != 'All Districts') {
                    final dist = (data['district'] ?? '').toString().trim();
                    if (dist.toLowerCase() != _selectedDistrict!.toLowerCase()) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                _currentFilteredDocs = filteredDocs;

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showArchived ? Icons.archive_outlined : Icons.person_search_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showArchived
                              ? 'No archived officers found matching the filters.'
                              : 'No active officers found matching the filters.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedDesignation = null;
                              _selectedDistrict = null;
                            });
                          },
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerHigh,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text('Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Badge / Govt ID', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Designation / Rank', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Station', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: filteredDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? 'Unknown').toString();
                            final badgeRaw = (data['badgeNumber'] ?? data['badge_number'] ?? data['badgeNo'])?.toString() ?? '';
                            final govtIdRaw = (data['govtId'] ?? '').toString();
                            final badgeOrGovtId = badgeRaw.isNotEmpty
                                ? badgeRaw
                                : (govtIdRaw.isNotEmpty ? govtIdRaw : 'N/A');

                            final designation = (data['designation'] ?? data['rank'] ?? 'N/A').toString();
                            final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Unassigned').toString();
                            final contact = (data['phone'] ?? data['phoneNumber'] ?? data['email'] ?? 'N/A').toString();
                            final photoUrl = (data['photoUrl'] ?? data['photoURL'] ?? data['avatar']) as String?;

                            return DataRow(
                              cells: [
                                DataCell(
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: (photoUrl == null || photoUrl.isEmpty)
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: theme.colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    badgeOrGovtId,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      designation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_city, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          station,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.contact_phone_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          contact,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_showArchived) ...[
                                        IconButton(
                                          icon: const Icon(Icons.visibility, color: Colors.blue),
                                          tooltip: 'View Officer Profile & Performance',
                                          onPressed: () => _showOfficerProfileDialog(context, doc),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Edit Officer Profile',
                                          onPressed: () => _showEditOfficerDialog(context, doc),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.archive_outlined, color: Colors.red),
                                          tooltip: 'Archive Officer',
                                          onPressed: () => _archiveOfficer(context, doc.id, name),
                                        ),
                                      ] else ...[
                                        IconButton(
                                          icon: const Icon(Icons.unarchive_outlined, color: Colors.green),
                                          tooltip: 'Restore Officer Account',
                                          onPressed: () => _restoreOfficer(context, doc.id, name),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }
}

class _EditOfficerDialog extends StatefulWidget {
  final DocumentSnapshot doc;

  const _EditOfficerDialog({required this.doc});

  @override
  State<_EditOfficerDialog> createState() => _EditOfficerDialogState();
}

class _EditOfficerDialogState extends State<_EditOfficerDialog> {
  late String _officerName;
  late String _badgeOrGovtId;

  String? _selectedDesignation;
  String? _selectedUnitType;
  String? _selectedDistrict;
  String? _selectedStation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>? ?? {};
    _officerName = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? 'Officer').toString();
    final badgeRaw = (data['badgeNumber'] ?? data['badge_number'] ?? data['badgeNo'])?.toString() ?? '';
    final govtIdRaw = (data['govtId'] ?? '').toString();
    _badgeOrGovtId = badgeRaw.isNotEmpty ? badgeRaw : (govtIdRaw.isNotEmpty ? govtIdRaw : 'N/A');

    final rawDesignation = (data['designation'] ?? data['rank'] ?? '').toString().trim();
    _selectedDesignation = rawDesignation.isNotEmpty ? rawDesignation : 'PC';

    final rawUnitType = (data['unitType'] ?? '').toString().trim();
    if (rawUnitType.toLowerCase().contains('commissionerate')) {
      _selectedUnitType = 'Commissionerate Police';
    } else if (rawUnitType.toLowerCase().contains('rural') || rawUnitType.toLowerCase().contains('superintendent')) {
      _selectedUnitType = 'Rural Police';
    } else {
      final implied = AppConstants.getImpliedUnitType(_selectedDesignation);
      _selectedUnitType = implied ?? 'Commissionerate Police';
    }

    final rawDistrict = (data['district'] ?? '').toString().trim();
    final validDistricts = AppConstants.getDistrictsForUnitType(_selectedUnitType);
    if (rawDistrict.isNotEmpty) {
      _selectedDistrict = rawDistrict;
    } else if (validDistricts.isNotEmpty) {
      _selectedDistrict = validDistricts.first;
    }

    final rawStation = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? '').toString().trim();
    final validStations = AppConstants.getStationsForDistrict(_selectedDistrict);
    if (rawStation.isNotEmpty) {
      _selectedStation = rawStation;
    } else if (validStations.isNotEmpty) {
      _selectedStation = validStations.first;
    }
  }

  void _onDesignationChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedDesignation = val;
      final implied = AppConstants.getImpliedUnitType(val);
      if (implied != null && implied != _selectedUnitType) {
        _selectedUnitType = implied;
        _syncDistrictAndStation();
      }
    });
  }

  void _onUnitTypeChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedUnitType = val;
      _syncDistrictAndStation();
    });
  }

  void _onDistrictChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedDistrict = val;
      final stations = AppConstants.getStationsForDistrict(val);
      if (_selectedStation != null && !stations.contains(_selectedStation)) {
        _selectedStation = stations.isNotEmpty ? stations.first : null;
      }
    });
  }

  void _onStationChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedStation = val;
    });
  }

  void _syncDistrictAndStation() {
    final districts = AppConstants.getDistrictsForUnitType(_selectedUnitType);
    if (_selectedDistrict != null && !districts.contains(_selectedDistrict)) {
      _selectedDistrict = districts.isNotEmpty ? districts.first : null;
    }
    final stations = AppConstants.getStationsForDistrict(_selectedDistrict);
    if (_selectedStation != null && !stations.contains(_selectedStation)) {
      _selectedStation = stations.isNotEmpty ? stations.first : null;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doc.id)
          .update({
        'designation': _selectedDesignation,
        'unitType': _selectedUnitType,
        'district': _selectedDistrict,
        'stationName': _selectedStation,
      });

      await AuditService.logAction(
        action: 'EDITED',
        targetUserId: widget.doc.id,
        details: 'Updated profile for $_officerName: Designation=$_selectedDesignation, District=$_selectedDistrict, Station=$_selectedStation',
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated profile for $_officerName'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          width: 400,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final designationSet = <String>{...AppConstants.getDesignationsForUnitType(_selectedUnitType)};
    if (_selectedDesignation != null && _selectedDesignation!.isNotEmpty) {
      designationSet.add(_selectedDesignation!);
    }
    final designationItems = designationSet.toList();

    final unitTypeSet = <String>{...AppConstants.unitTypes};
    if (_selectedUnitType != null && _selectedUnitType!.isNotEmpty) {
      unitTypeSet.add(_selectedUnitType!);
    }
    final unitTypeItems = unitTypeSet.toList();

    final districtSet = <String>{...AppConstants.getDistrictsForUnitType(_selectedUnitType)};
    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
      districtSet.add(_selectedDistrict!);
    }
    final districtItems = districtSet.toList();

    final stationSet = <String>{...AppConstants.getStationsForDistrict(_selectedDistrict)};
    if (_selectedStation != null && _selectedStation!.isNotEmpty) {
      stationSet.add(_selectedStation!);
    }
    final stationItems = stationSet.toList();

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Edit Officer Profile'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_officerName ($_badgeOrGovtId)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('designation_$_selectedDesignation'),
                initialValue: designationItems.contains(_selectedDesignation) ? _selectedDesignation : null,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  prefixIcon: Icon(Icons.shield_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: designationItems.map((d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(d),
                  );
                }).toList(),
                onChanged: _isSaving ? null : _onDesignationChanged,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('unitType_$_selectedUnitType'),
                initialValue: unitTypeItems.contains(_selectedUnitType) ? _selectedUnitType : null,
                decoration: const InputDecoration(
                  labelText: 'Unit Type',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: unitTypeItems.map((u) {
                  return DropdownMenuItem<String>(
                    value: u,
                    child: Text(u),
                  );
                }).toList(),
                onChanged: _isSaving ? null : _onUnitTypeChanged,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('district_$_selectedDistrict'),
                initialValue: districtItems.contains(_selectedDistrict) ? _selectedDistrict : null,
                decoration: const InputDecoration(
                  labelText: 'District / City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: districtItems.map((dist) {
                  return DropdownMenuItem<String>(
                    value: dist,
                    child: Text(dist),
                  );
                }).toList(),
                onChanged: _isSaving ? null : _onDistrictChanged,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('station_$_selectedStation'),
                initialValue: stationItems.contains(_selectedStation) ? _selectedStation : null,
                decoration: const InputDecoration(
                  labelText: 'Police Station / Branch',
                  prefixIcon: Icon(Icons.local_police_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: stationItems.map((st) {
                  return DropdownMenuItem<String>(
                    value: st,
                    child: Text(st),
                  );
                }).toList(),
                onChanged: _isSaving ? null : _onStationChanged,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveChanges,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
