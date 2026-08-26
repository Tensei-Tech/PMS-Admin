import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';
import 'login_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isRevokingSessions = false;

  void _showEditProfileDialog(Map<String, dynamic> currentData) {
    final nameCtrl = TextEditingController(text: currentData['name'] ?? 'Master Admin');
    final email = FirebaseAuth.instance.currentUser?.email ?? currentData['email']?.toString() ?? 'admin@police.gov.in';
    final emailCtrl = TextEditingController(text: email);
    final phoneCtrl = TextEditingController(text: currentData['phone'] ?? currentData['phoneNumber'] ?? '+91 98765 43210');
    final photoCtrl = TextEditingController(text: currentData['photoUrl'] ?? currentData['profilePhoto'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Admin Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update your administrator profile details. Changes reflect across the command console in real-time.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 16),
                        // 1. Full Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 14),
                        // 2. Email (Read-Only)
                        TextFormField(
                          controller: emailCtrl,
                          readOnly: true,
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            helperText: 'Contact system owner to change registered email',
                            helperStyle: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // 3. Phone Number (for 2FA SMS)
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                            labelText: 'Phone Number (for 2FA SMS)',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // 4. Profile Photo URL (Optional)
                        TextFormField(
                          controller: photoCtrl,
                          decoration: InputDecoration(
                            labelText: 'Profile Photo URL (Optional)',
                            prefixIcon: const Icon(Icons.image_outlined),
                            hintText: 'https://example.com/photo.jpg',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await AppSettingsService.updateAdminProfile(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              photoUrl: photoCtrl.text.trim().isNotEmpty ? photoCtrl.text.trim() : null,
                            );
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Admin Profile updated successfully!'),
                                backgroundColor: Colors.green.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to update profile: $e'),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock_reset_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ensure your new password contains at least 6 characters and includes alphanumeric symbols for security.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: currentPassCtrl,
                          obscureText: obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Current Password *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: newPassCtrl,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'New Password *',
                            prefixIcon: const Icon(Icons.password_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: confirmPassCtrl,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password *',
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) {
                            if (v != newPassCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.email_outlined, size: 14),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await AppSettingsService.sendPasswordResetEmail();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset link sent to your registered admin email address.'),
                                    backgroundColor: Color(0xFF15803D),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              } catch (e) {
                                String msg = e.toString();
                                if (msg.startsWith('Exception: ')) msg = msg.substring(11);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $msg'),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            label: const Text('Send Password Reset Email instead', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isChanging
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isChanging = true);
                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await AppSettingsService.changePassword(
                              currentPassword: currentPassCtrl.text.trim(),
                              newPassword: newPassCtrl.text.trim(),
                            );
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Password updated successfully!'),
                                backgroundColor: Colors.green.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isChanging = false);
                            String msg = e.toString();
                            if (msg.startsWith('Exception: ')) {
                              msg = msg.substring(11);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red.shade800,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                  child: isChanging
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final pagePadding = isMobile ? 14.0 : (isTablet ? 20.0 : 28.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: AppSettingsService.getAdminProfileStream(),
            builder: (context, profileSnapshot) {
              final adminData = profileSnapshot.data?.data() ?? {};
              final currentAdminName = adminData['name']?.toString() ?? 'Master Admin';
              final currentEmail = FirebaseAuth.instance.currentUser?.email ?? adminData['email']?.toString() ?? 'admin@police.gov.in';
              final currentRole = adminData['role']?.toString() ?? 'super_admin';
              final photoUrl = adminData['photoUrl']?.toString() ?? adminData['profilePhoto']?.toString();

              // Direct values extracted from Firestore live snapshot
              final bool darkMode = adminData['darkMode'] == true;
              final bool pushNotifications = adminData['pushNotifications'] ?? true;
              final bool autoArchiveCases = adminData['autoArchiveCases'] == true;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title & Description
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings & Preferences',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 22 : 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage system settings, administrator profile, and notification preferences',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 1. ADMIN PROFILE SECTION
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Admin Profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        onPressed: () => _showEditProfileDialog(adminData),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14.0 : 18.0),
                      child: Column(
                        children: [
                          // Responsive Profile Header Layout
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: isMobile ? 24 : 28,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: (photoUrl == null || photoUrl.isEmpty)
                                        ? Icon(
                                            Icons.admin_panel_settings,
                                            size: isMobile ? 28 : 32,
                                            color: theme.colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentAdminName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 16 : 18,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentEmail,
                                        style: TextStyle(
                                          color: theme.colorScheme.outline,
                                          fontSize: isMobile ? 12.5 : 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Chip(
                                avatar: const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF2563EB)),
                                label: Text(
                                  currentRole == 'super_admin' ? 'Master Admin' : currentRole.toUpperCase(),
                                ),
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFF93C5FD)),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF1D4ED8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Change Password Flow Row
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_clock_outlined, size: 18, color: theme.colorScheme.outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Account Security & Password',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.key_rounded, size: 16),
                                label: const Text('Change Password'),
                                onPressed: _showChangePasswordDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==========================================
                  // 2. SYSTEM CONFIGURATION SECTION
                  // ==========================================
                  Text(
                    'System Configuration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        // 🌙 Dark Mode Switch
                        _buildResponsiveSwitchRow(
                          context: context,
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark Mode',
                          subtitle: 'Enable dark theme interface for high-contrast viewing',
                          value: darkMode,
                          onChanged: (val) async {
                            await AppSettingsService.toggleDarkMode(val);
                          },
                        ),
                        const Divider(height: 1),

                        // 🔔 Push Notifications Switch
                        _buildResponsiveSwitchRow(
                          context: context,
                          icon: Icons.notifications_active_outlined,
                          title: 'Push Notifications for New Approvals',
                          subtitle: 'Receive real-time alerts when new officers request registration',
                          value: pushNotifications,
                          onChanged: (val) async {
                            await AppSettingsService.togglePushNotifications(val);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val
                                    ? 'Push alerts enabled for officer registration & approvals.'
                                    : 'Push alerts silenced.'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),

                        // 📦 Auto-Archive Closed Cases Switch
                        _buildResponsiveSwitchRow(
                          context: context,
                          icon: Icons.archive_outlined,
                          title: 'Auto-Archive Closed Cases',
                          subtitle: 'Automatically move resolved cases to archival storage after 30 days',
                          value: autoArchiveCases,
                          onChanged: (val) async {
                            final archived = await AppSettingsService.toggleAutoArchive(val);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val
                                    ? 'Auto-archive activated${archived > 0 ? " ($archived eligible cases moved to archive)" : ""}.'
                                    : 'Auto-archive paused.'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==========================================
                  // 3. ACCOUNT ACTIONS & SESSIONS SECTION
                  // ==========================================
                  Text(
                    'Account Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Active Sessions Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14.0 : 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.devices_rounded, size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Active Console Sessions',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        'Manage authorized devices & browser sessions for this account',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: _isRevokingSessions
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.red.shade700,
                                        ),
                                      )
                                    : const Icon(Icons.phonelink_erase_rounded, size: 16),
                                label: Text(_isRevokingSessions ? 'Logging out other devices...' : 'Logout All Other Devices'),
                                onPressed: _isRevokingSessions
                                    ? null
                                    : () async {
                                        setState(() => _isRevokingSessions = true);
                                        try {
                                          final count = await AppSettingsService.logoutAllOtherSessions();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(count > 0
                                                  ? 'All other sessions have been logged out ($count device(s) disconnected).'
                                                  : 'All other sessions have been logged out.'),
                                              backgroundColor: const Color(0xFF15803D),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          String msg = e.toString();
                                          if (msg.startsWith('Exception: ')) msg = msg.substring(11);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to logout other devices: $msg'),
                                              backgroundColor: const Color(0xFFDC2626),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 4),
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isRevokingSessions = false);
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          StreamBuilder<List<AdminSession>>(
                            stream: AppSettingsService.getActiveSessionsStream(),
                            builder: (context, sessionSnap) {
                              final sessions = sessionSnap.data ?? [];
                              if (sessions.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('Current Browser Session Active', style: TextStyle(fontSize: 13)),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sessions.length,
                                separatorBuilder: (ctx, i) => const Divider(height: 12),
                                itemBuilder: (ctx, i) {
                                  final s = sessions[i];
                                  return Row(
                                    children: [
                                      Icon(
                                        s.isCurrent ? Icons.laptop_chromebook_rounded : Icons.desktop_windows_outlined,
                                        size: 22,
                                        color: s.isCurrent ? Colors.green.shade700 : theme.colorScheme.outline,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    s.browser,
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (s.isCurrent) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.green.shade300),
                                                    ),
                                                    child: Text(
                                                      'Current Session',
                                                      style: TextStyle(
                                                        color: Colors.green.shade800,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              'IP: ${s.ipAddress} • Last Active: ${_formatSessionTime(s.lastActive)}',
                                              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.outline),
                                            ),
                                          ],
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
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🚪 Log Out of Console Danger Card
                  Card(
                    elevation: 1,
                    color: isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isDark ? Colors.red.shade800.withValues(alpha: 0.5) : Colors.red.shade200),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14.0 : 18.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Log Out of Console',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'End current master admin session securely and return to portal login.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final nav = Navigator.of(context);
                                        try {
                                          await FirebaseAuth.instance.signOut();
                                        } catch (_) {}

                                        if (!mounted) return;

                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Logged out of Master Admin Console.'),
                                            behavior: SnackBarBehavior.floating,
                                            width: 400,
                                          ),
                                        );

                                        nav.pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const LoginView()),
                                          (route) => false,
                                        );
                                      },
                                      icon: const Icon(Icons.logout_rounded, size: 18),
                                      label: const Text(
                                        'Logout',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Log Out of Console',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'End current master admin session securely and return to portal login.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    height: 46,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final nav = Navigator.of(context);
                                        try {
                                          await FirebaseAuth.instance.signOut();
                                        } catch (_) {}

                                        if (!mounted) return;

                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Logged out of Master Admin Console.'),
                                            behavior: SnackBarBehavior.floating,
                                            width: 400,
                                          ),
                                        );

                                        nav.pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const LoginView()),
                                          (route) => false,
                                        );
                                      },
                                      icon: const Icon(Icons.logout_rounded, size: 18),
                                      label: const Text(
                                        'Logout',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveSwitchRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 16.0,
        vertical: 12.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _formatSessionTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
