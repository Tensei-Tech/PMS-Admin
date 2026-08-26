import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/case_utils.dart';
import '../services/audit_service.dart';

class CasesView extends StatefulWidget {
  final String? initialStatus;

  const CasesView({super.key, this.initialStatus});

  @override
  State<CasesView> createState() => _CasesViewState();
}

class _CasesViewState extends State<CasesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedState = 'All States';
  String? _selectedDistrict;
  String? _selectedStation;
  late String _selectedStatus;

  final List<String> _states = const [
    'All States',
    'Maharashtra',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? 'All Cases';
  }

  @override
  void didUpdateWidget(covariant CasesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != null && widget.initialStatus != oldWidget.initialStatus) {
      setState(() {
        _selectedStatus = widget.initialStatus!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCaseDetailsDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    final theme = Theme.of(context);
    final caseNo = data['caseNumber'] ?? data['crimeNumber'] ?? data['firNumber'] ?? docId;
    final isDisposed = CaseUtils.isDisposed(data);
    final csNumber = CaseUtils.getChargesheetOrCcNumber(data, docId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Case: $caseNo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Status', CaseUtils.getStatusLabel(data).toUpperCase()),
                if (isDisposed) ...[
                  _detailRow('Chargesheet / CC No.', csNumber ?? 'CS-${docId.substring(0, 6).toUpperCase()}'),
                  _detailRow('Disposal / Court Date', _formatDate(data['disposedAt'] ?? data['updatedAt'] ?? data['createdAt'])),
                  _detailRow('Court Name', data['courtName']?.toString() ?? 'Session Court'),
                ],
                const Divider(),
                _detailRow('FIR / Crime No.', data['firNumber'] ?? data['crimeNumber'] ?? 'N/A'),
                _detailRow('Title / IPC/BNS Sections', data['title'] ?? data['sections'] ?? data['crimeType'] ?? 'General Investigation'),
                _detailRow('Police Station', data['station'] ?? data['stationName'] ?? data['assignedStation'] ?? 'Unassigned'),
                _detailRow('District', data['district'] ?? 'Maharashtra'),
                _detailRow('State', data['state'] ?? 'Maharashtra'),
                _detailRow('Investigating Officer (IO)', data['ioName'] ?? data['assignedOfficer'] ?? data['officerName'] ?? 'Unassigned'),
                _detailRow('IO Sevaarth / Badge ID', data['ioBadge'] ?? data['sevaarthId'] ?? 'N/A'),
                _detailRow('Registered Date', _formatDate(data['createdAt'])),
                if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Brief Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(data['description'].toString()),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _exportToCsv(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    final List<List<dynamic>> rows = [
      [
        'Case/Crime No',
        'Sections/Title',
        'Police Station',
        'District',
        'State',
        'Investigating Officer',
        'Status',
        'Chargesheet No',
        'Registration Date',
      ]
    ];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      rows.add([
        data['caseNumber'] ?? data['crimeNumber'] ?? data['firNumber'] ?? doc.id,
        data['title'] ?? data['sections'] ?? 'Investigation',
        data['station'] ?? data['stationName'] ?? '',
        data['district'] ?? '',
        data['state'] ?? 'Maharashtra',
        data['ioName'] ?? data['assignedOfficer'] ?? '',
        CaseUtils.getStatusLabel(data),
        CaseUtils.getChargesheetOrCcNumber(data, doc.id) ?? 'N/A',
        _formatDate(data['createdAt']),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(utf8.encode(csvData));
    await FileSaver.instance.saveFile(
      name: 'cases_report_${DateTime.now().millisecondsSinceEpoch}.csv',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );

    await AuditService.logAction(
      action: 'CASES_EXPORTED_CSV',
      targetUserId: 'system',
      details: 'Exported ${docs.length} investigation records to CSV report',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${docs.length} cases to CSV!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          width: 400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDistricts = AppConstants.getDistrictsForUnitType(null);
    final availableStations = _selectedDistrict != null
        ? AppConstants.getStationsForDistrict(_selectedDistrict)
        : const <String>[];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Export
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cases & Investigations Management',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time case tracking, jurisdictional filtering & chargesheet tracking',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Multi-Tier Filters Bar (State, District, City/Station, IO, Status)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Search
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by Case No, IO name, Section...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // State Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedState,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'State',
                            prefixIcon: const Icon(Icons.map_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _selectedState = val ?? 'All States'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // District Filter
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedDistrict,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'District',
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All Districts')),
                            ...allDistricts.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedDistrict = val;
                              _selectedStation = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Police Station Filter
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedStation,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Police Station',
                            prefixIcon: const Icon(Icons.local_police_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All Stations')),
                            ...availableStations.map((st) => DropdownMenuItem<String?>(value: st, child: Text(st, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) => setState(() => _selectedStation = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status / Chargesheet Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_selectedStatus),
                          initialValue: _selectedStatus,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Case Status',
                            prefixIcon: const Icon(Icons.fact_check_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All Cases', child: Text('All Cases')),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'Disposed', child: Text('Disposed (Chargesheeted)')),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val ?? 'All Cases'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reset Filters Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Reset'),
                        onPressed: () {
                          setState(() {
                            _selectedState = 'All States';
                            _selectedDistrict = null;
                            _selectedStation = null;
                            _selectedStatus = 'All Cases';
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main Table Area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cases').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If collection doesn't exist or is empty, we handle gracefully
                final docs = snapshot.data?.docs ?? [];

                // Filter logic
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final caseNo = (data['caseNumber'] ?? data['crimeNumber'] ?? data['firNumber'] ?? doc.id).toString().toLowerCase();
                  final title = (data['title'] ?? data['sections'] ?? '').toString().toLowerCase();
                  final ioName = (data['ioName'] ?? data['assignedOfficer'] ?? '').toString().toLowerCase();
                  final station = (data['station'] ?? data['stationName'] ?? '').toString();
                  final district = (data['district'] ?? '').toString();
                  final state = (data['state'] ?? 'Maharashtra').toString();
                  final isDisposed = CaseUtils.isDisposed(data);

                  // Search query filter
                  if (_searchQuery.isNotEmpty) {
                    final matches = caseNo.contains(_searchQuery) ||
                        title.contains(_searchQuery) ||
                        ioName.contains(_searchQuery) ||
                        station.toLowerCase().contains(_searchQuery);
                    if (!matches) return false;
                  }

                  // State filter
                  if (_selectedState != 'All States' && state != _selectedState) {
                    return false;
                  }

                  // District filter
                  if (_selectedDistrict != null && !district.toLowerCase().contains(_selectedDistrict!.toLowerCase())) {
                    return false;
                  }

                  // Station filter
                  if (_selectedStation != null && station != _selectedStation) {
                    return false;
                  }

                  // Status filter
                  if ((_selectedStatus == 'Pending' || _selectedStatus == 'Active') && isDisposed) return false;
                  if (_selectedStatus == 'Disposed' && !isDisposed) return false;

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 56, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            'No cases match the selected filters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try clearing the search query or adjusting State / District filters',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Subheader count & Export
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${filteredDocs.length} Cases',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.file_download_outlined, size: 16),
                              label: const Text('Export to CSV'),
                              onPressed: () => _exportToCsv(filteredDocs),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Data Table
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withAlpha(80)),
                              columns: const [
                                DataColumn(label: Text('Case / Crime No', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Police Station & District', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Investigating Officer (IO)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status / Chargesheet', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Registered', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final caseNo = data['caseNumber'] ?? data['crimeNumber'] ?? data['firNumber'] ?? doc.id;
                                final station = data['station'] ?? data['stationName'] ?? 'Unassigned';
                                final district = data['district'] ?? 'Maharashtra';
                                final io = data['ioName'] ?? data['assignedOfficer'] ?? 'Unassigned IO';
                                final isDisposed = CaseUtils.isDisposed(data);
                                final csNumber = CaseUtils.getChargesheetOrCcNumber(data, doc.id) ?? 'CS-${doc.id.substring(0, 6).toUpperCase()}';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isDisposed ? Icons.task_alt : Icons.hourglass_top,
                                            size: 18,
                                            color: isDisposed ? Colors.teal : theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            caseNo.toString(),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(station.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                                          Text(
                                            district.toString(),
                                            style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(io.toString()),
                                    ),
                                    DataCell(
                                      isDisposed
                                          ? Chip(
                                              avatar: const Icon(Icons.check_circle_outline, size: 14, color: Colors.teal),
                                              label: Text('Disposed ($csNumber)'),
                                              backgroundColor: Colors.teal.shade50,
                                              side: BorderSide(color: Colors.teal.shade200),
                                              visualDensity: VisualDensity.compact,
                                            )
                                          : Chip(
                                              avatar: const Icon(Icons.sync, size: 14, color: Colors.blueAccent),
                                              label: const Text('Pending'),
                                              backgroundColor: Colors.blue.shade50,
                                              side: BorderSide(color: Colors.blue.shade200),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                    ),
                                    DataCell(
                                      Text(_formatDate(data['createdAt'])),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18),
                                        tooltip: 'View Case Details',
                                        onPressed: () => _showCaseDetailsDialog(context, data, doc.id),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
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
