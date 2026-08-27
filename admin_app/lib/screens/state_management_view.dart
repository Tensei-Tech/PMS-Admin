import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/toast_service.dart';

class StateManagementView extends StatefulWidget {
  const StateManagementView({super.key});

  @override
  State<StateManagementView> createState() => _StateManagementViewState();
}

class _StateManagementViewState extends State<StateManagementView> {
  List<dynamic> _statesList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() => _isLoading = true);
    final states = await ApiService.fetchStates();
    if (mounted) {
      setState(() {
        _statesList = states;
        _isLoading = false;
      });
    }
  }

  void _showOnboardStateDialog() async {
    final availableStates = await ApiService.fetchAvailableStates();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OnboardStateDialog(
        availableStates: availableStates,
        onStateAdded: _loadStates,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredStates = _statesList.where((s) {
      final name = (s['state_name'] ?? '').toString().toLowerCase();
      final code = (s['state_code'] ?? '').toString().toLowerCase();
      final force = (s['police_force_title'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || code.contains(query) || force.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar & Action Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State Jurisdictions & Police Forces',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Onboard state police forces, configure state super admins, and manage active state registries.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showOnboardStateDialog,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text(
                  'Onboard New State',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search & Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search state, code, or police force title...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                onPressed: _loadStates,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh States List',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // State Cards Grid / Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No Provisioned States Found',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('Click "Onboard New State" to register your first state police force.'),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _showOnboardStateDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Onboard New State'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisExtent: 220,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredStates.length,
                        itemBuilder: (context, index) {
                          final state = filteredStates[index];
                          final code = state['state_code'] ?? 'ST';
                          final name = state['state_name'] ?? 'State';
                          final force = state['police_force_title'] ?? '$name Police';
                          final superAdmin = state['super_admin_name'] ?? 'DGP / Super Admin';
                          final rank = state['super_admin_rank'] ?? 'DGP';
                          final email = state['super_admin_email'] ?? '';
                          final phone = state['super_admin_phone'] ?? '';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        child: Text(
                                          code,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              force,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.shield_outlined, size: 18, color: Colors.blueAccent),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$superAdmin ($rank)',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          email.isNotEmpty ? email : 'superadmin@pms.gov.in',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        phone.isNotEmpty ? phone : '+91 98765 00000',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
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

class _OnboardStateDialog extends StatefulWidget {
  final List<dynamic> availableStates;
  final VoidCallback onStateAdded;

  const _OnboardStateDialog({
    required this.availableStates,
    required this.onStateAdded,
  });

  @override
  State<_OnboardStateDialog> createState() => _OnboardStateDialogState();
}

class _OnboardStateDialogState extends State<_OnboardStateDialog> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _selectedState;

  final TextEditingController _forceTitleCtrl = TextEditingController();
  final TextEditingController _superAdminNameCtrl = TextEditingController();
  final TextEditingController _superAdminEmailCtrl = TextEditingController();
  final TextEditingController _superAdminPhoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController(text: 'StateAdmin@123');

  String _selectedRank = 'Director General of Police (DGP)';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _policeRanks = [
    'Director General of Police (DGP)',
    'Additional Director General of Police (ADGP)',
    'Inspector General of Police (IGP)',
    'Deputy Inspector General of Police (DIG)',
    'Commissioner of Police (CP)',
  ];

  @override
  void dispose() {
    _forceTitleCtrl.dispose();
    _superAdminNameCtrl.dispose();
    _superAdminEmailCtrl.dispose();
    _superAdminPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onStateSelected(Map<String, dynamic>? item) {
    if (item == null || item['is_already_added'] == true) return;

    setState(() {
      _selectedState = item;
      _forceTitleCtrl.text = item['default_force'] ?? '${item['name']} State Police';
      _superAdminNameCtrl.text = 'DGP ${item['name']}';
      _superAdminEmailCtrl.text = 'dgp.${item['code'].toString().toLowerCase()}@pms.gov.in';
      _superAdminPhoneCtrl.text = '98765${item['code'].toString().codeUnits.join().substring(0, 5)}';
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedState == null) {
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an available state')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.createStateOnboarding(
        stateCode: _selectedState!['code'],
        stateName: _selectedState!['name'],
        policeForceTitle: _forceTitleCtrl.text.trim(),
        superAdminName: _superAdminNameCtrl.text.trim(),
        superAdminEmail: _superAdminEmailCtrl.text.trim(),
        superAdminPhone: _superAdminPhoneCtrl.text.trim(),
        superAdminRank: _selectedRank,
        password: _passwordCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onStateAdded();

      AdminToast.showSuccess(
        context,
        'State ${_selectedState!['name']} (${_selectedState!['code']}) onboarded successfully!',
        title: 'STATE ONBOARDED',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AdminToast.showError(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
        title: 'ONBOARDING FAILED',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_location_alt, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Onboard New State Jurisdiction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Provision state database registry & Super Admin', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text('Select State or Union Territory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedState,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.map),
                    hintText: 'Select Indian State / UT',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: widget.availableStates.map((st) {
                    final isAdded = st['is_already_added'] == true;
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: isAdded ? null : st,
                      enabled: !isAdded,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${st['name']} (${st['code']})',
                            style: TextStyle(
                              color: isAdded ? Colors.grey : null,
                              fontWeight: isAdded ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          if (isAdded)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Already Added',
                                style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _onStateSelected,
                  validator: (v) => _selectedState == null ? 'State selection required' : null,
                ),
                const SizedBox(height: 20),

                const Text('Police Force Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _forceTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Police Force Official Title',
                    prefixIcon: const Icon(Icons.security),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Title required' : null,
                ),
                const SizedBox(height: 20),

                const Text('State Super Admin Account Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _superAdminNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Super Admin Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRank,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Police Rank',
                          prefixIcon: const Icon(Icons.military_tech),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _policeRanks
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRank = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _superAdminEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Super Admin Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email required';
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _superAdminPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone required';
                          final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                          if (clean.length < 10) return 'Enter 10-digit phone number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Super Admin Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleSubmit,
          icon: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle),
          label: Text(_isLoading ? 'Onboarding...' : 'Onboard State'),
        ),
      ],
    );
  }
}
