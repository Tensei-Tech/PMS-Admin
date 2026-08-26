import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  final _firestore = FirebaseFirestore.instance;

  static const List<String> _suggestedTags = [
    'New Law',
    'Circular',
    'Amendment',
    'Notice',
    'Alert',
    'Awareness',
    'SOP',
    'Important',
  ];

  static const List<({String name, IconData icon, String label})> _availableIcons = [
    (name: 'gavel', icon: Icons.gavel_rounded, label: 'Legal / Gavel'),
    (name: 'shield', icon: Icons.shield_rounded, label: 'Shield / Safety'),
    (name: 'videocam', icon: Icons.videocam_rounded, label: 'Body Camera'),
    (name: 'security', icon: Icons.security_rounded, label: 'Security / Cyber'),
    (name: 'campaign', icon: Icons.campaign_rounded, label: 'Announcement'),
    (name: 'warning', icon: Icons.warning_amber_rounded, label: 'Alert / Warning'),
    (name: 'policy', icon: Icons.policy_rounded, label: 'Policy / Rule'),
    (name: 'article', icon: Icons.article_rounded, label: 'Document / Order'),
    (name: 'local_police', icon: Icons.local_police_rounded, label: 'Police Badge'),
    (name: 'handshake', icon: Icons.handshake_rounded, label: 'Community / Public'),
  ];

  static const List<({String label, int hexColor})> _themeColors = [
    (label: 'Deep Navy', hexColor: 0xFF1A237E),
    (label: 'Teal Blue', hexColor: 0xFF00838F),
    (label: 'Vibrant Amber', hexColor: 0xFFE65100),
    (label: 'Forest Green', hexColor: 0xFF1B5E20),
    (label: 'Crimson Red', hexColor: 0xFFB71C1C),
    (label: 'Royal Purple', hexColor: 0xFF4A148C),
  ];

  static IconData _iconFromName(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'gavel':
        return Icons.gavel_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'videocam':
        return Icons.videocam_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'policy':
        return Icons.policy_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'local_police':
        return Icons.local_police_rounded;
      case 'handshake':
        return Icons.handshake_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  void _openAnnouncementEditor({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    final data = isEditing ? doc.data() as Map<String, dynamic>? : null;

    final titleCtrl = TextEditingController(text: data?['title'] ?? '');
    final descCtrl = TextEditingController(text: data?['description'] ?? '');
    String selectedTag = data?['tag'] ?? 'New Law';
    String selectedIconName = data?['iconName'] ?? 'gavel';
    int selectedColor = (data?['iconColorHex'] as num?)?.toInt() ?? 0xFF1A237E;
    String targetScope = data?['targetAudience'] ?? 'All Users (All India)';
    String? targetState = data?['targetState'] ?? 'Maharashtra';
    String? targetDistrict = data?['targetDistrict'];
    String? targetStation = data?['targetStation'];
    final officerIdCtrl = TextEditingController(text: data?['targetOfficerId'] ?? '');
    bool isRedAlert = data?['isRedAlert'] == true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedIconData = _iconFromName(selectedIconName);
          final allDistricts = AppConstants.getDistrictsForUnitType(null);
          final availableStations = targetDistrict != null
              ? AppConstants.getStationsForDistrict(targetDistrict)
              : const <String>[];

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Title & Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Broadcast Announcement' : 'Create Broadcast / Push Notification',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Live Mobile Preview Box
                      Text(
                        'Live Broadcast Preview',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isRedAlert
                                ? [const Color(0xFFB71C1C), const Color(0xFFD32F2F)]
                                : [
                                    Color(selectedColor),
                                    Color(selectedColor).withValues(alpha: 0.85),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isRedAlert
                                  ? Colors.red.withValues(alpha: 0.4)
                                  : Color(selectedColor).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isRedAlert ? Icons.emergency : selectedIconData,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isRedAlert ? 'EMERGENCY RED ALERT' : selectedTag,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Target: $targetScope',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    titleCtrl.text.trim().isEmpty
                                        ? 'Announcement Title will appear here...'
                                        : titleCtrl.text.trim(),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    descCtrl.text.trim().isEmpty
                                        ? 'Detailed circular description and instructions will appear here...'
                                        : descCtrl.text.trim(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Red Alert Urgent Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isRedAlert ? Colors.red.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isRedAlert ? Colors.red.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.emergency_outlined,
                                  color: isRedAlert ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Red Alert / Emergency Push Notification',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isRedAlert ? Colors.red.shade900 : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Forces high priority push notification banner on officer devices',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isRedAlert,
                              activeTrackColor: Colors.red,
                              onChanged: (val) => setDialogState(() => isRedAlert = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Target Audience Hierarchy Selector
                      const Text(
                        'Target Audience Scope (Geographic Hierarchy)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: targetScope,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Notification Scope *',
                          prefixIcon: Icon(Icons.hub_outlined, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All Users (All India)', child: Text('All India (All Officers)')),
                          DropdownMenuItem(value: 'State', child: Text('State Level')),
                          DropdownMenuItem(value: 'District', child: Text('District Level')),
                          DropdownMenuItem(value: 'Police Station', child: Text('Specific Police Station')),
                          DropdownMenuItem(value: 'Individual Officer', child: Text('Individual Officer')),
                        ],
                        onChanged: (val) {
                          setDialogState(() {
                            targetScope = val ?? 'All Users (All India)';
                          });
                        },
                      ),
                      if (targetScope == 'District' || targetScope == 'Police Station') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: targetDistrict,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select District *',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: allDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              targetDistrict = val;
                              targetStation = null;
                            });
                          },
                        ),
                      ],
                      if (targetScope == 'Police Station') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: targetStation,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Police Station *',
                            prefixIcon: Icon(Icons.local_police_outlined, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: availableStations.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                          onChanged: (val) => setDialogState(() => targetStation = val),
                        ),
                      ],
                      if (targetScope == 'Individual Officer') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: officerIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Officer Sevaarth ID / Badge No / User ID *',
                            prefixIcon: Icon(Icons.person_search_outlined, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Category Tag Chips
                      const Text(
                        'Category Tag',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedTags.map((tag) {
                          final isSel = tag == selectedTag;
                          return ChoiceChip(
                            label: Text(tag),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedTag = tag);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Title Field
                      TextField(
                        controller: titleCtrl,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Announcement / Broadcast Title *',
                          hintText: 'e.g. BNSS 2023 — New Criminal Procedure Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Description / Instructions *',
                          hintText: 'Enter comprehensive circular details for field officers...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Icon Selector
                      const Text(
                        'Icon Badge',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableIcons.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final item = _availableIcons[idx];
                            final isSel = item.name == selectedIconName;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setDialogState(() => selectedIconName = item.name),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: isSel
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color Themes
                      const Text(
                        'Theme Color',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: _themeColors.map((theme) {
                          final isSel = theme.hexColor == selectedColor;
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setDialogState(() => selectedColor = theme.hexColor),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(theme.hexColor),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  if (isSel)
                                    BoxShadow(
                                      color: Color(theme.hexColor).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSel
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: Text(isEditing ? 'Update Broadcast' : 'Publish & Send Broadcast'),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final title = titleCtrl.text.trim();
                                    final desc = descCtrl.text.trim();
                                    if (title.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a title')),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSaving = true);
                                    try {
                                      final payload = {
                                        'title': title,
                                        'description': desc,
                                        'tag': selectedTag,
                                        'iconName': selectedIconName,
                                        'iconColorHex': selectedColor,
                                        'targetAudience': targetScope,
                                        'targetState': targetState,
                                        'targetDistrict': targetDistrict,
                                        'targetStation': targetStation,
                                        'targetOfficerId': officerIdCtrl.text.trim(),
                                        'isRedAlert': isRedAlert,
                                        'priority': isRedAlert ? 'urgent' : 'normal',
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      };

                                      if (isEditing) {
                                        await _firestore
                                            .collection('app_announcements')
                                            .doc(doc.id)
                                            .set(payload, SetOptions(merge: true));
                                      } else {
                                        payload['order'] = DateTime.now().millisecondsSinceEpoch;
                                        payload['createdAt'] = FieldValue.serverTimestamp();
                                        await _firestore
                                            .collection('app_announcements')
                                            .add(payload);
                                      }

                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.green,
                                            content: Text(
                                              isEditing
                                                  ? 'Broadcast updated! Target audience will receive this update.'
                                                  : 'Broadcast published live to $targetScope!',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() => isSaving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.red,
                                            content: Text('Error saving: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(DocumentSnapshot doc) {
    final title = (doc.data() as Map<String, dynamic>?)?['title'] ?? 'this announcement';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Text('Are you sure you want to delete "$title"? It will be removed immediately from all users\' app carousels.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestore.collection('app_announcements').doc(doc.id).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement removed.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Colors.red, content: Text('Error deleting: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ensureDefaultsSeeded();
  }

  void _ensureDefaultsSeeded() async {
    try {
      final snap = await _firestore.collection('app_announcements').limit(1).get();
      if (snap.docs.isEmpty) {
        _seedDefaultBulletins(silent: true);
      }
    } catch (_) {}
  }

  void _seedDefaultBulletins({bool silent = false}) async {
    final defaults = [
      {
        'title': 'BNSS 2023 — New Criminal Procedure Code',
        'description':
            'Bharatiya Nagarik Suraksha Sanhita (BNSS) replaces CrPC with stricter timelines for investigation and trial.',
        'iconName': 'gavel',
        'iconColorHex': 0xFF1A237E,
        'tag': 'New Law',
        'order': 1,
      },
      {
        'title': 'POCSO Amendment — Stricter Penalties',
        'description':
            'Recent amendments to POCSO Act 2012 prescribe enhanced punishment for repeat offenders and faster trial timelines.',
        'iconName': 'shield',
        'iconColorHex': 0xFF00838F,
        'tag': 'Amendment',
        'order': 2,
      },
      {
        'title': 'Circular: Body Camera Mandate',
        'description':
            'All field officers must wear body cameras during raids and arrests effective 1st May. Submit usage reports weekly.',
        'iconName': 'videocam',
        'iconColorHex': 0xFFE65100,
        'tag': 'Circular',
        'order': 3,
      },
      {
        'title': 'Cyber Crime Awareness — New SOP',
        'description':
            'Updated Standard Operating Procedure for cybercrime investigation units. First responders must complete e-training.',
        'iconName': 'security',
        'iconColorHex': 0xFF1B5E20,
        'tag': 'Awareness',
        'order': 4,
      },
    ];

    try {
      final existing = await _firestore.collection('app_announcements').get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      for (final item in defaults) {
        await _firestore.collection('app_announcements').add({
          ...item,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Default legal announcements published to app carousel!'),
          ),
        );
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Carousel & Announcements',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage the news carousel, circulars & law updates shown to all officers on the mobile app.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restore_page_outlined),
                      label: const Text('Reset Defaults'),
                      onPressed: () => _seedDefaultBulletins(),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Announcement'),
                      onPressed: () => _openAnnouncementEditor(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Announcements Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('app_announcements')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    // Automatically seed defaults if first time
                    _ensureDefaultsSeeded();
                    return const Center(child: CircularProgressIndicator());
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 480,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final doc = docs[idx];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'Announcement';
                      final desc = data['description'] ?? '';
                      final tag = data['tag'] ?? 'Notice';
                      final iconName = data['iconName'] ?? 'gavel';
                      final colorHex = (data['iconColorHex'] as num?)?.toInt() ?? 0xFF1A237E;
                      final iconData = _iconFromName(iconName);

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Column(
                          children: [
                            // Banner Card Content
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(colorHex),
                                      Color(colorHex).withValues(alpha: 0.85),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(iconData, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tag,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            desc,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Card Actions
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit'),
                                    onPressed: () => _openAnnouncementEditor(doc: doc),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                    onPressed: () => _confirmDelete(doc),
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
}
