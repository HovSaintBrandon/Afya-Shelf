import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _clinicNameCtrl = TextEditingController();
  String _role = 'PHARMACIST';

  void _addWorker() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty || _clinicNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AfyaTheme.destructive),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.addWorker(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
      _role,
      _clinicNameCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker added successfully'), backgroundColor: AfyaTheme.success),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to add worker'), backgroundColor: AfyaTheme.destructive),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Management', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AfyaTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Worker', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Create an account for a pharmacist or manager in your clinic.',
              style: GoogleFonts.inter(fontSize: 13, color: AfyaTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            _inputField('Username', _usernameCtrl, Icons.person_outline),
            const SizedBox(height: 20),
            _inputField('Password', _passwordCtrl, Icons.lock_outline, obscure: true),
            const SizedBox(height: 20),
            Text('Role Selection', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AfyaTheme.surfaceMuted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AfyaTheme.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    activeColor: AfyaTheme.primary,
                    title: Text('Pharmacist', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Can dispense and view inventory', style: GoogleFonts.inter(fontSize: 12)),
                    value: 'PHARMACIST',
                    groupValue: _role,
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    activeColor: AfyaTheme.primary,
                    title: Text('Manager', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Full inventory & staff control', style: GoogleFonts.inter(fontSize: 12)),
                    value: 'MANAGER',
                    groupValue: _role,
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _inputField('Clinic Name', _clinicNameCtrl, Icons.local_pharmacy_outlined),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _addWorker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AfyaTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: auth.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Worker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AfyaTheme.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
