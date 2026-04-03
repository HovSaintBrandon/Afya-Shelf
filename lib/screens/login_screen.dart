import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AfyaTheme.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          child: Column(
            children: [
              // Top section
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AfyaTheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.local_pharmacy, size: 36, color: AfyaTheme.primary),
              ),
              const SizedBox(height: 20),
              Text('Afya Shelf',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AfyaTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text('Pharmacy Inventory Management',
                style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              // Form card
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
                      Text('Welcome back',
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
                      ),
                      const SizedBox(height: 32),
                      _inputLabel('Username'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter your username',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _inputLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AfyaTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: auth.loading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {},
                child: Text('Forgot password?', style: TextStyle(color: AfyaTheme.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No account? ', style: TextStyle(color: AfyaTheme.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Text('Sign Up', style: TextStyle(color: AfyaTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: AfyaTheme.textSecondary)),
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
