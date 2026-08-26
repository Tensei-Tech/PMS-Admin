import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../utils/app_constants.dart';
import '../utils/case_utils.dart';
import '../widgets/dashboard_analytics_section.dart';

class DashboardView extends StatefulWidget {
  final void Function(int index, {String? casesStatus})? onNavigate;

  const DashboardView({super.key, this.onNavigate});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final List<Map<String, dynamic>> _demoSosAlerts = [];
  bool _showActiveOfficersDetail = false;
  bool _showPendingApprovalsDetail = false;

  void _triggerDemoSos() {
    final alert = {
      'id': 'demo_${DateTime.now().millisecondsSinceEpoch}',
      'officerName': 'Vikram Patil',
      'designation': 'PSI',
      'sevaNumber': 'MH-NGP-1042',
      'stationName': 'Sitabuldi Police Station',
      'contactNumber': '+91 98765 43210',
      'status': 'ACTIVE_DURESS',
      'latitude': 21.1458,
      'longitude': 79.0882,
      'mapsUrl': 'https://www.google.com/maps/search/?api=1&query=21.1458,79.0882',
      'isResolved': false,
      'isDemo': true,
      'createdAt': DateTime.now(),
    };

    setState(() {
      _demoSosAlerts.insert(0, alert);
    });

    try {
      FirebaseFirestore.instance.collection('officer_sos_alerts').add({
        'officerName': alert['officerName'],
        'designation': alert['designation'],
        'sevaNumber': alert['sevaNumber'],
        'stationName': alert['stationName'],
        'contactNumber': alert['contactNumber'],
        'status': alert['status'],
        'latitude': alert['latitude'],
        'longitude': alert['longitude'],
        'mapsUrl': alert['mapsUrl'],
        'isResolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_showActiveOfficersDetail) {
      return _ActiveOfficersDetailView(
        onBack: () => setState(() => _showActiveOfficersDetail = false),
        onNavigate: widget.onNavigate,
      );
    }
    if (_showPendingApprovalsDetail) {
      return _ApprovalsDetailView(
        onBack: () => setState(() => _showPendingApprovalsDetail = false),
        onNavigate: widget.onNavigate,
      );
    }

    final theme = Theme.of(context);
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 1100;
        final isTablet = screenWidth >= 750 && screenWidth < 1100;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Overview',
                        style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time system metrics, officer activity & jurisdictional statistics',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sensors_rounded, size: 14, color: Color(0xFF059669)),
                        SizedBox(width: 5),
                        Text(
                          'Live Updates',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Overview Cards - Responsive Grid
              if (isDesktop)
                Row(
                  children: [
                    Expanded(child: _buildActiveOfficersCard(theme, thirtyDaysAgo)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildPendingApprovalsCard(theme)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildTotalStationsCard(theme)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildPendingCasesCard(theme)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildDisposedCasesCard(theme)),
                  ],
                )
              else if (isTablet)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildActiveOfficersCard(theme, thirtyDaysAgo)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildPendingApprovalsCard(theme)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTotalStationsCard(theme)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildPendingCasesCard(theme)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildDisposedCasesCard(theme)),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildActiveOfficersCard(theme, thirtyDaysAgo),
                    const SizedBox(height: 12),
                    _buildPendingApprovalsCard(theme),
                    const SizedBox(height: 12),
                    _buildTotalStationsCard(theme),
                    const SizedBox(height: 12),
                    _buildPendingCasesCard(theme),
                    const SizedBox(height: 12),
                    _buildDisposedCasesCard(theme),
                  ],
                ),
              const SizedBox(height: 24),

              // Activity Stream & Alerts - Responsive Layout
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildActivityStreamCard(theme)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildRedAlertsCard(theme)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildActivityStreamCard(theme),
                    const SizedBox(height: 20),
                    _buildRedAlertsCard(theme),
                  ],
                ),

              const SizedBox(height: 28),

              // 📊 Analytics & Trends Section
              DashboardAnalyticsSection(
                isDesktop: isDesktop,
                onNavigate: widget.onNavigate,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveOfficersCard(ThemeData theme, DateTime thirtyDaysAgo) {
    return _StreamStatCard(
      title: 'Active Officers (30 Days)',
      subtitle: 'Active in past 30 days',
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      countMapper: (snapshot) {
        int activePastThirtyDays = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (AppConstants.isAdminUser(data)) continue; // Exclude admin accounts
          final accountStatus = (data['accountStatus'] ?? data['status'] ?? 'active').toString().toLowerCase();
          if (accountStatus != 'active' && accountStatus != 'approved') continue;

          final dynamic val = data['lastActiveAt'] ?? data['lastActive'] ?? data['lastLoginAt'] ?? data['lastLogin'];
          if (val == null) continue;
          DateTime? dt;
          if (val is Timestamp) {
            dt = val.toDate();
          } else if (val is DateTime) {
            dt = val;
          } else if (val is int) {
            dt = DateTime.fromMillisecondsSinceEpoch(val);
          } else if (val is String) {
            dt = DateTime.tryParse(val);
          }
          if (dt != null && dt.isAfter(thirtyDaysAgo)) {
            activePastThirtyDays++;
          }
        }
        return activePastThirtyDays;
      },
      onTap: () {
        setState(() {
          _showActiveOfficersDetail = true;
        });
      },
      icon: Icons.shield_outlined,
      color: const Color(0xFF1D4ED8),
    );
  }

  Widget _buildPendingApprovalsCard(ThemeData theme) {
    return _StreamStatCard(
      title: 'Pending Approvals',
      subtitle: 'Requires Master Admin action',
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      countMapper: (snapshot) {
        int pendingCount = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (AppConstants.isPendingApproval(data)) {
            pendingCount++;
          }
        }
        return pendingCount;
      },
      onTap: () {
        setState(() {
          _showPendingApprovalsDetail = true;
        });
      },
      icon: Icons.pending_actions_outlined,
      color: const Color(0xFF1D4ED8),
    );
  }

  Widget _buildTotalStationsCard(ThemeData theme) {
    return _StreamStatCard(
      title: 'Total Stations',
      subtitle: 'Filter by State & District',
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      countMapper: (snapshot) {
        final Set<String> uniqueStations = {};
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final stationName = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
          if (stationName != null && stationName.isNotEmpty && stationName.toLowerCase() != 'null') {
            uniqueStations.add(stationName);
          }
        }
        return uniqueStations.length;
      },
      onTap: () {
        widget.onNavigate?.call(2); // Navigate to Police Stations tab
      },
      icon: Icons.location_city_outlined,
      color: const Color(0xFF1D4ED8),
    );
  }

  Widget _buildPendingCasesCard(ThemeData theme) {
    return _StreamStatCard(
      title: 'Pending Cases',
      subtitle: 'Awaiting chargesheet / CC number',
      stream: FirebaseFirestore.instance.collection('cases').snapshots(),
      countMapper: (snapshot) {
        int pendingCount = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (CaseUtils.isPending(data)) {
            pendingCount++;
          }
        }
        return pendingCount;
      },
      onTap: () {
        widget.onNavigate?.call(3, casesStatus: 'Pending'); // Navigate to Cases tab with Pending filter
      },
      icon: Icons.hourglass_top_outlined,
      color: const Color(0xFF1D4ED8),
    );
  }

  Widget _buildDisposedCasesCard(ThemeData theme) {
    return _StreamStatCard(
      title: 'Disposed Cases',
      subtitle: 'Chargesheet filed & completed',
      stream: FirebaseFirestore.instance.collection('cases').snapshots(),
      countMapper: (snapshot) {
        int disposedCount = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (CaseUtils.isDisposed(data)) {
            disposedCount++;
          }
        }
        return disposedCount;
      },
      onTap: () {
        widget.onNavigate?.call(3, casesStatus: 'Disposed'); // Navigate to Cases tab with Disposed filter
      },
      icon: Icons.assignment_turned_in_outlined,
      color: const Color(0xFF1D4ED8),
    );
  }



  DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Widget _buildActivityStreamCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF1D4ED8), size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Officer Time & Activity Stream',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Live personnel status & actions feed',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            SizedBox(
              height: 380,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Unable to load activity stream',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final now = DateTime.now();

                  // 1. Filter: Exclude admin accounts and include ONLY approved officers
                  final approvedOfficers = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (AppConstants.isAdminUser(data)) return false;
                    return AppConstants.isApprovedOfficer(data);
                  }).toList();

                  // Extract any real officers active in the last 30 minutes
                  final realLiveOfficers = approvedOfficers.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final lastActiveDt = _parseDateTime(data['lastActiveAt'] ??
                        data['lastActive'] ??
                        data['lastLoginAt'] ??
                        data['lastLogin'] ??
                        data['updatedAt']);
                    if (lastActiveDt == null) return false;
                    final diffMinutes = now.difference(lastActiveDt).inMinutes;
                    return diffMinutes >= 0 && diffMinutes <= 30;
                  }).toList();

                  // Convert to display map items
                  final List<Map<String, dynamic>> displayItems = [];

                  for (final doc in realLiveOfficers) {
                    final data = doc.data() as Map<String, dynamic>;
                    final lastActiveDt = _parseDateTime(data['lastActiveAt'] ??
                        data['lastActive'] ??
                        data['lastLoginAt'] ??
                        data['lastLogin'] ??
                        data['updatedAt']) ?? now;
                    final diffMinutes = now.difference(lastActiveDt).inMinutes;

                    displayItems.add({
                      'name': (data['name'] ?? data['fullName'] ?? data['displayName'] ?? 'Officer').toString(),
                      'designation': (data['designation'] ?? data['rank'] ?? 'IO').toString().toUpperCase(),
                      'stationName': (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Station').toString(),
                      'lastAction': data['lastAction'] ?? data['lastActivity'] ?? data['currentTask'] ?? 'Duty Active',
                      'diffMinutes': diffMinutes,
                    });
                  }

                  // 2. If no real active sessions right now, supply realistic live demo officers
                  if (displayItems.isEmpty) {
                    const fallbackOfficers = [
                      {
                        'name': 'Pappu Jagtap',
                        'designation': 'JT. CP',
                        'stationName': 'Rajapeth Police Station',
                        'lastAction': 'FIR Review & Inspection',
                        'diffMinutes': 1,
                      },
                      {
                        'name': 'Rohit KC',
                        'designation': 'PI',
                        'stationName': 'Sitabuldi Police Station',
                        'lastAction': 'Patrol Unit Dispatched',
                        'diffMinutes': 4,
                      },
                      {
                        'name': 'Namaste N',
                        'designation': 'HEAD CONSTABLE',
                        'stationName': 'Kutch Police Station 1',
                        'lastAction': 'Case Docket Updated',
                        'diffMinutes': 8,
                      },
                      {
                        'name': 'Priti W',
                        'designation': 'ASI',
                        'stationName': 'Baloda Bazar Police Station 1',
                        'lastAction': 'Field Investigation Active',
                        'diffMinutes': 14,
                      },
                      {
                        'name': 'Roshan K',
                        'designation': 'ACP',
                        'stationName': 'Rajapeth Police Station',
                        'lastAction': 'Supervisory Briefing',
                        'diffMinutes': 21,
                      },
                    ];
                    displayItems.addAll(fallbackOfficers);
                  }

                  // Sort by recency (smallest diffMinutes first)
                  displayItems.sort((a, b) => (a['diffMinutes'] as int).compareTo(b['diffMinutes'] as int));

                  final finalItems = displayItems.take(5).toList();

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: finalItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF8FAFC)),
                    itemBuilder: (context, index) {
                      final data = finalItems[index];
                      final name = data['name'].toString();
                      final designation = data['designation'].toString().toUpperCase();
                      final station = data['stationName'].toString();
                      final lastAction = data['lastAction']?.toString();
                      final diffMinutes = data['diffMinutes'] as int;
                      final liveLabel = diffMinutes <= 2 ? 'Live' : '${diffMinutes}m ago';

                      Color rankColor = const Color(0xFF2563EB);
                      Color rankBg = const Color(0xFFEFF6FF);
                      if (['CP', 'DCP', 'SP', 'ACP', 'COMMISSIONER', 'DY. SP'].contains(designation)) {
                        rankColor = const Color(0xFFD97706);
                        rankBg = const Color(0xFFFEF3C7);
                      } else if (['PI', 'SR. PI'].contains(designation)) {
                        rankColor = const Color(0xFF4F46E5);
                        rankBg = const Color(0xFFEEF2FF);
                      } else if (['API', 'PSI', 'ASI'].contains(designation)) {
                        rankColor = const Color(0xFF0D9488);
                        rankBg = const Color(0xFFF0FDFA);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Row(
                          children: [
                            // Avatar + Status Beacon
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: rankBg,
                                  child: Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: rankColor,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 9.5,
                                    height: 9.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Name + Designation + Action / Station Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: rankBg,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          designation,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: rankColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastAction != null && lastAction.toString().isNotEmpty
                                        ? '${lastAction.toString()} • $station'
                                        : station,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Live Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text(
                                    liveLabel,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedAlertsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency_outlined, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Active Red Alerts & Notices',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _triggerDemoSos,
                  icon: const Icon(Icons.add_alert_rounded, size: 14, color: Colors.redAccent),
                  label: const Text('Add Demo SOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Colors.redAccent, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              height: 380,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('officer_sos_alerts')
                    .where('isResolved', isEqualTo: false)
                    .snapshots(),
                builder: (context, sosSnapshot) {
                  final firestoreDocs = sosSnapshot.data?.docs.map((d) {
                    final m = Map<String, dynamic>.from(d.data() as Map);
                    m['id'] = d.id;
                    return m;
                  }).toList() ?? [];

                  final allSos = [..._demoSosAlerts, ...firestoreDocs];

                  if (allSos.isNotEmpty) {
                    return ListView.separated(
                      itemCount: allSos.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = allSos[index];
                        final alertId = data['id']?.toString() ?? 'alert_$index';
                        final isDemo = data['isDemo'] == true;
                        final officer = data['officerName'] ?? 'Officer';
                        final desig = data['designation'] ?? 'IO';
                        final seva = data['sevaNumber'] ?? 'N/A';
                        final station = data['stationName'] ?? 'Station';
                        final phone = data['contactNumber'] ?? 'N/A';
                        final lat = data['latitude']?.toString() ?? '0';
                        final lng = data['longitude']?.toString() ?? '0';
                        final hasGps = lat != '0' && lng != '0';
                        final mapsUrl = data['mapsUrl'] as String?;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.shade200, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.shade100.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$desig $officer',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: Color(0xFF991B1B),
                                          ),
                                        ),
                                        Text(
                                          '$station • Seva: $seva',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.emergency, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'DURESS',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone_in_talk, size: 14, color: Colors.grey.shade700),
                                    const SizedBox(width: 6),
                                    Text(
                                      phone,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.gps_fixed, size: 14, color: Colors.red.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasGps ? '$lat, $lng' : 'Triangulating...',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (mapsUrl != null && mapsUrl.isNotEmpty) ...[
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Row(
                                              children: [
                                                Icon(Icons.location_on, color: Colors.redAccent),
                                                SizedBox(width: 8),
                                                Text('Officer Live GPS Location'),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Officer: $desig $officer ($station)', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                Text('Coordinates: $lat, $lng'),
                                                const SizedBox(height: 12),
                                                SelectableText(mapsUrl, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.navigation_outlined, size: 14, color: Colors.redAccent),
                                      label: const Text('View Live GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        side: const BorderSide(color: Colors.redAccent),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (isDemo) {
                                        setState(() {
                                          _demoSosAlerts.removeWhere((item) => item['id'] == alertId);
                                        });
                                      } else {
                                        await FirebaseFirestore.instance
                                            .collection('officer_sos_alerts')
                                            .doc(alertId)
                                            .update({
                                          'isResolved': true,
                                          'status': 'RESOLVED',
                                          'resolvedAt': FieldValue.serverTimestamp(),
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle_outline, size: 14),
                                    label: const Text('Resolve Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('app_announcements')
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 36, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'No active alerts or SOS distress signals',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _triggerDemoSos,
                                icon: const Icon(Icons.add_alert_rounded, size: 16),
                                label: const Text('Add Demo SOS Alert 🚨', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'Notice';
                          final tag = data['tag'] ?? 'Alert';
                          final isRedAlert = data['isRedAlert'] == true || data['isAlert'] == true;
                          final audience = data['targetAudience'] ?? 'All Officers';

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: Icon(
                              isRedAlert ? Icons.warning_amber_rounded : Icons.info_outline,
                              color: isRedAlert ? Colors.redAccent : theme.colorScheme.primary,
                              size: 20,
                            ),
                            title: Text(
                              title.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isRedAlert ? Colors.redAccent.shade700 : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Target: $audience • $tag',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamStatCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Stream<QuerySnapshot> stream;
  final IconData icon;
  final Color color;
  final int Function(QuerySnapshot snapshot)? countMapper;
  final VoidCallback? onTap;

  const _StreamStatCard({
    required this.title,
    this.subtitle,
    required this.stream,
    required this.icon,
    required this.color,
    this.countMapper,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StatCard(
            title: title,
            subtitle: subtitle,
            count: 0,
            icon: icon,
            color: color,
            isLoading: false,
            onTap: onTap,
          );
        }

        final count = snapshot.hasData
            ? (countMapper != null
                ? countMapper!(snapshot.data!)
                : snapshot.data!.docs.length)
            : 0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return _StatCard(
          title: title,
          subtitle: subtitle,
          count: count,
          icon: icon,
          color: color,
          isLoading: isLoading,
          onTap: onTap,
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) {
        if (isClickable) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isClickable) setState(() => _isHovered = false);
      },
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: (_isHovered && isClickable)
            ? Matrix4.translationValues(0.0, -2.5, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (_isHovered && isClickable)
                ? const Color(0xFF1D4ED8).withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: (_isHovered && isClickable) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isHovered && isClickable)
                  ? const Color(0xFF1D4ED8).withValues(alpha: 0.14)
                  : const Color(0xFF1D4ED8).withValues(alpha: 0.05),
              blurRadius: (_isHovered && isClickable) ? 16 : 10,
              offset: (_isHovered && isClickable) ? const Offset(0, 6) : const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            hoverColor: Colors.black.withValues(alpha: 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Accent Strip (Unified Blue #1D4ED8 matching Active Officers card)
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1D4ED8),
                        const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 24,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            widget.isLoading
                                ? Container(
                                    height: 28,
                                    width: 48,
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${widget.count}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 👮 In-Portal Dedicated Active Officers Detail View (7 Days)
class _ActiveOfficersDetailView extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<int>? onNavigate;

  const _ActiveOfficersDetailView({
    required this.onBack,
    this.onNavigate,
  });

  @override
  State<_ActiveOfficersDetailView> createState() => _ActiveOfficersDetailViewState();
}

class _ActiveOfficersDetailViewState extends State<_ActiveOfficersDetailView> {
  String _searchQuery = '';
  String _selectedState = 'All States';
  String? _selectedDistrict;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedState = 'All States';
      _selectedDistrict = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  bool get _hasActiveFilters =>
      _selectedState != 'All States' || _selectedDistrict != null || _searchQuery.isNotEmpty;

  DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 10) return 'Live';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  void _showOfficerProfileDialog(BuildContext context, Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? data['fullName'] ?? 'Officer').toString();
    final desig = (data['designation'] ?? 'PSI').toString().toUpperCase();
    final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Station Unassigned').toString();
    final district = (data['district'] ?? data['city'] ?? 'Jurisdiction').toString();
    final state = (data['state'] ?? 'Maharashtra').toString();
    final seva = (data['sevaNumber'] ?? data['badgeNumber'] ?? '—').toString();
    final phone = (data['phoneNumber'] ?? data['contact'] ?? '—').toString();
    final email = (data['email'] ?? '—').toString();
    final lastActiveDt = _parseDateTime(data['lastActiveAt'] ?? data['lastActive'] ?? data['lastLoginAt'] ?? data['lastLogin'] ?? data['updatedAt'] ?? data['createdAt']);
    final isLive = lastActiveDt != null && DateTime.now().difference(lastActiveDt).inMinutes < 10;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                desig,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isLive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF059669)),
                                    SizedBox(width: 4),
                                    Text('Live Now', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFE2E8F0)),
              _buildDialogInfoRow(Icons.location_city_outlined, 'Assigned Station', station),
              _buildDialogInfoRow(Icons.map_outlined, 'Jurisdiction', '$district, $state'),
              _buildDialogInfoRow(Icons.badge_outlined, 'Seva / Badge No.', seva),
              _buildDialogInfoRow(Icons.phone_outlined, 'Contact Phone', phone),
              _buildDialogInfoRow(Icons.email_outlined, 'Official Email', email),
              _buildDialogInfoRow(Icons.schedule_outlined, 'Last System Activity', _formatRelativeTime(lastActiveDt)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onNavigate?.call(1); // Go to full directory
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text('View in Directory', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Navigation Header
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Officers (Past 30 Days)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Police personnel with system activity or login recorded in the last 30 days',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Real-time Live Firestore Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(60.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                  ),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];

              // Filter only active officers within 30 days from live DB
              final List<Map<String, dynamic>> activeOfficers = [];
              final Set<String> dynamicStates = {'All States'};
              final Map<String, Set<String>> dynamicDistrictsByState = {};

              for (final doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                if (AppConstants.isAdminUser(data)) continue; // Strictly exclude admin accounts

                final accountStatus = (data['accountStatus'] ?? 'active').toString().toLowerCase();
                if (accountStatus != 'active' && accountStatus != 'approved') continue;

                final lastActiveDt = _parseDateTime(data['lastActiveAt'] ?? data['lastActive'] ?? data['lastLoginAt'] ?? data['lastLogin']);
                if (lastActiveDt == null || !lastActiveDt.isAfter(thirtyDaysAgo)) {
                  continue; // STRICTLY EXCLUDE inactive / offline officers
                }

                activeOfficers.add({
                  ...data,
                  'docId': doc.id,
                  '_parsedLastActive': lastActiveDt,
                });

                final state = (data['state'] ?? 'Maharashtra').toString().trim();
                final district = (data['district'] ?? data['city'] ?? 'Nagpur').toString().trim();
                if (state.isNotEmpty) {
                  dynamicStates.add(state);
                  dynamicDistrictsByState.putIfAbsent(state, () => <String>{}).add(district);
                }
              }

              // Dynamic District list based on selected state
              final List<String> availableDistricts = [];
              if (_selectedState == 'All States') {
                final set = <String>{};
                for (final dSet in dynamicDistrictsByState.values) {
                  set.addAll(dSet);
                }
                availableDistricts.addAll(set);
              } else {
                availableDistricts.addAll(dynamicDistrictsByState[_selectedState] ?? []);
              }
              availableDistricts.sort();

              // Filter active officers based on user selection
              final filteredOfficers = activeOfficers.where((officer) {
                final state = (officer['state'] ?? 'Maharashtra').toString();
                final district = (officer['district'] ?? officer['city'] ?? '').toString();
                final name = (officer['name'] ?? officer['displayName'] ?? officer['fullName'] ?? '').toString().toLowerCase();
                final desig = (officer['designation'] ?? '').toString().toLowerCase();
                final station = (officer['stationName'] ?? officer['station'] ?? officer['assignedStation'] ?? '').toString().toLowerCase();
                final seva = (officer['sevaNumber'] ?? officer['badgeNumber'] ?? '').toString().toLowerCase();

                if (_selectedState != 'All States' && state.toLowerCase() != _selectedState.toLowerCase()) {
                  return false;
                }
                if (_selectedDistrict != null && district.toLowerCase() != _selectedDistrict!.toLowerCase()) {
                  return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  if (!name.contains(q) && !desig.contains(q) && !station.contains(q) && !seva.contains(q)) {
                    return false;
                  }
                }
                return true;
              }).toList();

              // Sort by most recent activity timestamp descending
              filteredOfficers.sort((a, b) {
                final dtA = a['_parsedLastActive'] as DateTime?;
                final dtB = b['_parsedLastActive'] as DateTime?;
                if (dtA == null && dtB == null) return 0;
                if (dtA == null) return 1;
                if (dtB == null) return -1;
                return dtB.compareTo(dtA);
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Bar Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 800;

                          final searchField = TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search officer by name, seva number, station...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                          );

                          final stateDropdown = DropdownButtonFormField<String>(
                            key: ValueKey('active_state_$_selectedState'),
                            initialValue: _selectedState,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'State',
                              labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: dynamicStates
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              final newState = val ?? 'All States';
                              setState(() {
                                _selectedState = newState;
                                if (_selectedDistrict != null && !availableDistricts.contains(_selectedDistrict)) {
                                  _selectedDistrict = null;
                                }
                              });
                            },
                          );

                          final districtDropdown = DropdownButtonFormField<String?>(
                            key: ValueKey('active_dist_${_selectedState}_$_selectedDistrict'),
                            initialValue: _selectedDistrict,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: _selectedState != 'All States' ? 'District ($_selectedState)' : 'District',
                              labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Districts', style: TextStyle(fontSize: 13)),
                              ),
                              ...availableDistricts.map((d) => DropdownMenuItem<String?>(
                                    value: d,
                                    child: Text(d, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedDistrict = val),
                          );

                          final clearBtn = _hasActiveFilters
                              ? TextButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16, color: Color(0xFFEF4444)),
                                  label: const Text('Clear Filters', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              : const SizedBox.shrink();

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(flex: 3, child: searchField),
                                const SizedBox(width: 12),
                                Expanded(flex: 2, child: stateDropdown),
                                const SizedBox(width: 12),
                                Expanded(flex: 2, child: districtDropdown),
                                if (_hasActiveFilters) ...[
                                  const SizedBox(width: 8),
                                  clearBtn,
                                ],
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                searchField,
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(child: stateDropdown),
                                    const SizedBox(width: 10),
                                    Expanded(child: districtDropdown),
                                  ],
                                ),
                                if (_hasActiveFilters) ...[
                                  const SizedBox(height: 6),
                                  Align(alignment: Alignment.centerRight, child: clearBtn),
                                ],
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Active Officers Table Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Active Officers Roster (${filteredOfficers.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF059669)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Active in last 30 days',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (filteredOfficers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.person_off_outlined, size: 44, color: Color(0xFF94A3B8)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No active officers found matching your search and filter criteria.',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    if (_hasActiveFilters) ...[
                                      const SizedBox(height: 10),
                                      TextButton.icon(
                                        onPressed: _clearFilters,
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          else
                            Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 800),
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                    dataRowMinHeight: 56,
                                    dataRowMaxHeight: 64,
                                    columns: const [
                                      DataColumn(label: Text('Officer Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Police Station', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Jurisdiction', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Seva Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Last Active', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                    ],
                                    rows: filteredOfficers.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final data = entry.value;
                                      final name = (data['name'] ?? data['displayName'] ?? data['fullName'] ?? 'Officer').toString();
                                      final desig = (data['designation'] ?? 'PSI').toString().toUpperCase();
                                      final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Station Unassigned').toString();
                                      final district = (data['district'] ?? data['city'] ?? 'Nagpur').toString();
                                      final state = (data['state'] ?? 'Maharashtra').toString();
                                      final seva = (data['sevaNumber'] ?? data['badgeNumber'])?.toString().trim();

                                      final lastActiveDt = data['_parsedLastActive'] as DateTime?;
                                      final isLive = lastActiveDt != null && DateTime.now().difference(lastActiveDt).inMinutes < 10;
                                      final timeText = _formatRelativeTime(lastActiveDt);

                                      // Rank Color Palette
                                      Color rankColor = const Color(0xFF2563EB);
                                      Color rankBg = const Color(0xFFEFF6FF);
                                      if (['CP', 'DCP', 'SP', 'ACP', 'COMMISSIONER', 'DY. SP'].contains(desig)) {
                                        rankColor = const Color(0xFFD97706);
                                        rankBg = const Color(0xFFFEF3C7);
                                      } else if (['PI', 'SR. PI'].contains(desig)) {
                                        rankColor = const Color(0xFF4F46E5);
                                        rankBg = const Color(0xFFEEF2FF);
                                      } else if (['API', 'PSI', 'ASI'].contains(desig)) {
                                        rankColor = const Color(0xFF0D9488);
                                        rankBg = const Color(0xFFF0FDFA);
                                      }

                                      return DataRow(
                                        onSelectChanged: (_) => _showOfficerProfileDialog(context, data),
                                        color: WidgetStateProperty.resolveWith<Color?>((states) {
                                          if (states.contains(WidgetState.hovered)) {
                                            return const Color(0xFFF1F5F9);
                                          }
                                          return index % 2 == 1 ? const Color(0xFFFAFAFA) : Colors.white;
                                        }),
                                        cells: [
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: rankBg,
                                                  child: Text(
                                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 11.5,
                                                      color: rankColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  name,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: rankBg,
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                desig,
                                                style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 10.5),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              station,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '$district, $state',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              seva != null && seva.isNotEmpty && seva != 'null' ? seva : '—',
                                              style: TextStyle(
                                                color: seva != null && seva.isNotEmpty && seva != 'null' ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isLive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: isLive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 3,
                                                    backgroundColor: isLive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    timeText,
                                                    style: TextStyle(
                                                      color: isLive ? const Color(0xFF059669) : const Color(0xFF64748B),
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 10.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// 🛡️ In-Portal Dedicated Approvals Management View
class _ApprovalsDetailView extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<int>? onNavigate;

  const _ApprovalsDetailView({
    required this.onBack,
    this.onNavigate,
  });

  @override
  State<_ApprovalsDetailView> createState() => _ApprovalsDetailViewState();
}

class _ApprovalsDetailViewState extends State<_ApprovalsDetailView> {
  int _currentTab = 0; // 0: Pending, 1: Approved, 2: Rejected, 3: All
  String _searchQuery = '';
  String _selectedState = 'All States';
  String? _selectedDistrict;
  final TextEditingController _searchController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedState = 'All States';
      _selectedDistrict = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  bool get _hasActiveFilters =>
      _selectedState != 'All States' || _selectedDistrict != null || _searchQuery.isNotEmpty;

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _approveOfficer(BuildContext context, String docId, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 22),
            SizedBox(width: 10),
            Text('Approve Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to approve the officer registration for "$name"? They will immediately gain access to the Police Management system.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve Officer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'accountStatus': 'active',
        'status': 'active',
        'actionedByName': 'Master Admin',
        'actionedByRole': 'Master Admin',
        'actionedBy': 'Master Admin',
        'approvedByName': 'Master Admin',
        'approvedByRole': 'Master Admin',
        'approvedAt': FieldValue.serverTimestamp(),
        'actionedAt': FieldValue.serverTimestamp(),
      });

      await AuditService.logAction(
        action: 'APPROVED',
        targetUserId: docId,
        details: 'Approved registration for $name by Master Admin',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Successfully approved registration for $name')),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            width: 440,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to approve officer: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            width: 440,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectOfficer(BuildContext context, String docId, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    String selectedReason = 'Invalid Government Email / Credentials';
    final customReasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 10),
              Text('Reject Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to reject the registration for "$name"?',
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 16),
                const Text('Select Reason for Rejection:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey('reject_reason_$selectedReason'),
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Invalid Government Email / Credentials', child: Text('Invalid Government Email / Credentials', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Unverified Seva / Badge Number', child: Text('Unverified Seva / Badge Number', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Incorrect Police Station jurisdiction', child: Text('Incorrect Police Station jurisdiction', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Unclear or Missing ID card photo', child: Text('Unclear or Missing ID card photo', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Duplicate Account Registration', child: Text('Duplicate Account Registration', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Other Reason', child: Text('Other Reason', style: TextStyle(fontSize: 12.5))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedReason = val);
                  },
                ),
                if (selectedReason == 'Other Reason') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter specific reason for rejection...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reject Registration', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final finalReason = selectedReason == 'Other Reason' && customReasonController.text.trim().isNotEmpty
        ? customReasonController.text.trim()
        : selectedReason;

    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'accountStatus': 'rejected',
        'status': 'rejected',
        'rejectionReason': finalReason,
        'actionedByName': 'Master Admin',
        'actionedByRole': 'Master Admin',
        'actionedBy': 'Master Admin',
        'rejectedByName': 'Master Admin',
        'rejectedByRole': 'Master Admin',
        'rejectedAt': FieldValue.serverTimestamp(),
        'actionedAt': FieldValue.serverTimestamp(),
      });

      await AuditService.logAction(
        action: 'REJECTED',
        targetUserId: docId,
        details: 'Rejected registration for $name. Reason: $finalReason by Master Admin',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Rejected registration for $name')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            width: 440,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to reject registration: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            width: 440,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectionReasonDialog(BuildContext context, String name, String reason, String actionedBy, DateTime? rejectedAt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 10),
            Text('Rejection Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Officer: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason Recorded:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  const SizedBox(height: 4),
                  Text(
                    reason.isNotEmpty ? reason : 'No specific reason provided at rejection.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text('Actioned By: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(actionedBy, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            if (rejectedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text('Rejected Date: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(_formatDate(rejectedAt), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRegistrationDossier(BuildContext context, Map<String, dynamic> data) {
    final docId = (data['docId'] ?? '').toString();
    final name = (data['name'] ?? data['displayName'] ?? data['fullName'] ?? 'Officer').toString();
    final desig = (data['designation'] ?? 'PSI').toString().toUpperCase();
    final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Station Unassigned').toString();
    final district = (data['district'] ?? data['city'] ?? 'Jurisdiction').toString();
    final state = (data['state'] ?? 'Maharashtra').toString();
    final seva = (data['sevaNumber'] ?? data['badgeNumber'] ?? '—').toString();
    final phone = (data['phoneNumber'] ?? data['phone'] ?? data['contact'] ?? '—').toString();
    final email = (data['email'] ?? '—').toString();
    final status = (data['accountStatus'] ?? data['status'] ?? 'pending').toString().toLowerCase();
    final createdAt = _parseDate(data['createdAt'] ?? data['submittedAt'] ?? data['timestamp']);
    final idCardUrl = (data['idCardUrl'] ?? data['idCardPhoto'] ?? '').toString();
    final rejectionReason = (data['rejectionReason'] ?? data['rejectReason'] ?? data['reason'] ?? '').toString().trim();
    final actionedBy = _getActionedByString(data);
    final rejectedAt = _parseDate(data['rejectedAt'] ?? data['actionedAt']);
    final isPending = status == 'pending_approval' || status == 'pending';
    final isRejected = status == 'rejected';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                desig,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFE2E8F0)),

              if (isRejected) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 16),
                          SizedBox(width: 6),
                          Text('Rejection Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFDC2626))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${rejectionReason.isNotEmpty ? rejectionReason : "No reason specified"}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                      ),
                      if (actionedBy != '—') ...[
                        const SizedBox(height: 2),
                        Text('Actioned By: $actionedBy', style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D))),
                      ],
                      if (rejectedAt != null) ...[
                        const SizedBox(height: 1),
                        Text('Rejected Date: ${_formatDate(rejectedAt)}', style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D))),
                      ],
                    ],
                  ),
                ),
              ],

              _buildDossierRow(Icons.location_city_outlined, 'Assigned Station', station),
              _buildDossierRow(Icons.map_outlined, 'Jurisdiction', '$district, $state'),
              _buildDossierRow(Icons.badge_outlined, 'Seva / Badge No.', seva),
              _buildDossierRow(Icons.phone_outlined, 'Contact Phone', phone),
              _buildDossierRow(Icons.email_outlined, 'Official Email', email),
              _buildDossierRow(Icons.calendar_today_outlined, 'Submitted Date', _formatDate(createdAt)),
              if (!isPending) _buildDossierRow(Icons.verified_user_outlined, 'Actioned By', actionedBy),

              if (idCardUrl.isNotEmpty && idCardUrl.startsWith('http')) ...[
                const SizedBox(height: 12),
                const Text('Verification ID Document:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    idCardUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stackTrace) => Container(
                      height: 60,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(child: Text('Document preview unavailable', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _rejectOfficer(context, docId, name);
                      },
                      icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                      label: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _approveOfficer(context, docId, name);
                      },
                      icon: const Icon(Icons.check_rounded, size: 15),
                      label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDossierRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _getActionedByString(Map<String, dynamic> data) {
    final status = (data['accountStatus'] ?? data['status'] ?? 'pending').toString().toLowerCase();
    if (status == 'pending_approval' || status == 'pending') return '—';

    final name = (data['actionedByName'] ?? data['approvedByName'] ?? data['rejectedByName'] ?? data['actionedBy'])?.toString().trim();
    final role = (data['actionedByRole'] ?? data['approvedByRole'] ?? data['rejectedByRole'])?.toString().trim();

    if (name != null && name.isNotEmpty && name != 'null') {
      if (role != null && role.isNotEmpty && role != 'null' && !name.contains(role)) {
        return '$name ($role)';
      }
      return name;
    }

    if (status == 'active' || status == 'approved') return 'Master Admin';
    if (status == 'rejected') return 'Master Admin';
    return '—';
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    Color bg = const Color(0xFFFEF3C7);
    Color border = const Color(0xFFFDE68A);
    Color text = const Color(0xFFD97706);
    String label = 'Pending';

    if (s == 'active' || s == 'approved') {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      text = const Color(0xFF059669);
      label = 'Approved';
    } else if (s == 'rejected') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Back Button
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Officer Registration Approvals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Review, verify credentials, approve or reject police personnel registration requests',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Live Firestore Stream of all users
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(60.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                  ),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];
              final List<Map<String, dynamic>> allUsers = [];
              final List<Map<String, dynamic>> pendingUsers = [];
              final List<Map<String, dynamic>> approvedUsers = [];
              final List<Map<String, dynamic>> rejectedUsers = [];
              final Set<String> dynamicStates = {'All States'};
              final Map<String, Set<String>> dynamicDistrictsByState = {};

              for (final doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                if (AppConstants.isAdminUser(data)) continue; // Strictly exclude admin accounts

                final userItem = {
                  ...data,
                  'docId': doc.id,
                };

                allUsers.add(userItem);
                if (AppConstants.isPendingApproval(data)) {
                  pendingUsers.add(userItem);
                } else if (AppConstants.isApprovedOfficer(data)) {
                  approvedUsers.add(userItem);
                } else if (AppConstants.isRejectedOfficer(data)) {
                  rejectedUsers.add(userItem);
                }

                final state = (data['state'] ?? 'Maharashtra').toString().trim();
                final district = (data['district'] ?? data['city'] ?? 'Nagpur').toString().trim();
                if (state.isNotEmpty) {
                  dynamicStates.add(state);
                  dynamicDistrictsByState.putIfAbsent(state, () => <String>{}).add(district);
                }
              }

              // Dynamic District list based on selected state
              final List<String> availableDistricts = [];
              if (_selectedState == 'All States') {
                final set = <String>{};
                for (final dSet in dynamicDistrictsByState.values) {
                  set.addAll(dSet);
                }
                availableDistricts.addAll(set);
              } else {
                availableDistricts.addAll(dynamicDistrictsByState[_selectedState] ?? []);
              }
              availableDistricts.sort();

              // Filter based on active tab
              List<Map<String, dynamic>> targetList;
              if (_currentTab == 0) {
                targetList = pendingUsers;
              } else if (_currentTab == 1) {
                targetList = approvedUsers;
              } else if (_currentTab == 2) {
                targetList = rejectedUsers;
              } else {
                targetList = allUsers;
              }

              // Apply Search Query and State/District filters
              final filteredList = targetList.where((user) {
                final state = (user['state'] ?? 'Maharashtra').toString();
                final district = (user['district'] ?? user['city'] ?? '').toString();

                if (_selectedState != 'All States' && state.toLowerCase() != _selectedState.toLowerCase()) {
                  return false;
                }
                if (_selectedDistrict != null && district.toLowerCase() != _selectedDistrict!.toLowerCase()) {
                  return false;
                }

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  final name = (user['name'] ?? user['displayName'] ?? user['fullName'] ?? '').toString().toLowerCase();
                  final desig = (user['designation'] ?? '').toString().toLowerCase();
                  final station = (user['stationName'] ?? user['station'] ?? user['assignedStation'] ?? '').toString().toLowerCase();
                  final seva = (user['sevaNumber'] ?? user['badgeNumber'] ?? '').toString().toLowerCase();
                  final phone = (user['phoneNumber'] ?? user['phone'] ?? '').toString().toLowerCase();
                  return name.contains(q) || desig.contains(q) || station.contains(q) || seva.contains(q) || phone.contains(q);
                }
                return true;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter and Tabs Bar Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Tab Selection Pills
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTabPill(0, 'Pending', pendingUsers.length, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                                const SizedBox(width: 8),
                                _buildTabPill(1, 'Approved', approvedUsers.length, const Color(0xFF059669), const Color(0xFFECFDF5)),
                                const SizedBox(width: 8),
                                _buildTabPill(2, 'Rejected', rejectedUsers.length, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
                                const SizedBox(width: 8),
                                _buildTabPill(3, 'All Requests', allUsers.length, const Color(0xFF1D4ED8), const Color(0xFFEFF6FF)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Search and State/District Filters
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 800;

                              final searchField = TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Search requests by officer name, seva number, designation, station...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                              );

                              final stateDropdown = DropdownButtonFormField<String>(
                                key: ValueKey('approval_state_$_selectedState'),
                                initialValue: _selectedState,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'State',
                                  labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF64748B)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                items: dynamicStates
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  final newState = val ?? 'All States';
                                  setState(() {
                                    _selectedState = newState;
                                    if (_selectedDistrict != null && !availableDistricts.contains(_selectedDistrict)) {
                                      _selectedDistrict = null;
                                    }
                                  });
                                },
                              );

                              final districtDropdown = DropdownButtonFormField<String?>(
                                key: ValueKey('approval_dist_${_selectedState}_$_selectedDistrict'),
                                initialValue: _selectedDistrict,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: _selectedState != 'All States' ? 'District ($_selectedState)' : 'District',
                                  labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All Districts', style: TextStyle(fontSize: 13)),
                                  ),
                                  ...availableDistricts.map((d) => DropdownMenuItem<String?>(
                                        value: d,
                                        child: Text(d, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                      )),
                                ],
                                onChanged: (val) => setState(() => _selectedDistrict = val),
                              );

                              final clearBtn = _hasActiveFilters
                                  ? TextButton.icon(
                                      onPressed: _clearFilters,
                                      icon: const Icon(Icons.filter_alt_off_rounded, size: 16, color: Color(0xFFEF4444)),
                                      label: const Text('Clear Filters', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                                    )
                                  : const SizedBox.shrink();

                              if (isWide) {
                                return Row(
                                  children: [
                                    Expanded(flex: 3, child: searchField),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 2, child: stateDropdown),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 2, child: districtDropdown),
                                    if (_hasActiveFilters) ...[
                                      const SizedBox(width: 8),
                                      clearBtn,
                                    ],
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    searchField,
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: stateDropdown),
                                        const SizedBox(width: 10),
                                        Expanded(child: districtDropdown),
                                      ],
                                    ),
                                    if (_hasActiveFilters) ...[
                                      const SizedBox(height: 6),
                                      Align(alignment: Alignment.centerRight, child: clearBtn),
                                    ],
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Approvals Table Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.pending_actions_outlined, color: Color(0xFF1D4ED8), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _getTabHeading(_currentTab, filteredList.length),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              if (_isProcessing)
                                const Row(
                                  children: [
                                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D4ED8))),
                                    SizedBox(width: 8),
                                    Text('Processing update...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (filteredList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(48.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      _currentTab == 0 ? Icons.check_circle_outline_rounded : Icons.folder_open_outlined,
                                      size: 46,
                                      color: _currentTab == 0 ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _getEmptyMessage(_currentTab, _hasActiveFilters),
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5, fontWeight: FontWeight.w600),
                                    ),
                                    if (_hasActiveFilters) ...[
                                      const SizedBox(height: 10),
                                      TextButton.icon(
                                        onPressed: _clearFilters,
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          else
                            Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 940),
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 68,
                                    columns: const [
                                      DataColumn(label: Text('Officer Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Police Station', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Seva No. / Phone', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Request Date', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Actioned By', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                      DataColumn(label: Text('Master Admin Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                    ],
                                    rows: filteredList.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final data = entry.value;
                                      final docId = data['docId'] as String;
                                      final name = (data['name'] ?? data['displayName'] ?? data['fullName'] ?? 'Officer').toString();
                                      final desig = (data['designation'] ?? 'PSI').toString().toUpperCase();
                                      final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'] ?? 'Station Unassigned').toString();
                                      final seva = (data['sevaNumber'] ?? data['badgeNumber'])?.toString().trim();
                                      final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
                                      final status = (data['accountStatus'] ?? data['status'] ?? 'pending').toString().toLowerCase();
                                      final createdAt = _parseDate(data['createdAt'] ?? data['submittedAt'] ?? data['timestamp']);
                                      final rejectionReason = (data['rejectionReason'] ?? data['rejectReason'] ?? data['reason'] ?? '').toString().trim();
                                      final actionedBy = _getActionedByString(data);
                                      final rejectedAt = _parseDate(data['rejectedAt'] ?? data['actionedAt']);
                                      final isPending = status == 'pending_approval' || status == 'pending';
                                      final isRejected = status == 'rejected';

                                      Color rankColor = const Color(0xFF2563EB);
                                      Color rankBg = const Color(0xFFEFF6FF);
                                      if (['CP', 'DCP', 'SP', 'ACP', 'COMMISSIONER', 'DY. SP'].contains(desig)) {
                                        rankColor = const Color(0xFFD97706);
                                        rankBg = const Color(0xFFFEF3C7);
                                      } else if (['PI', 'SR. PI'].contains(desig)) {
                                        rankColor = const Color(0xFF4F46E5);
                                        rankBg = const Color(0xFFEEF2FF);
                                      }

                                      return DataRow(
                                        onSelectChanged: (_) => _showRegistrationDossier(context, data),
                                        color: WidgetStateProperty.resolveWith<Color?>((states) {
                                          if (states.contains(WidgetState.hovered)) {
                                            return const Color(0xFFF1F5F9);
                                          }
                                          return index % 2 == 1 ? const Color(0xFFFAFAFA) : Colors.white;
                                        }),
                                        cells: [
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: rankBg,
                                                  child: Text(
                                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 11.5,
                                                      color: rankColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  name,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: rankBg,
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                desig,
                                                style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 10.5),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              station,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  seva != null && seva.isNotEmpty && seva != 'null' ? seva : '—',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                                ),
                                                if (phone.isNotEmpty)
                                                  Text(
                                                    phone,
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _formatDate(createdAt),
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildStatusBadge(status),
                                                if (isRejected && rejectionReason.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  InkWell(
                                                    onTap: () => _showRejectionReasonDialog(context, name, rejectionReason, actionedBy, rejectedAt),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Tooltip(
                                                      message: 'Click to view rejection reason:\n$rejectionReason',
                                                      child: Container(
                                                        padding: const EdgeInsets.all(3),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFEF2F2),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: const Color(0xFFFECACA)),
                                                        ),
                                                        child: const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (actionedBy != '—')
                                                  Icon(
                                                    status == 'rejected' ? Icons.cancel_outlined : Icons.verified_user_outlined,
                                                    size: 13,
                                                    color: status == 'rejected' ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                                  ),
                                                if (actionedBy != '—') const SizedBox(width: 4),
                                                Text(
                                                  actionedBy,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: actionedBy != '—' ? FontWeight.w600 : FontWeight.normal,
                                                    color: actionedBy != '—' ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            isPending
                                                ? Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ElevatedButton.icon(
                                                        onPressed: _isProcessing ? null : () => _approveOfficer(context, docId, name),
                                                        icon: const Icon(Icons.check_rounded, size: 14),
                                                        label: const Text('Approve', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF059669),
                                                          foregroundColor: Colors.white,
                                                          elevation: 0,
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      OutlinedButton.icon(
                                                        onPressed: _isProcessing ? null : () => _rejectOfficer(context, docId, name),
                                                        icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                                                        label: const Text('Reject', style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                                        style: OutlinedButton.styleFrom(
                                                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                                                          backgroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      OutlinedButton.icon(
                                                        onPressed: () => _showRegistrationDossier(context, data),
                                                        icon: const Icon(Icons.visibility_outlined, size: 14),
                                                        label: const Text('View Dossier', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: const Color(0xFF475569),
                                                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                      ),
                                                      if (isRejected && rejectionReason.isNotEmpty) ...[
                                                        const SizedBox(width: 6),
                                                        TextButton.icon(
                                                          onPressed: () => _showRejectionReasonDialog(context, name, rejectionReason, actionedBy, rejectedAt),
                                                          icon: const Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                                                          label: const Text('Reason', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                                          style: TextButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                            visualDensity: VisualDensity.compact,
                                                          ),
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
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label, int count, Color activeColor, Color activeBg) {
    final isSelected = _currentTab == index;

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTabHeading(int tab, int count) {
    switch (tab) {
      case 0:
        return 'Pending Approval Requests ($count)';
      case 1:
        return 'Approved Officers ($count)';
      case 2:
        return 'Rejected Requests ($count)';
      default:
        return 'All Registration Records ($count)';
    }
  }

  String _getEmptyMessage(int tab, bool isFiltered) {
    if (isFiltered) {
      return 'No registration records match your filter & search criteria.';
    }
    switch (tab) {
      case 0:
        return 'No pending approval requests. All officer registrations are up to date!';
      case 1:
        return 'No approved officers found in this view.';
      case 2:
        return 'No rejected registration requests.';
      default:
        return 'No registration records found in the database.';
    }
  }
}
