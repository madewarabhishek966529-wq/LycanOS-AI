import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../providers/auth_state_provider.dart';

/// Self-registration always creates a new business with the registering
/// user as its Owner (see backend AuthService.register — there's no other
/// path to an Owner account). Manager/Cashier/Employee accounts are
/// created by an Owner/Manager from within the app in Phase 7.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authStateProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          businessName: _businessNameController.text.trim(),
        );
    if (!success && mounted) {
      final error = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authStateProvider.select((s) => s.isSubmitting));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isSubmitting ? null : () => context.go(RouteNames.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassCard(
              blur: false,
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Set up your business',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your ${AppConstants.appName} Owner account',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Business name',
                      controller: _businessNameController,
                      hintText: 'Sharma General Store',
                      prefixIcon: Icons.storefront_outlined,
                      enabled: !isSubmitting,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Business name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Your full name',
                      controller: _fullNameController,
                      hintText: 'Priya Sharma',
                      prefixIcon: Icons.person_outline,
                      enabled: !isSubmitting,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Your name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      hintText: 'you@business.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline,
                      enabled: !isSubmitting,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      hintText: 'At least 8 characters, 1 letter + 1 number',
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                      enabled: !isSubmitting,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) return 'At least 8 characters';
                        if (!value.contains(RegExp(r'[A-Za-z]')) || !value.contains(RegExp(r'[0-9]'))) {
                          return 'Must contain a letter and a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    AppButton(label: 'Create account', onPressed: _handleSubmit, isLoading: isSubmitting),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?', style: Theme.of(context).textTheme.bodySmall),
                        TextButton(
                          onPressed: isSubmitting ? null : () => context.go(RouteNames.login),
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
