import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../utils/app_constants.dart';

/// Two-Way Departmental Notifications & Alert Center for Master Admin
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Send Notification Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedPriority = 'General';
  String _selectedTargetType = 'ALL'; // ALL, STATE, DISTRICT, STATION, OFFICER
  String? _selectedState = 'Maharashtra';
  String? _selectedDistrict = 'Nagpur City';
  String? _selectedStation = 'Sitabuldi PS';
  String? _selectedOfficerId;
  String? _selectedOfficerName;
  bool _isSending = false;

  // Tab 2: Received Alerts Filter State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilterState = 'All States';
  String _selectedFilterDistrict = 'All Districts';
  String _selectedFilterStation = 'All Stations';
  String _selectedStatusFilter = 'All'; // All, Unread Only, Read
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Seed sample incoming officer notices if collection is empty
  void _checkAndSeedIfEmpty(List<QueryDocumentSnapshot> docs) {
    if (_seeded || docs.isNotEmpty) return;
    _seeded = true;
    final collection = FirebaseFirestore.instance.collection('officer_notices');
    final now = DateTime.now();

    final seedItems = [
      {
        'officerId': 'officer_pappu',
        'officerName': 'Pappu Jagtap',
        'sevaNumber': 'SEVA-88219',
        'designation': 'JT. CP',
        'stationName': 'Rajapeth Police Station',
        'district': 'Amravati City',
        'state': 'Maharashtra',
        'title': 'Bandobast Reinforcement Request',
        'message': 'VIP convoy movement scheduled along NH-6 on 22nd Aug. Requesting deployment of 2 additional interceptor squads and traffic clearance protocols.',
        'priority': 'Urgent',
        'isRead': false,
        'status': 'Unread',
        'createdAt': FieldValue.serverTimestamp(),
        'timestampStr': now.subtract(const Duration(minutes: 18)).toIso8601String(),
      },
      {
        'officerId': 'officer_rohit',
        'officerName': 'Rohit KC',
        'sevaNumber': 'SEVA-44102',
        'designation': 'PI',
        'stationName': 'Sitabuldi Police Station',
        'district': 'Nagpur City',
        'state': 'Maharashtra',
        'title': 'Malkhana Arms Verification Completed',
        'message': 'Quarterly forensic armory physical audit completed for Sitabuldi precinct. All registered seizure units and digital seals reconciled with court registry.',
        'priority': 'Normal',
        'isRead': false,
        'status': 'Unread',
        'createdAt': FieldValue.serverTimestamp(),
        'timestampStr': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'officerId': 'officer_priti',
        'officerName': 'Priti W',
        'sevaNumber': 'SEVA-55194',
        'designation': 'ASI',
        'stationName': 'Baloda Bazar Police Station 1',
        'district': 'Baloda Bazar',
        'state': 'Chhattisgarh',
        'title': 'Cyber Crime Evidence Sync Advisory',
        'message': 'Extracted call detail records (CDR) for pending kidnap inquiry synced to secure investigation locker. Requesting forensic analyst sign-off.',
        'priority': 'Advisory',
        'isRead': true,
        'status': 'Read',
        'createdAt': FieldValue.serverTimestamp(),
        'timestampStr': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'officerId': 'officer_namaste',
        'officerName': 'Namaste N',
        'sevaNumber': 'SEVA-33100',
        'designation': 'HEAD CONSTABLE',
        'stationName': 'Kutch Police Station 1',
        'district': 'Kutch',
        'state': 'Gujarat',
        'title': 'Night Patrol Beat Route Adjustment',
        'message': 'Coastal border highway checkpoint temporary road diversion active due to bridge maintenance. Patrol vehicle logs adjusted accordingly.',
        'priority': 'Normal',
        'isRead': true,
        'status': 'Read',
        'createdAt': FieldValue.serverTimestamp(),
        'timestampStr': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];

    for (final item in seedItems) {
      collection.add(item);
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTargetType == 'OFFICER' && _selectedOfficerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an officer from the list'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      String targetValue = 'All Police Personnel (Nationwide)';
      if (_selectedTargetType == 'STATE') {
        targetValue = _selectedState ?? 'All States';
      } else if (_selectedTargetType == 'DISTRICT') {
        targetValue = '$_selectedDistrict ($_selectedState)';
      } else if (_selectedTargetType == 'STATION') {
        targetValue = '$_selectedStation ($_selectedDistrict)';
      } else if (_selectedTargetType == 'OFFICER') {
        targetValue = _selectedOfficerName ?? 'Targeted Officer';
      }

      final now = DateTime.now();
      final adminUser = FirebaseAuth.instance.currentUser;

      final payload = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _selectedPriority,
        'targetType': _selectedTargetType,
        'targetValue': targetValue,
        'state': _selectedState,
        'district': _selectedDistrict,
        'stationName': _selectedStation,
        'targetOfficerId': _selectedOfficerId,
        'targetOfficerName': _selectedOfficerName,
        'senderId': adminUser?.uid ?? 'master_admin',
        'senderName': 'Master Admin',
        'createdAt': FieldValue.serverTimestamp(),
        'timestampStr': now.toIso8601String(),
        'readBy': <String>[],
        'isBroadcast': _selectedTargetType == 'ALL',
      };

      await FirebaseFirestore.instance.collection('notifications').add(payload);

      // Audit the dispatch action
      await AuditService.logAction(
        action: 'NOTIFICATION_DISPATCH',
        targetUserId: _selectedOfficerId ?? _selectedTargetType,
        details: 'Dispatched $_selectedPriority notification "${_titleController.text.trim()}" to $targetValue',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Notification successfully sent to $targetValue'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );

        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedOfficerId = null;
          _selectedOfficerName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'critical':
        return const Color(0xFFDC2626);
      case 'advisory':
        return const Color(0xFFD97706);
      case 'departmental':
        return const Color(0xFF4F46E5);
      case 'general':
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return 'Recent';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is DateTime) dt = raw;
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return 'Recent';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 🏷️ Clean Header Banner with Top Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1D4ED8), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications & Alert Center',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Two-way departmental alert dispatch, targeting & live incoming officer notices',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Top Navigation Sub-Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFF1D4ED8),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF1D4ED8),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  tabs: [
                    const Tab(
                      iconMargin: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.send_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Send Notification (Dispatch)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('officer_notices')
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data?.docs.length ?? 0;
                          return Row(
                            children: [
                              const Icon(Icons.inbox_rounded, size: 16),
                              const SizedBox(width: 8),
                              const Text('Received Alerts & Notices'),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📄 Tab Views Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendNotificationTab(theme),
                _buildReceivedAlertsTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📤 TAB 1: SEND NOTIFICATION (COMPOSER & OUTBOX)
  // ===========================================================================
  Widget _buildSendNotificationTab(ThemeData theme) {
    final districts = AppConstants.getDistrictsForState(_selectedState);
    final stations = AppConstants.getStationsForDistrict(_selectedDistrict);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📝 Composer Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.campaign_rounded, color: Color(0xFF1D4ED8), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Compose Departmental Broadcast / Alert',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Priority Selector & Target Scope Row
                    Wrap(
                      spacing: 16,
                      runSpacing: 14,
                      children: [
                        // Priority
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority Level',
                              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'General', child: Text('🔵 General Notice')),
                              DropdownMenuItem(value: 'Advisory', child: Text('🟠 Advisory / Memo')),
                              DropdownMenuItem(value: 'Urgent', child: Text('🔴 Urgent Order')),
                              DropdownMenuItem(value: 'Critical', child: Text('🟣 Critical Operational')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPriority = val);
                            },
                          ),
                        ),

                        // Target Scope
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedTargetType,
                            decoration: InputDecoration(
                              labelText: 'Send To (Target Scope)',
                              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('📢 Broadcast (All Officers)')),
                              DropdownMenuItem(value: 'STATE', child: Text('🏛️ State-wise Broadcast')),
                              DropdownMenuItem(value: 'DISTRICT', child: Text('📍 District-wise Broadcast')),
                              DropdownMenuItem(value: 'STATION', child: Text('🏢 Specific Police Station')),
                              DropdownMenuItem(value: 'OFFICER', child: Text('👤 Specific Individual Officer')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTargetType = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dynamic Sub-Selectors based on Target Scope
                    if (_selectedTargetType != 'ALL') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            // State Dropdown
                            if (_selectedTargetType == 'STATE' || _selectedTargetType == 'DISTRICT' || _selectedTargetType == 'STATION')
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedState,
                                  decoration: InputDecoration(
                                    labelText: 'Select State',
                                    labelStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                  items: AppConstants.allIndiaStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedState = val;
                                        final dists = AppConstants.getDistrictsForState(val);
                                        _selectedDistrict = dists.isNotEmpty ? dists.first : null;
                                        final sts = AppConstants.getStationsForDistrict(_selectedDistrict);
                                        _selectedStation = sts.isNotEmpty ? sts.first : null;
                                      });
                                    }
                                  },
                                ),
                              ),

                            // District Dropdown
                            if (_selectedTargetType == 'DISTRICT' || _selectedTargetType == 'STATION')
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String>(
                                  initialValue: districts.contains(_selectedDistrict) ? _selectedDistrict : (districts.isNotEmpty ? districts.first : null),
                                  decoration: InputDecoration(
                                    labelText: 'Select District / City',
                                    labelStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                  items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedDistrict = val;
                                        final sts = AppConstants.getStationsForDistrict(val);
                                        _selectedStation = sts.isNotEmpty ? sts.first : null;
                                      });
                                    }
                                  },
                                ),
                              ),

                            // Police Station Dropdown
                            if (_selectedTargetType == 'STATION')
                              SizedBox(
                                width: 240,
                                child: DropdownButtonFormField<String>(
                                  initialValue: stations.contains(_selectedStation) ? _selectedStation : (stations.isNotEmpty ? stations.first : null),
                                  decoration: InputDecoration(
                                    labelText: 'Select Police Station',
                                    labelStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                  items: stations.map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedStation = val);
                                  },
                                ),
                              ),

                            // Individual Officer Live Selector
                            if (_selectedTargetType == 'OFFICER')
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                                builder: (context, snapshot) {
                                  final officerDocs = snapshot.data?.docs.where((d) {
                                    final data = d.data() as Map<String, dynamic>;
                                    return AppConstants.isApprovedOfficer(data);
                                  }).toList() ?? [];

                                  return SizedBox(
                                    width: 320,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedOfficerId,
                                      decoration: InputDecoration(
                                        labelText: 'Select Officer Personnel',
                                        labelStyle: const TextStyle(fontSize: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      hint: const Text('Search & select officer', style: TextStyle(fontSize: 12)),
                                      items: officerDocs.map((d) {
                                        final data = d.data() as Map<String, dynamic>;
                                        final name = (data['name'] ?? data['fullName'] ?? 'Officer').toString();
                                        final desig = (data['designation'] ?? data['rank'] ?? 'IO').toString().toUpperCase();
                                        final station = (data['stationName'] ?? data['station'] ?? 'Station').toString();
                                        return DropdownMenuItem(
                                          value: d.id,
                                          child: Text(
                                            '$name ($desig) • $station',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12.5),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final selectedDoc = officerDocs.firstWhere((d) => d.id == val);
                                          final data = selectedDoc.data() as Map<String, dynamic>;
                                          setState(() {
                                            _selectedOfficerId = val;
                                            _selectedOfficerName = (data['name'] ?? data['fullName'] ?? 'Officer').toString();
                                          });
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Notification Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Notification Subject / Title',
                        hintText: 'e.g. Special Law & Order Advisory for Independence Day Protocol',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),

                    // Notification Message Body
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Detailed Message Body & Instructions',
                        hintText: 'Enter complete departmental instructions, directives, or operational advisory here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter message content' : null,
                    ),
                    const SizedBox(height: 20),

                    // Submit Action Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendNotification,
                        icon: _isSending
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(_isSending ? 'Transmitting...' : 'Dispatch Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // 📜 Dispatched History Header
          const Row(
            children: [
              Icon(Icons.history_edu_rounded, size: 20, color: Color(0xFF1D4ED8)),
              SizedBox(width: 8),
              Text(
                'Dispatched Notification History & Outbox',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dispatched Stream List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .limit(25)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.mark_email_read_outlined, size: 40, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 10),
                      Text('No previous dispatched notifications found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Notice';
                  final message = data['message'] ?? '';
                  final priority = (data['priority'] ?? 'General').toString();
                  final target = data['targetValue'] ?? 'All Officers';
                  final pColor = _getPriorityColor(priority);
                  final timeStr = _formatTimeAgo(data['createdAt'] ?? data['timestampStr']);

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: pColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: pColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      priority.toUpperCase(),
                                      style: TextStyle(color: pColor, fontSize: 10.5, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.tune_rounded, size: 12, color: Color(0xFF475569)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'To: $target',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(timeStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                                    tooltip: 'Delete notification',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('notifications').doc(docs[index].id).delete();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📥 TAB 2: RECEIVED ALERTS & NOTICES (INCOMING FROM OFFICERS)
  // ===========================================================================
  Widget _buildReceivedAlertsTab(ThemeData theme) {
    final filterDistricts = AppConstants.getDistrictsForState(_selectedFilterState == 'All States' ? null : _selectedFilterState);
    final filterStations = _selectedFilterDistrict == 'All Districts' ? <String>[] : AppConstants.getStationsForDistrict(_selectedFilterDistrict);

    return Column(
      children: [
        // Filter Header Bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Input
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search officer, seva, title...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),

              // State Filter
              SizedBox(
                width: 170,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFilterState,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: ['All States', ...AppConstants.allIndiaStates]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFilterState = val;
                        _selectedFilterDistrict = 'All Districts';
                        _selectedFilterStation = 'All Stations';
                      });
                    }
                  },
                ),
              ),

              // District Filter
              SizedBox(
                width: 170,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFilterDistrict,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: ['All Districts', ...filterDistricts]
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFilterDistrict = val;
                        _selectedFilterStation = 'All Stations';
                      });
                    }
                  },
                ),
              ),

              // Station Filter
              SizedBox(
                width: 180,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFilterStation,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: ['All Stations', ...filterStations]
                      .map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFilterStation = val);
                  },
                ),
              ),

              // Status Filter (All, Unread, Read)
              SizedBox(
                width: 140,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatusFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Unread Only', child: Text('🔴 Unread Only', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Read', child: Text('✅ Read', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatusFilter = val);
                  },
                ),
              ),
            ],
          ),
        ),

        // Live Notices List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('officer_notices')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rawDocs = snapshot.data?.docs ?? [];
              _checkAndSeedIfEmpty(rawDocs);

              // Apply client-side filters
              final filteredDocs = rawDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['officerName'] ?? '').toString().toLowerCase();
                final seva = (data['sevaNumber'] ?? '').toString().toLowerCase();
                final title = (data['title'] ?? '').toString().toLowerCase();
                final message = (data['message'] ?? '').toString().toLowerCase();
                final state = (data['state'] ?? '').toString();
                final district = (data['district'] ?? '').toString();
                final station = (data['stationName'] ?? '').toString();
                final isRead = data['isRead'] == true;

                if (_searchQuery.isNotEmpty) {
                  final match = name.contains(_searchQuery) ||
                      seva.contains(_searchQuery) ||
                      title.contains(_searchQuery) ||
                      message.contains(_searchQuery);
                  if (!match) return false;
                }

                if (_selectedFilterState != 'All States' && state != _selectedFilterState) return false;
                if (_selectedFilterDistrict != 'All Districts' && district != _selectedFilterDistrict) return false;
                if (_selectedFilterStation != 'All Stations' && station != _selectedFilterStation) return false;

                if (_selectedStatusFilter == 'Unread Only' && isRead) return false;
                if (_selectedStatusFilter == 'Read' && !isRead) return false;

                return true;
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Text(
                        'No officer alerts or notices match your filter criteria',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _selectedFilterState = 'All States';
                            _selectedFilterDistrict = 'All Districts';
                            _selectedFilterStation = 'All Stations';
                            _selectedStatusFilter = 'All';
                          });
                        },
                        child: const Text('Reset All Filters'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['officerName'] ?? 'Officer';
                  final desig = data['designation'] ?? 'IO';
                  final seva = data['sevaNumber'] ?? 'N/A';
                  final station = data['stationName'] ?? 'Station';
                  final district = data['district'] ?? '';
                  final title = data['title'] ?? 'Notice';
                  final message = data['message'] ?? '';
                  final priority = (data['priority'] ?? 'Normal').toString();
                  final isRead = data['isRead'] == true;
                  final pColor = _getPriorityColor(priority);
                  final timeStr = _formatTimeAgo(data['createdAt'] ?? data['timestampStr']);

                  return Card(
                    elevation: 0,
                    color: isRead ? Colors.white : const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF93C5FD),
                        width: isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Officer identity + Status badge + Time
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            desig,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: pColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            priority.toUpperCase(),
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$station ${district.isNotEmpty ? "• $district" : ""} • Seva: $seva',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(timeStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 6),
                                  if (!isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF3B82F6)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(radius: 3, backgroundColor: Color(0xFF2563EB)),
                                          SizedBox(width: 4),
                                          Text('NEW', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),

                          // Notice Subject & Content
                          Text(
                            title,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.45),
                          ),

                          const SizedBox(height: 16),

                          // Action Buttons: Mark as Read & Reply
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isRead)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('officer_notices').doc(doc.id).update({
                                      'isRead': true,
                                      'status': 'Read',
                                      'readAt': FieldValue.serverTimestamp(),
                                    });
                                  },
                                  icon: const Icon(Icons.mark_email_read_outlined, size: 14, color: Color(0xFF1D4ED8)),
                                  label: const Text('Mark as Read', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    side: const BorderSide(color: Color(0xFF1D4ED8)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF059669)),
                                    SizedBox(width: 4),
                                    Text('Read & Processed', style: TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
