import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'announcements_view.dart';
import 'audit_logs_view.dart';
import 'cases_view.dart';
import 'dashboard_view.dart';
import 'feedback_view.dart';
import 'notifications_view.dart';
import 'police_stations_view.dart';
import 'officers_directory_view.dart';
import 'settings_view.dart';
import '../services/app_settings_service.dart';
import '../utils/app_constants.dart';

// 🎨 Theme tokens for PMS Admin Shell
const Color kAdminSidebarBg = Color(0xFF151B4D); // #151B4D
const Color kAdminHeaderBg = Color(0xFF1A2159);  // #1A2159

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  String? _casesInitialStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppSettingsService.startApprovalPushNotificationsListener(context);
      }
    });
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.badge_outlined, activeIcon: Icons.badge_rounded, label: 'Officers Directory'),
    _NavItem(icon: Icons.location_city_outlined, activeIcon: Icons.location_city_rounded, label: 'Police Stations'),
    _NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded, label: 'Cases'),
    _NavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, label: 'Carousel & News'),
    _NavItem(icon: Icons.notifications_none_rounded, activeIcon: Icons.notifications_rounded, label: 'Notifications'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: 'Audit Logs'),
    _NavItem(icon: Icons.rate_review_outlined, activeIcon: Icons.rate_review_rounded, label: 'Officer Feedback'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          onNavigate: (index, {String? casesStatus}) {
            setState(() {
              _selectedIndex = index;
              _casesInitialStatus = casesStatus;
            });
          },
        );
      case 1:
        return const OfficersDirectoryView();
      case 2:
        return const PoliceStationsView();
      case 3:
        return CasesView(
          initialStatus: _casesInitialStatus,
        );
      case 4:
        return const AnnouncementsView();
      case 5:
        return const NotificationsView();
      case 6:
        return const AuditLogsView();
      case 7:
        return const FeedbackView();
      case 8:
        return const SettingsView();
      default:
        return Center(
          child: Text(
            'Section Under Construction',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final autoCollapsed = screenWidth < 1000;
    final isExpanded = !autoCollapsed && _isSidebarExpanded;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // 🌟 Custom Responsive Sidebar (#151B4D)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: isExpanded ? 240 : 76,
            decoration: BoxDecoration(
              color: kAdminSidebarBg, // #151B4D
              border: const Border(
                right: BorderSide(color: Color(0xFF282E87), width: 1.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Logo & Header
                Container(
                  height: 68,
                  padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF282E87), width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_police_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PMS Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                'Police Console',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu_open_rounded, size: 20, color: Color(0xFF94A3B8)),
                          tooltip: 'Collapse sidebar',
                          onPressed: () {
                            setState(() {
                              _isSidebarExpanded = false;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Navigation Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    itemCount: _navItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                          final item = _navItems[index];
                          final isSelected = _selectedIndex == index;

                          final buttonChild = Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                  if (index != 3) {
                                    _casesInitialStatus = null;
                                  } else {
                                    _casesInitialStatus = 'All Cases';
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              hoverColor: Colors.white.withValues(alpha: 0.06),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isExpanded ? 12 : 0,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF3E5FEB).withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF3E5FEB).withValues(alpha: 0.4),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          isSelected ? item.activeIcon : item.icon,
                                          size: 20,
                                          color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                                        ),
                                        if (index == 5 && !isExpanded)
                                          StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('officer_notices')
                                                .where('isRead', isEqualTo: false)
                                                .snapshots(),
                                            builder: (context, snapshot) {
                                              final count = snapshot.data?.docs.length ?? 0;
                                              if (count == 0) return const SizedBox.shrink();
                                              return Positioned(
                                                top: -3,
                                                right: -4,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFEF4444),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                    if (isExpanded) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                      ),
                                      if (index == 5)
                                        StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('officer_notices')
                                              .where('isRead', isEqualTo: false)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            final count = snapshot.data?.docs.length ?? 0;
                                            if (count == 0) return const SizedBox.shrink();
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$count',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (!isExpanded) {
                            return Tooltip(
                              message: item.label,
                              preferBelow: false,
                              child: buttonChild,
                            );
                          }

                          return buttonChild;
                        },
                      ),
                ),

                // Bottom Expand Button (when collapsed)
                if (!isExpanded && !autoCollapsed) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF94A3B8)),
                    tooltip: 'Expand sidebar',
                    onPressed: () {
                      setState(() {
                        _isSidebarExpanded = true;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Main View Body
          Expanded(
            child: Column(
              children: [
                // Top Application Header (#1A2159)
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  decoration: const BoxDecoration(
                    color: kAdminHeaderBg, // #1A2159
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF282E87),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF60A5FA),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Police Management System — Admin Console',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Maharashtra State Police • Central Command & Operations',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFFCBD5E1)),
                                  onPressed: () {
                                    setState(() {
                                      _selectedIndex = 0;
                                    });
                                  },
                                );
                              }

                              final allDocs = snapshot.data?.docs ?? [];
                              int pendingCount = 0;
                              for (final doc in allDocs) {
                                final data = doc.data() as Map<String, dynamic>;
                                if (AppConstants.isPendingApproval(data)) {
                                  pendingCount++;
                                }
                              }

                              return Badge(
                                isLabelVisible: pendingCount > 0,
                                label: Text('$pendingCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: const Color(0xFFEF4444),
                                child: IconButton(
                                  icon: Icon(
                                    pendingCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                                    color: pendingCount > 0 ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                                  ),
                                  tooltip: pendingCount > 0
                                      ? 'Pending Approvals ($pendingCount)'
                                      : 'No pending approvals',
                                  onPressed: () {
                                    setState(() {
                                      _selectedIndex = 1;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 28,
                            width: 1,
                            color: const Color(0xFF282E87),
                          ),
                          const SizedBox(width: 12),
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid ?? 'super_admin')
                                .snapshots(),
                            builder: (context, profileSnap) {
                              final data = profileSnap.data?.data() ?? {};
                              final authUser = FirebaseAuth.instance.currentUser;
                              final rawName = (data['name'] ?? data['fullName'] ?? authUser?.displayName)?.toString().trim();
                              final email = (authUser?.email ?? data['email'])?.toString().trim() ?? 'admin@police.gov.in';

                              // Top line: admin's actual name if set (and distinct from role label), otherwise email fallback
                              final String displayName = (rawName != null && rawName.isNotEmpty && rawName != 'Master Admin')
                                  ? rawName
                                  : (email.isNotEmpty ? email : 'Administrator');

                              // Bottom line: admin's role label
                              const String role = 'Master Admin';

                              final String initials = (rawName != null && rawName.isNotEmpty && rawName != 'Master Admin')
                                  ? rawName.split(' ').where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase()).take(2).join()
                                  : 'MA';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF282E87)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 13,
                                      backgroundColor: const Color(0xFF2563EB),
                                      child: Text(
                                        initials.isNotEmpty ? initials : 'MA',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        Text(
                                          role,
                                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Main Content Body
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: _buildMainContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
