import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/case_utils.dart';

class PoliceStationsView extends StatefulWidget {
  const PoliceStationsView({super.key});

  @override
  State<PoliceStationsView> createState() => _PoliceStationsViewState();
}

class _PoliceStationsViewState extends State<PoliceStationsView> {
  String _selectedState = 'All States';
  String? _selectedDistrict;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Selected station for detail view
  String? _selectedStationForDetail;

  final List<String> _states = [
    'All States',
    ...AppConstants.allIndiaStates,
  ];

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

  @override
  Widget build(BuildContext context) {
    // If a station is selected, render the Station Detail View
    if (_selectedStationForDetail != null) {
      return _StationDetailView(
        stationName: _selectedStationForDetail!,
        onBack: () => setState(() => _selectedStationForDetail = null),
      );
    }

    final stateDistricts = AppConstants.getDistrictsForState(_selectedState);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stream Users and Cases together for 100% live data
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('cases').snapshots(),
                builder: (context, caseSnapshot) {
                  final isLoading = (userSnapshot.connectionState == ConnectionState.waiting && !userSnapshot.hasData) ||
                      (caseSnapshot.connectionState == ConnectionState.waiting && !caseSnapshot.hasData);

                  final userDocs = userSnapshot.data?.docs ?? [];
                  final caseDocs = caseSnapshot.data?.docs ?? [];

                  // Aggregate unique stations from live users & cases
                  final Map<String, _StationAggregate> stationsMap = {};

                  for (final doc in userDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final station = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
                    if (station != null && station.isNotEmpty && station.toLowerCase() != 'null') {
                      if (!stationsMap.containsKey(station)) {
                        stationsMap[station] = _StationAggregate(
                          name: station,
                          district: (data['district'] ?? data['city'] ?? 'Nagpur').toString(),
                          state: (data['state'] ?? 'Maharashtra').toString(),
                          status: 'Active',
                        );
                      }
                      if (data['accountStatus'] == 'active' || data['accountStatus'] == null) {
                        stationsMap[station]!.officerCount++;
                        stationsMap[station]!.officers.add(data);
                      }
                    }
                  }

                  // Also check cases to catch stations with filed cases
                  for (final doc in caseDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final station = (data['station'] ?? data['stationName'])?.toString().trim();
                    if (station != null && station.isNotEmpty && station.toLowerCase() != 'null') {
                      if (!stationsMap.containsKey(station)) {
                        stationsMap[station] = _StationAggregate(
                          name: station,
                          district: (data['district'] ?? 'Nagpur').toString(),
                          state: (data['state'] ?? 'Maharashtra').toString(),
                          status: 'Active',
                        );
                      }
                      stationsMap[station]!.totalCases++;
                      if (CaseUtils.isDisposed(data)) {
                        stationsMap[station]!.disposedCases++;
                      } else {
                        stationsMap[station]!.activeCases++;
                      }
                    }
                  }

                  final allStations = stationsMap.values.toList()
                    ..sort((a, b) => a.name.compareTo(b.name));

                  // Apply search and filters
                  final filteredStations = allStations.where((st) {
                    if (_selectedState != 'All States' && st.state.toLowerCase() != _selectedState.toLowerCase()) {
                      return false;
                    }
                    if (_selectedDistrict != null && !st.district.toLowerCase().contains(_selectedDistrict!.toLowerCase())) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty && !st.name.toLowerCase().contains(_searchQuery)) {
                      return false;
                    }
                    return true;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Page Header with Total Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Police Stations',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Manage and view all registered police stations & jurisdictional personnel',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_city_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 6),
                                Text(
                                  '${allStations.length} Stations Registered',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 2. Filters & Search Control Bar
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 750;

                              final searchField = TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search station by name...',
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  isDense: true,
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              );

                              final stateDropdown = DropdownButtonFormField<String>(
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
                                items: _states
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  final newState = val ?? 'All States';
                                  setState(() {
                                    _selectedState = newState;
                                    final validDistricts = AppConstants.getDistrictsForState(newState);
                                    if (_selectedDistrict != null && !validDistricts.contains(_selectedDistrict)) {
                                      _selectedDistrict = null;
                                    }
                                  });
                                },
                              );

                              final districtDropdown = DropdownButtonFormField<String?>(
                                key: ValueKey('district_$_selectedState'),
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
                                  ...stateDistricts.map((d) => DropdownMenuItem<String?>(
                                        value: d,
                                        child: Text(d, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                      )),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDistrict = val;
                                  });
                                },
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

