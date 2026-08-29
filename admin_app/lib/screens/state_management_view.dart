import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../utils/toast_service.dart';

class StateManagementView extends StatefulWidget {
  const StateManagementView({super.key});

  @override
  State<StateManagementView> createState() => _StateManagementViewState();
}

ImageProvider? _getLogoImageProvider(String? logoSrc) {
  if (logoSrc == null || logoSrc.trim().isEmpty) return null;
  final clean = logoSrc.trim();
  if (clean.startsWith('data:image')) {
    try {
      final base64Str = clean.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  } else if (clean.startsWith('http')) {
    return NetworkImage(clean);
  }
  return null;
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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openStateDetailsDialog(state),
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
                                          backgroundImage: _getLogoImageProvider(state['department_logo_url']?.toString()),
                                          child: _getLogoImageProvider(state['department_logo_url']?.toString()) == null
                                              ? Text(
                                                  code,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onPrimaryContainer,
                                                  ),
                                                )
                                              : null,
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
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Manage State Admins',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                        ),
                                        Icon(Icons.arrow_forward, size: 16, color: Colors.blueAccent),
                                      ],
                                    ),
                                  ],
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

  void _openStateDetailsDialog(Map<String, dynamic> state) {
    showDialog(
      context: context,
      builder: (ctx) => _StateDetailsDialog(state: state, onUpdated: _loadStates),
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
  final TextEditingController _logoUrlCtrl = TextEditingController();
  final TextEditingController _superAdminNameCtrl = TextEditingController();
  final TextEditingController _superAdminEmailCtrl = TextEditingController();
  final TextEditingController _superAdminPhoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController(text: 'StateAdmin@123');
  final TextEditingController _ageCtrl = TextEditingController(text: '45');
  final TextEditingController _photoUrlCtrl = TextEditingController();
  final TextEditingController _idCardUrlCtrl = TextEditingController();

  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _logoDataUrl;

  Uint8List? _photoBytes;
  String? _photoFileName;
  String? _photoDataUrl;

  Uint8List? _idCardBytes;
  String? _idCardFileName;
  String? _idCardDataUrl;

  String _selectedRank = 'Director General of Police (DG)';
  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _pickFile({
    required Function(Uint8List bytes, String fileName, String dataUrl) onPicked,
  }) async {
    if (kIsWeb) {
      try {
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/png, image/jpeg, image/jpg, image/webp';
        uploadInput.click();

        uploadInput.onChange.listen((e) {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();

            reader.onLoadEnd.listen((e) {
              final result = reader.result;
              if (result is String) {
                final base64Str = result.contains(',') ? result.split(',').last : result;
                try {
                  final bytes = base64Decode(base64Str);
                  onPicked(bytes, file.name, result);
                } catch (_) {}
              }
            });

            reader.readAsDataUrl(file);
          }
        });
        return;
      } catch (_) {
        // Fall back to FilePicker if HTML input fails
      }
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        final Uint8List? bytes = file.bytes;
        if (bytes != null) {
          final String ext = file.extension?.toLowerCase() ?? 'png';
          final String mime = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png';
          final base64Str = base64Encode(bytes);
          final dataUrl = 'data:$mime;base64,$base64Str';
          onPicked(bytes, file.name, dataUrl);
        }
      }
    } catch (e) {
      if (mounted) {
        AdminToast.showError(context, 'Failed to select file: $e');
      }
    }
  }

  List<String> _policeRanks = [
    'Director General of Police (DG)',
    'Additional Director General of Police (ADG)',
    'Inspector General of Police (IG)',
    'Deputy Inspector General of Police (DIG)',
    'Commissioner of Police (CP)',
  ];

  @override
  void initState() {
    super.initState();
    _loadDynamicDesignations();
  }

  Future<void> _loadDynamicDesignations() async {
    try {
      final list = await ApiService.fetchDesignations(role: 'state_admin');
      if (list.isNotEmpty && mounted) {
        setState(() {
          _policeRanks = list.map((item) {
            final title = item['title'] ?? item['code'];
            final code = item['code'] ?? '';
            return code.isNotEmpty && !title.toString().contains(code)
                ? '$title ($code)'
                : title.toString();
          }).toList();
          if (_policeRanks.isNotEmpty) {
            _selectedRank = _policeRanks.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _forceTitleCtrl.dispose();
    _logoUrlCtrl.dispose();
    _superAdminNameCtrl.dispose();
    _superAdminEmailCtrl.dispose();
    _superAdminPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    _ageCtrl.dispose();
    _photoUrlCtrl.dispose();
    _idCardUrlCtrl.dispose();
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
      final logoSrc = _logoDataUrl ?? '';
      final photoSrc = _photoDataUrl ?? '';
      final idCardSrc = _idCardDataUrl ?? '';

      await ApiService.createStateOnboarding(
        stateCode: _selectedState!['code'],
        stateName: _selectedState!['name'],
        policeForceTitle: _forceTitleCtrl.text.trim(),
        departmentLogoUrl: logoSrc,
        superAdminName: _superAdminNameCtrl.text.trim(),
        superAdminEmail: _superAdminEmailCtrl.text.trim(),
        superAdminPhone: _superAdminPhoneCtrl.text.trim(),
        superAdminRank: _selectedRank,
        password: _passwordCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()),
        gender: _selectedGender,
        photoUrl: photoSrc,
        idCardUrl: idCardSrc,
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
  Widget _buildFileUploadTile({
    required String label,
    required String hintText,
    required IconData icon,
    required Uint8List? bytes,
    required String? fileName,
    required VoidCallback onTapUpload,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);

    if (bytes != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade400),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                  Text(
                    fileName ?? 'image.png',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue, size: 18),
              tooltip: 'Change Image',
              onPressed: onTapUpload,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
              tooltip: 'Remove',
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTapUpload,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                  Text(hintText, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onTapUpload,
              icon: const Icon(Icons.upload_file, size: 14),
              label: const Text('Browse File', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
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
                const SizedBox(height: 10),
                _buildFileUploadTile(
                  label: 'State Police Department Logo (PNG/JPEG)',
                  hintText: 'Select official state emblem logo file',
                  icon: Icons.shield,
                  bytes: _logoBytes,
                  fileName: _logoFileName,
                  onTapUpload: () => _pickFile(onPicked: (b, fn, du) {
                    setState(() {
                      _logoBytes = b;
                      _logoFileName = fn;
                      _logoDataUrl = du;
                    });
                  }),
                  onClear: () => setState(() {
                    _logoBytes = null;
                    _logoFileName = null;
                    _logoDataUrl = null;
                  }),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Officer Age',
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v ?? 'Male'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFileUploadTile(
                        label: 'Officer Profile Photo (Optional)',
                        hintText: 'Upload PNG/JPEG photo',
                        icon: Icons.account_box,
                        bytes: _photoBytes,
                        fileName: _photoFileName,
                        onTapUpload: () => _pickFile(onPicked: (b, fn, du) {
                          setState(() {
                            _photoBytes = b;
                            _photoFileName = fn;
                            _photoDataUrl = du;
                          });
                        }),
                        onClear: () => setState(() {
                          _photoBytes = null;
                          _photoFileName = null;
                          _photoDataUrl = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFileUploadTile(
                        label: 'Police ID Card Photo (Optional)',
                        hintText: 'Upload ID Card PNG/JPEG',
                        icon: Icons.badge_outlined,
                        bytes: _idCardBytes,
                        fileName: _idCardFileName,
                        onTapUpload: () => _pickFile(onPicked: (b, fn, du) {
                          setState(() {
                            _idCardBytes = b;
                            _idCardFileName = fn;
                            _idCardDataUrl = du;
                          });
                        }),
                        onClear: () => setState(() {
                          _idCardBytes = null;
                          _idCardFileName = null;
                          _idCardDataUrl = null;
                        }),
                      ),
                    ),
                  ],
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

class _StateDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> state;
  final VoidCallback onUpdated;

  const _StateDetailsDialog({
    required this.state,
    required this.onUpdated,
  });

  @override
  State<_StateDetailsDialog> createState() => _StateDetailsDialogState();
}

class _StateDetailsDialogState extends State<_StateDetailsDialog> {
  List<dynamic> _admins = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.fetchStateAdmins(widget.state['state_code']);
      if (mounted) {
        setState(() {
          _admins = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AdminToast.showError(context, 'Failed to load state admins: $e');
      }
    }
  }

  Future<void> _toggleAdminStatus(Map<String, dynamic> admin) async {
    final uid = admin['uid'];
    final name = admin['name'] ?? 'Officer';
    final isDeactivating = (admin['account_status'] ?? 'active') == 'active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDeactivating ? Icons.block : Icons.check_circle,
              color: isDeactivating ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Text(isDeactivating ? 'Deactivate State Admin?' : 'Reactivate State Admin?'),
          ],
        ),
        content: Text(
          isDeactivating
              ? 'Are you sure you want to DEACTIVATE $name?\n\nDeactivated officers will immediately lose access and be BLOCKED from logging into the PMS App.'
              : 'Are you sure you want to REACTIVATE $name?\n\nReactivated officers will regain full administrative access to the PMS App.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDeactivating ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isDeactivating ? 'Deactivate Account' : 'Reactivate Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await ApiService.toggleStateAdminStatus(
        stateCode: widget.state['state_code'],
        uid: uid,
      );
      if (mounted) {
        AdminToast.showSuccess(
          context,
          res['message'] ?? 'Admin status updated successfully',
          title: 'STATUS UPDATED',
        );
        _loadAdmins();
      }
    } catch (e) {
      if (mounted) {
        AdminToast.showError(context, 'Failed to update admin status: $e');
      }
    }
  }

  void _openAddAdminDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddStateAdminDialog(
        state: widget.state,
        onAdded: _loadAdmins,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = widget.state['state_code'] ?? 'ST';
    final name = widget.state['state_name'] ?? 'State';
    final force = widget.state['police_force_title'] ?? '$name Police';

    final filteredAdmins = _admins.where((admin) {
      final q = _searchQuery.toLowerCase();
      final n = (admin['name'] ?? '').toString().toLowerCase();
      final e = (admin['email'] ?? '').toString().toLowerCase();
      final p = (admin['phone'] ?? '').toString().toLowerCase();
      final d = (admin['designation'] ?? '').toString().toLowerCase();
      return n.contains(q) || e.contains(q) || p.contains(q) || d.contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1000,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: _getLogoImageProvider(widget.state['department_logo_url']?.toString()),
                  child: _getLogoImageProvider(widget.state['department_logo_url']?.toString()) == null
                      ? Text(code, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer, fontSize: 16))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(code, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      Text('$force • State Officers Directory', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAdmins,
                  tooltip: 'Refresh Admin List',
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _openAddAdminDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add State Admin'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 32),

            // Search Bar & Admin Stats
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search state admins by name, email, rank, phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Total Admins: ${_admins.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredAdmins.isEmpty
                      ? const Center(child: Text('No state admins found for this jurisdiction.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 900),
                              child: DataTable(
                                columnSpacing: 18,
                                horizontalMargin: 16,
                                headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest),
                                columns: const [
                                  DataColumn(label: Text('OFFICER NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('RANK / DESIGNATION', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('CONTACT', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('AGE / GENDER', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filteredAdmins.map((admin) {
                                  final isActive = (admin['account_status'] ?? 'active') == 'active';
                                  final photoSrc = admin['photo_url']?.toString();
                                  final name = admin['name'] ?? 'Officer';
                                  final badge = admin['badge_number'] ?? 'N/A';
                                  final desig = admin['designation'] ?? 'State Admin';
                                  final email = admin['email'] ?? '';
                                  final phone = admin['phone'] ?? '';
                                  final age = admin['age'] != null ? '${admin['age']} yrs' : 'N/A';
                                  final gender = admin['gender'] ?? 'Male';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 180,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundImage: _getLogoImageProvider(photoSrc),
                                                child: _getLogoImageProvider(photoSrc) == null
                                                    ? const Icon(Icons.person, size: 18)
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                                    Text('Badge: $badge', style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 170,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              desig,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 180,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(email, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                              Text(phone, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 90,
                                          child: Text('$age / $gender', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            isActive ? 'ACTIVE' : 'DEACTIVATED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isActive ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isActive ? Colors.red : Colors.green,
                                            side: BorderSide(color: isActive ? Colors.red : Colors.green),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          onPressed: () => _toggleAdminStatus(admin),
                                          icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 13),
                                          label: Text(isActive ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStateAdminDialog extends StatefulWidget {
  final Map<String, dynamic> state;
  final VoidCallback onAdded;

  const _AddStateAdminDialog({
    required this.state,
    required this.onAdded,
  });

  @override
  State<_AddStateAdminDialog> createState() => _AddStateAdminDialogState();
}

class _AddStateAdminDialogState extends State<_AddStateAdminDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController(text: 'StateAdmin@123');
  final TextEditingController _ageCtrl = TextEditingController(text: '45');

  String _selectedRank = 'Director General of Police (DG)';
  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Uint8List? _photoBytes;
  String? _photoFileName;
  String? _photoDataUrl;

  Uint8List? _idCardBytes;
  String? _idCardFileName;
  String? _idCardDataUrl;

  List<String> _policeRanks = [
    'Director General of Police (DG)',
    'Additional Director General of Police (ADG)',
    'Inspector General of Police (IG)',
    'Deputy Inspector General of Police (DIG)',
    'Commissioner of Police (CP)',
  ];

  @override
  void initState() {
    super.initState();
    _loadDynamicDesignations();
  }

  Future<void> _loadDynamicDesignations() async {
    try {
      final list = await ApiService.fetchDesignations(role: 'state_admin');
      if (list.isNotEmpty && mounted) {
        setState(() {
          _policeRanks = list.map((item) {
            final title = item['title'] ?? item['code'];
            final code = item['code'] ?? '';
            return code.isNotEmpty && !title.toString().contains(code)
                ? '$title ($code)'
                : title.toString();
          }).toList();
          if (_policeRanks.isNotEmpty) {
            _selectedRank = _policeRanks.first;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickFile({
    required Function(Uint8List bytes, String fileName, String dataUrl) onPicked,
  }) async {
    if (kIsWeb) {
      try {
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/png, image/jpeg, image/jpg, image/webp';
        uploadInput.click();

        uploadInput.onChange.listen((e) {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();

            reader.onLoadEnd.listen((e) {
              final result = reader.result;
              if (result is String) {
                try {
                  final base64Str = result.contains(',') ? result.split(',').last : result;
                  final bytes = base64Decode(base64Str);
                  onPicked(bytes, file.name, result);
                } catch (_) {}
              }
            });

            reader.readAsDataUrl(file);
          }
        });
        return;
      } catch (_) {}
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        final Uint8List? bytes = file.bytes;
        if (bytes != null) {
          final String ext = file.extension?.toLowerCase() ?? 'png';
          final String mime = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png';
          final base64Str = base64Encode(bytes);
          final dataUrl = 'data:$mime;base64,$base64Str';
          onPicked(bytes, file.name, dataUrl);
        }
      }
    } catch (e) {
      if (mounted) {
        AdminToast.showError(context, 'Failed to select file: $e');
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.addStateAdmin(
        stateCode: widget.state['state_code'],
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        designation: _selectedRank,
        password: _passwordCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()),
        gender: _selectedGender,
        photoUrl: _photoDataUrl ?? '',
        idCardUrl: _idCardDataUrl ?? '',
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAdded();

      AdminToast.showSuccess(
        context,
        'State Admin ${_nameCtrl.text.trim()} added to ${widget.state['state_name']} Police!',
        title: 'ADMIN OFFICER ADDED',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AdminToast.showError(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
        title: 'FAILED TO ADD ADMIN',
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
            child: Icon(Icons.person_add, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New State Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Provision additional admin officer for ${widget.state['state_name']} Police', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Officer Full Name',
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
                                  child: Text(r, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
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
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Official Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Email required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Account Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Officer Age',
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v ?? 'Male'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFileUploadTile(
                        label: 'Profile Photo (Optional)',
                        hintText: 'Upload PNG/JPEG photo',
                        icon: Icons.account_box,
                        bytes: _photoBytes,
                        fileName: _photoFileName,
                        onTapUpload: () => _pickFile(onPicked: (b, fn, du) {
                          setState(() {
                            _photoBytes = b;
                            _photoFileName = fn;
                            _photoDataUrl = du;
                          });
                        }),
                        onClear: () => setState(() {
                          _photoBytes = null;
                          _photoFileName = null;
                          _photoDataUrl = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFileUploadTile(
                        label: 'Police ID Card Photo (Optional)',
                        hintText: 'Upload ID Card PNG/JPEG',
                        icon: Icons.badge_outlined,
                        bytes: _idCardBytes,
                        fileName: _idCardFileName,
                        onTapUpload: () => _pickFile(onPicked: (b, fn, du) {
                          setState(() {
                            _idCardBytes = b;
                            _idCardFileName = fn;
                            _idCardDataUrl = du;
                          });
                        }),
                        onClear: () => setState(() {
                          _idCardBytes = null;
                          _idCardFileName = null;
                          _idCardDataUrl = null;
                        }),
                      ),
                    ),
                  ],
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
          label: Text(_isLoading ? 'Adding Admin...' : 'Add Admin'),
        ),
      ],
    );
  }

  Widget _buildFileUploadTile({
    required String label,
    required String hintText,
    required IconData icon,
    required Uint8List? bytes,
    required String? fileName,
    required VoidCallback onTapUpload,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final hasFile = bytes != null && bytes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasFile)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    bytes,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName ?? 'image.png',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onTapUpload,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit, size: 14, color: Colors.blueAccent),
                  ),
                ),
                InkWell(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: Colors.redAccent),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: onTapUpload,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Browse File',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
