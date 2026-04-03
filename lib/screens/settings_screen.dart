import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import 'staff_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text('Settings',
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text('Manage your account and preferences',
            style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          // Profile Section
          Text('Account Profile',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Username', value: auth.user?.username ?? ''),
                const Divider(height: 32),
                _InfoRow(label: 'Role', value: auth.user?.role ?? ''),
                const Divider(height: 32),
                _InfoRow(label: 'Clinic ID', value: auth.user?.clinicId ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Management Section (Visible to Owner/Manager)
          if (auth.user?.role == 'OWNER' || auth.user?.role == 'ADMIN' || auth.user?.role == 'MANAGER') ...[
            Text('Clinic Management',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_outline, color: AfyaTheme.primary),
                    title: Text('Staff Management', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Manage pharmacists and managers', style: GoogleFonts.inter(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz, color: AfyaTheme.primaryLight),
                    title: Text('Switch Clinic', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Change your active branch', style: GoogleFonts.inter(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      _showSwitchClinicDialog(context, auth);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          // API Section
          Text('API Configuration',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backend Server URL',
                  style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AfyaTheme.surfaceMuted, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(ApiConfig.baseUrl,
                          style: GoogleFonts.firaCode(fontSize: 12, color: AfyaTheme.primary),
                        ),
                      ),
                      Icon(Icons.copy, size: 16, color: AfyaTheme.primary.withOpacity(0.6)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Update this in lib/config/api_config.dart',
                  style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          OutlinedButton(
            onPressed: () => auth.logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AfyaTheme.destructive,
              side: const BorderSide(color: AfyaTheme.destructive),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Logout from Device', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Afya Shelf · Open Source Management',
              style: GoogleFonts.inter(fontSize: 12, color: AfyaTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSwitchClinicDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch Clinic', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter Clinic ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                final success = await auth.switchClinic(id);
                if (success && context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary)),
      ],
    );
  }
}
