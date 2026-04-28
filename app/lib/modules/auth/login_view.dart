import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthController _ctrl = Get.put(AuthController());

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _ctrl.login(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFBF6EF), Color(0xFFF3E6D4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.seed, Color(0xFFC44318)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.seed.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 28),
                Text('Welcome back', style: theme.textTheme.displayMedium),
                const SizedBox(height: 10),
                Text(
                  "Share what you're cooking —\nfind cooks in your neighborhood.",
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.inkSoft, height: 1.5),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppTheme.inkSoft),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppTheme.inkSoft),
                        ),
                        validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
                      ),
                      const SizedBox(height: 24),
                      Obx(() => FilledButton(
                            onPressed: _ctrl.isLoading.value ? null : _submit,
                            child: _ctrl.isLoading.value
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Log in'),
                          )),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.register),
                        child: Text.rich(
                          TextSpan(
                            text: 'New here? ',
                            style: TextStyle(color: AppTheme.inkSoft, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(
                                text: 'Create an account',
                                style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
