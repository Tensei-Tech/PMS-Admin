import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class StationDashboardView extends StatelessWidget {
  final String stationName;

  const StationDashboardView({
    super.key,
    required this.stationName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$stationName Overview',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Station Performance & Personnel',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time metrics and active personnel assigned to $stationName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            // Stat Cards Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildOfficersCard(context)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildActiveCasesCard(context)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildClosedCasesCard(context)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildOfficersCard(context),
                          const SizedBox(height: 12),
                          _buildActiveCasesCard(context),
                          const SizedBox(height: 12),
                          _buildClosedCasesCard(context),
                        ],
                      );
              },
            ),
            const SizedBox(height: 32),
            // Personnel List Section Header
            Row(
              children: [
                Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Assigned Officers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Personnel Data Table
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
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

                final docs = snapshot.data?.docs ?? [];
                final stationOfficers = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (AppConstants.isAdminUser(data)) return false;
                  final userStation = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
                  final status = (data['accountStatus'] ?? data['status'] ?? 'active').toString().trim();
                  return userStation == stationName.trim() &&
                      status != 'pending_approval' &&
                      status != 'pending' &&
                      status != 'rejected' &&
                      status != 'archived';
                }).toList();

                if (stationOfficers.isEmpty) {
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No active officers currently assigned to $stationName.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            label: Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        rows: stationOfficers.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? 'Unknown').toString();
                          final badgeRaw = (data['badgeNumber'] ?? data['badge_number'] ?? data['badgeNo'])?.toString() ?? '';
                          final govtIdRaw = (data['govtId'] ?? '').toString();
                          final badgeOrGovtId = badgeRaw.isNotEmpty
                              ? badgeRaw
                              : (govtIdRaw.isNotEmpty ? govtIdRaw : 'N/A');

                          final designation = (data['designation'] ?? data['rank'] ?? 'N/A').toString();
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
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                Text(
                                  badgeOrGovtId,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(designation),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.contact_phone_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(contact),
                                  ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildOfficersCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        String valueStr = '...';
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          final count = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final st = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
            final status = (data['accountStatus'] ?? data['status'] ?? 'active').toString().trim();
            return st == stationName.trim() &&
                status != 'pending_approval' &&
                status != 'pending' &&
                status != 'rejected' &&
                status != 'archived';
          }).length;
          valueStr = count.toString();
        }

        return _StatCard(
          title: 'Total Officers',
          value: valueStr,
          icon: Icons.shield_outlined,
          color: Colors.blue.shade700,
          backgroundColor: Colors.blue.shade50,
        );
      },
    );
  }

  Widget _buildActiveCasesCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cases')
          .snapshots(),
      builder: (context, snapshot) {
        String valueStr = '...';
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          final count = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final st = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
            final status = (data['status'] ?? 'open').toString().trim().toLowerCase();
            return (st == stationName.trim() || st == null) &&
                (status == 'open' || status == 'active' || status == 'under_investigation');
          }).length;
          valueStr = count.toString();
        }

        return _StatCard(
          title: 'Active Cases',
          value: valueStr,
          icon: Icons.folder_open_outlined,
          color: Colors.orange.shade800,
          backgroundColor: Colors.orange.shade50,
        );
      },
    );
  }

  Widget _buildClosedCasesCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cases')
          .snapshots(),
      builder: (context, snapshot) {
        String valueStr = '...';
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          final count = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final st = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
            final status = (data['status'] ?? '').toString().trim().toLowerCase();
            return (st == stationName.trim() || st == null) &&
                (status == 'closed' || status == 'resolved');
          }).length;
          valueStr = count.toString();
        }

        return _StatCard(
          title: 'Closed Cases',
          value: valueStr,
          icon: Icons.task_alt_outlined,
          color: Colors.green.shade700,
          backgroundColor: Colors.green.shade50,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
