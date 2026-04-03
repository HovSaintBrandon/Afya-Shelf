import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _clinicNameCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _clinicNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AfyaTheme.destructive),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
      _confirmPasswordCtrl.text,
      _clinicNameCtrl.text.trim(),
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please sign in.'),
          backgroundColor: AfyaTheme.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AfyaTheme.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AfyaTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AfyaTheme.primary.withOpacity(0.08),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Column(
            children: [
              Text('Create Account',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text('Join Afya Shelf Pharmacy Network',
                style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: AfyaTheme.border.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel('Username'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Choose a username',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _inputLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _inputLabel('Confirm Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          hintText: 'Re-type your password',
                          prefixIcon: Icon(Icons.lock_reset, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _inputLabel('Clinic Name'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _clinicNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. City Pharmacy',
                          prefixIcon: Icon(Icons.local_pharmacy_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.loading ? null : _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AfyaTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: auth.loading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: TextStyle(color: AfyaTheme.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Sign In', style: TextStyle(color: AfyaTheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(label,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AfyaTheme.textPrimary),
    );
  }
}