                      const SizedBox(height: 22),

                      // 3. Station Cards Grid
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(
                            child: SizedBox(
                              height: 32,
                              width: 32,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        )
                      else if (filteredStations.isEmpty)
                        Container(
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
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No police stations found',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hasActiveFilters
                                    ? 'Try changing your search keywords or resetting the filters.'
                                    : 'No stations have been registered in the database yet.',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Reset Filters'),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final screenW = constraints.maxWidth;
                            int crossAxisCount = 1;
                            if (screenW >= 1200) {
                              crossAxisCount = 3;
                            } else if (screenW >= 760) {
                              crossAxisCount = 2;
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: 185,
                              ),
                              itemCount: filteredStations.length,
                              itemBuilder: (context, index) {
                                final st = filteredStations[index];
                                return _StationCard(
                                  station: st,
                                  onTap: () {
                                    setState(() {
                                      _selectedStationForDetail = st.name;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StationAggregate {
  final String name;
  final String district;
  final String state;
  final String status;
  int officerCount = 0;
  int totalCases = 0;
  int activeCases = 0;
  int disposedCases = 0;
  final List<Map<String, dynamic>> officers = [];

  _StationAggregate({
    required this.name,
    required this.district,
    required this.state,
    this.status = 'Active',
  });
}

// 🏢 Individual Station Card Widget
class _StationCard extends StatefulWidget {
  final _StationAggregate station;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.onTap,
  });

  @override
  State<_StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<_StationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final st = widget.station;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFF1D4ED8).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 14 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Accent Strip
                Container(
                  height: 3.5,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Icon + Name + Active Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8).withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  st.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${st.district}, ${st.state}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 12),

                      // Metrics Row: Officer count & Cases
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${st.officerCount} Officers',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.folder_open_rounded, size: 14, color: Color(0xFF475569)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${st.totalCases} Cases',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Inspect',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isHovered ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: _isHovered ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ],
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

// 🔍 Dedicated Station Detail View
class _StationDetailView extends StatefulWidget {
  final String stationName;
  final VoidCallback onBack;

  const _StationDetailView({
    required this.stationName,
    required this.onBack,
  });

  @override
  State<_StationDetailView> createState() => _StationDetailViewState();
}

class _StationDetailViewState extends State<_StationDetailView> {
  String? _caseStatusFilter; // null = all, 'Pending', 'Disposed'
  final GlobalKey _rosterSectionKey = GlobalKey();
  final GlobalKey _casesSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Back Button & Station Title Header
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Police Stations', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stationName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Jurisdictional station overview, active personnel roster and case records',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Streams for Station Officers & Cases (100% Live Firestore)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('cases').snapshots(),
                builder: (context, caseSnapshot) {
                  final userDocs = userSnapshot.data?.docs ?? [];
                  final caseDocs = caseSnapshot.data?.docs ?? [];

                  final stationOfficers = userDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (AppConstants.isAdminUser(data)) return false;
                    final st = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
                    return st?.toLowerCase() == widget.stationName.toLowerCase();
                  }).toList();

                  final stationCases = caseDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final st = (data['station'] ?? data['stationName'])?.toString().trim();
                    return st?.toLowerCase() == widget.stationName.toLowerCase();
                  }).toList();

                  int pendingCasesCount = 0;
                  int disposedCasesCount = 0;
                  for (final doc in stationCases) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (CaseUtils.isDisposed(data)) {
                      disposedCasesCount++;
                    } else {
                      pendingCasesCount++;
                    }
                  }

                  // Filter cases for the table view
                  final displayedCases = stationCases.where((doc) {
                    if (_caseStatusFilter == null) return true;
                    final data = doc.data() as Map<String, dynamic>;
                    final isDisposed = CaseUtils.isDisposed(data);

                    if (_caseStatusFilter == 'Pending') {
                      return !isDisposed;
                    } else if (_caseStatusFilter == 'Disposed') {
                      return isDisposed;
                    }
                    return true;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Stat Cards Row (Unified Blue Style & Clickable)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 750;
                          final officersCard = _DetailStatCard(
                            label: 'Total Officers',
                            value: '${stationOfficers.length}',
                            icon: Icons.badge_outlined,
                            isSelected: false,
                            onTap: () {
                              setState(() => _caseStatusFilter = null);
                              _scrollToKey(_rosterSectionKey);
                            },
                          );
                          final pendingCard = _DetailStatCard(
                            label: 'Pending Cases',
                            value: '$pendingCasesCount',
                            icon: Icons.folder_outlined,
                            isSelected: _caseStatusFilter == 'Pending',
                            onTap: () {
                              setState(() {
                                _caseStatusFilter = _caseStatusFilter == 'Pending' ? null : 'Pending';
                              });
                              _scrollToKey(_casesSectionKey);
                            },
                          );
                          final disposedCard = _DetailStatCard(
                            label: 'Disposed Cases',
                            value: '$disposedCasesCount',
                            icon: Icons.task_alt_rounded,
                            isSelected: _caseStatusFilter == 'Disposed',
                            onTap: () {
                              setState(() {
                                _caseStatusFilter = _caseStatusFilter == 'Disposed' ? null : 'Disposed';
                              });
                              _scrollToKey(_casesSectionKey);
                            },
                          );

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: officersCard),
                                const SizedBox(width: 16),
                                Expanded(child: pendingCard),
                                const SizedBox(width: 16),
                                Expanded(child: disposedCard),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                officersCard,
                                const SizedBox(height: 12),
                                pendingCard,
                                const SizedBox(height: 12),
                                disposedCard,
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // 2. Station Personnel Roster Table
                      Card(
                        key: _rosterSectionKey,
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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.badge_outlined, color: Color(0xFF1D4ED8), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Station Personnel Roster',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Assigned officers, ranks, and live 7-day activity status',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (stationOfficers.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text(
                                      'No officers currently assigned to this station.',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                )
                              else
                                Scrollbar(
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 700),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                        dataRowMinHeight: 52,
                                        dataRowMaxHeight: 60,
                                        columns: const [
                                          DataColumn(label: Text('Officer Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                          DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                          DataColumn(label: Text('Seva Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                          DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                        ],
                                        rows: stationOfficers.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final doc = entry.value;
                                          final data = doc.data() as Map<String, dynamic>;
                                          final name = (data['name'] ?? data['displayName'] ?? data['fullName'] ?? 'Officer').toString();
                                          final desig = (data['designation'] ?? 'PSI').toString().toUpperCase();
                                          final seva = (data['sevaNumber'] ?? data['badgeNumber'])?.toString().trim();
                                          final phone = (data['phoneNumber'] ?? data['contact'])?.toString().trim();

                                          // 🟢 Real 7-day activity check from Firestore
                                          final lastLoginDt = _parseDateTime(data['lastLoginAt'] ?? data['lastActiveAt'] ?? data['lastActive'] ?? data['lastLogin'] ?? data['updatedAt'] ?? data['createdAt']);
                                          final isOfficerActive = lastLoginDt != null && DateTime.now().difference(lastLoginDt).inDays <= 7;
                                          final statusLabel = isOfficerActive ? 'ACTIVE' : 'INACTIVE';
                                          final statusColor = isOfficerActive ? const Color(0xFF059669) : const Color(0xFF64748B);
                                          final statusBg = isOfficerActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);
                                          final statusBorder = isOfficerActive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0);

                                          // Rank color badge
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
                                                  seva != null && seva.isNotEmpty && seva != 'null' ? seva : '—',
                                                  style: TextStyle(
                                                    color: seva != null && seva.isNotEmpty && seva != 'null' ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  phone != null && phone.isNotEmpty && phone != 'null' ? phone : '—',
                                                  style: TextStyle(
                                                    color: phone != null && phone.isNotEmpty && phone != 'null' ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: statusBg,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: statusBorder),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      CircleAvatar(radius: 3, backgroundColor: statusColor),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        statusLabel,
                                                        style: TextStyle(
                                                          color: statusColor,
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

                      const SizedBox(height: 24),

                      // 3. Station Cases Table (With Live Filter Chip)
                      Card(
                        key: _casesSectionKey,
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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.folder_outlined, color: Color(0xFF1D4ED8), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'Station Cases & Registrations',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (_caseStatusFilter != null) ...[
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: const Color(0xFF93C5FD)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Filtered: $_caseStatusFilter Cases (${displayedCases.length})',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFF1D4ED8),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    InkWell(
                                                      onTap: () => setState(() => _caseStatusFilter = null),
                                                      child: const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFF1D4ED8)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const Text(
                                          'Case registry, crime numbers, IO assignments and disposal states',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (displayedCases.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          _caseStatusFilter != null
                                              ? 'No $_caseStatusFilter cases found for this station.'
                                              : 'No case records registered for this station.',
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        if (_caseStatusFilter != null) ...[
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () => setState(() => _caseStatusFilter = null),
                                            child: const Text('Show All Cases', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
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
                                      constraints: const BoxConstraints(minWidth: 700),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                        dataRowMinHeight: 52,
                                        dataRowMaxHeight: 60,
                                        columns: const [
                                          DataColumn(label: Text('Crime / Case No.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                          DataColumn(label: Text('Case Title / Sections', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                          DataColumn(label: Text('Investigating Officer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF334155)))),
                                        ],
                                        rows: displayedCases.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final doc = entry.value;
                                          final data = doc.data() as Map<String, dynamic>;
                                          final caseNo = (data['caseNumber'] ?? data['crimeNumber'] ?? data['firNumber'] ?? doc.id).toString();
                                          final title = (data['title'] ?? data['sections'] ?? data['caseTitle'] ?? 'General Case Record').toString();
                                          final io = (data['ioName'] ?? data['assignedOfficer'] ?? data['officerName'] ?? '—').toString();
                                          final isDisposed = CaseUtils.isDisposed(data);

                                          // 🏷️ Status Badge
                                          final displayBadgeText = CaseUtils.getStatusLabel(data);
                                          final badgeColor = isDisposed ? const Color(0xFF059669) : const Color(0xFFD97706);
                                          final badgeBg = isDisposed ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7);
                                          final badgeBorder = isDisposed ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A);

                                          return DataRow(
                                            color: WidgetStateProperty.resolveWith<Color?>((states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return const Color(0xFFF1F5F9);
                                              }
                                              return index % 2 == 1 ? const Color(0xFFFAFAFA) : Colors.white;
                                            }),
                                            cells: [
                                              DataCell(
                                                Text(
                                                  caseNo,
                                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8), fontSize: 13),
                                                ),
                                              ),
                                              DataCell(
                                                ConstrainedBox(
                                                  constraints: const BoxConstraints(maxWidth: 320),
                                                  child: Text(
                                                    title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  io,
                                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: badgeBg,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: badgeBorder),
                                                  ),
                                                  child: Text(
                                                    displayBadgeText,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: badgeColor,
                                                    ),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

// 🗂️ Interactive Clickable Polished Stat Card (Unified Blue Palette)
class _DetailStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<_DetailStatCard> createState() => _DetailStatCardState();
}

class _DetailStatCardState extends State<_DetailStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF1D4ED8); // Unified Blue Accent across all 3 cards

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? accentColor
                  : (_isHovered ? accentColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
              width: widget.isSelected ? 2 : (_isHovered ? 1.5 : 1),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? accentColor.withValues(alpha: 0.12)
                    : (_isHovered
                        ? accentColor.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.02)),
                blurRadius: widget.isSelected ? 14 : (_isHovered ? 12 : 6),
                offset: Offset(0, _isHovered || widget.isSelected ? 4 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Blue Accent Strip
              Container(
                height: 3.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
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
    );
  }
}


