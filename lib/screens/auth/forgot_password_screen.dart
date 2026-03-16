import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) setState(() { _sent = true; _loading = false; });
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.code == 'user-not-found'
            ? 'No account found with this email.'
            : e.message ?? 'Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Container(width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.blue, size: 34)),
        const SizedBox(height: 24),
        const Text('Reset Password', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 8),
        const Text('Enter the email address linked to your account and we\'ll send you a reset link.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMuted, height: 1.5)),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined)),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_error!, style: const TextStyle(
                  color: AppColors.red, fontFamily: 'Nunito', fontSize: 13))),
            ]),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
                ? const SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Send Reset Link',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Back to Sign In',
              style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito')),
        )),
      ]),
    );
  }

  Widget _buildSuccess() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const SizedBox(height: 40),
      Container(width: 80, height: 80,
        decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 44)),
      const SizedBox(height: 24),
      const Text('Email Sent!', style: TextStyle(
          fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
        textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(
        'We sent a password reset link to\n${_emailCtrl.text.trim()}\n\nCheck your inbox (and spam folder).',
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMuted, height: 1.6),
        textAlign: TextAlign.center),
      const SizedBox(height: 40),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Back to Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
        ),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => setState(() => _sent = false),
        child: const Text('Resend email',
            style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito'))),
    ]);
  }
}
