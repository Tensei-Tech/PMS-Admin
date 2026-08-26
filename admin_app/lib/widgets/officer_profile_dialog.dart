import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OfficerProfileDialog extends StatelessWidget {
  final DocumentSnapshot doc;

  const OfficerProfileDialog({
    super.key,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final docId = doc.id;

    final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? 'Unknown Officer').toString();
    final badgeRaw = (data['badgeNumber'] ?? data['badge_number'] ?? data['badgeNo'])?.toString() ?? '';
    final govtIdRaw = (data['govtId'] ?? '').toString();
    final badgeOrGovtId = badgeRaw.isNotEmpty ? badgeRaw : (govtIdRaw.isNotEmpty ? govtIdRaw : 'N/A');

    final designation = (data['designation'] ?? data['rank'] ?? 'N/A').toString();
    final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Unassigned').toString();
    final district = (data['district'] ?? 'N/A').toString();
    final email = (data['email'] ?? 'N/A').toString();
    final phone = (data['phone'] ?? data['phoneNumber'] ?? 'N/A').toString();
    final photoUrl = (data['photoUrl'] ?? data['photoURL'] ?? data['avatar']) as String?;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Avatar & Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 28,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(designation),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ID: $badgeOrGovtId',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // Posting Details
              Row(
                children: [
                  const Icon(Icons.location_city_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Station: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(station, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.map_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('District: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(district, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Email: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(email, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Phone: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(phone, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Case Assignments & Performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Performance Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildCaseMetricCard(
                      context: context,
                      title: 'Active Cases',
                      officerDocId: docId,
                      officerName: name,
                      statusFilter: 'open',
                      icon: Icons.folder_open_outlined,
                      color: Colors.orange.shade800,
                      backgroundColor: Colors.orange.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCaseMetricCard(
                      context: context,
                      title: 'Closed Cases',
                      officerDocId: docId,
                      officerName: name,
                      statusFilter: 'closed',
                      icon: Icons.task_alt_outlined,
                      color: Colors.green.shade700,
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildCaseMetricCard({
    required BuildContext context,
    required String title,
    required String officerDocId,
    required String officerName,
    required String statusFilter,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cases').snapshots(),
      builder: (context, snapshot) {
        String valueStr = '...';
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          final count = docs.where((c) {
            final data = c.data() as Map<String, dynamic>;
            final assignedUid = (data['assignedOfficerUid'] ?? data['createdBy'] ?? data['assignedOfficerId'] ?? data['userId'])?.toString();
            final assignedName = (data['assignedOfficer'] ?? data['officerName'] ?? data['createdByName'])?.toString();
            final status = (data['status'] ?? '').toString().toLowerCase();

            final matchesOfficer = assignedUid == officerDocId ||
                (assignedName != null && assignedName.toLowerCase() == officerName.toLowerCase());

            final matchesStatus = statusFilter == 'open'
                ? (status == 'open' || status == 'active' || status == 'under_investigation')
                : (status == 'closed' || status == 'resolved');

            return matchesOfficer && matchesStatus;
          }).length;
          valueStr = count.toString();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valueStr,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
