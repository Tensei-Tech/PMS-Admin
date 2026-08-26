import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/station_dashboard_view.dart';
import '../utils/app_constants.dart';

class StationsListDialog extends StatefulWidget {
  const StationsListDialog({super.key});

  @override
  State<StationsListDialog> createState() => _StationsListDialogState();
}

class _StationsListDialogState extends State<StationsListDialog> {
  Key _streamKey = UniqueKey();
  String _selectedState = 'All States';
  String? _selectedDistrict;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _states = const [
    'All States',
    'Maharashtra',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDistricts = AppConstants.getDistrictsForUnitType(null);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_city_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              const Text('Police Stations Directory'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        height: 520,
        child: Column(
          children: [
            // Filter Controls (State & District)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'State',
                      prefixIcon: const Icon(Icons.map_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: _states
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedState = val ?? 'All States';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedDistrict,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'District',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Districts', overflow: TextOverflow.ellipsis),
                      ),
                      ...allDistricts.map((d) => DropdownMenuItem<String?>(
                            value: d,
                            child: Text(d, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedDistrict = val;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search Input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search station by name...',
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
            const SizedBox(height: 12),
            // Station List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                key: _streamKey,
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('accountStatus', isEqualTo: 'active')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 10),
                            Text('Failed to load stations: $error', textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final Map<String, ({int count, String district, String state})> stationData = {};

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final stationName = (data['stationName'] ?? data['station'] ?? data['assignedStation'])?.toString().trim();
                    final district = (data['district'] ?? data['city'] ?? 'Maharashtra Police').toString().trim();
                    final state = (data['state'] ?? 'Maharashtra').toString().trim();

                    if (stationName != null && stationName.isNotEmpty) {
                      final current = stationData[stationName];
                      stationData[stationName] = (
                        count: (current?.count ?? 0) + 1,
                        district: district.isNotEmpty ? district : (current?.district ?? 'Unknown District'),
                        state: state.isNotEmpty ? state : (current?.state ?? 'Maharashtra'),
                      );
                    }
                  }

                  // Apply State, District, and Search Filters
                  final filteredStations = stationData.keys.where((st) {
                    final info = stationData[st]!;
                    if (_selectedState != 'All States' && info.state != _selectedState) {
                      return false;
                    }
                    if (_selectedDistrict != null &&
                        !info.district.toLowerCase().contains(_selectedDistrict!.toLowerCase())) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty && !st.toLowerCase().contains(_searchQuery)) {
                      return false;
                    }
                    return true;
                  }).toList()..sort();

                  if (filteredStations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 10),
                          Text(
                            'No matching police stations found',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredStations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final station = filteredStations[index];
                      final info = stationData[station]!;

                      return ListTile(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StationDashboardView(stationName: station),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.local_police_outlined,
                            size: 20,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          station,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${info.district} • ${info.state}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                '${info.count} Officer${info.count == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

