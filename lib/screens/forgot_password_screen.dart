import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your username or email'),
          backgroundColor: AfyaTheme.destructive,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(username);
    
    if (mounted) {
      if (success) {
        // Show success dialog or snackbar and pop
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Email Sent', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: const Text('A temporary password has been sent to your email. Please use it to log in.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  Navigator.pop(context); // go back to login
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Failed to request password reset'),
            backgroundColor: AfyaTheme.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AfyaTheme.textPrimary,
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
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
                      Text('Reset Password',
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AfyaTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text('Enter your username or email to receive a temporary password.',
                        style: GoogleFonts.inter(fontSize: 14, color: AfyaTheme.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      Text('Username / Email',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AfyaTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter your username or email',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        onSubmitted: (_) => _resetPassword(),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.loading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AfyaTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: auth.loading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
