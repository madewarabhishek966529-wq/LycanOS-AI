import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../providers/auth_providers.dart';

/// Two-step flow in one screen: request a reset token by email, then
/// (once the person has it — delivered by email once the Settings-phase
/// notification service exists) enter the token + new password. Splitting
/// this into two routes would add navigation ceremony for very little
/// benefit at this stage.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _requestSent = false;
  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_requestFormKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await ref.read(forgotPasswordUseCaseProvider).call(email: _emailController.text.trim());

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (result is Success<void>) _requestSent = true;
    });

    final message = result is Success<void>
        ? 'If that email exists, reset instructions have been sent.'
        : (result as Error<void>).failure.message;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await ref.read(resetPasswordUseCaseProvider).call(
          resetToken: _tokenController.text.trim(),
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is Success<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset — sign in with your new password.')),
      );
      context.go(RouteNames.login);
    } else {
      final failure = (result as Error<void>).failure;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassCard(
              blur: false,
              padding: const EdgeInsets.all(32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _requestSent ? _buildResetForm(context) : _buildRequestForm(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm(BuildContext context) {
    return Form(
      key: _requestFormKey,
      child: Column(
        key: const ValueKey('request'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reset your password', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            "Enter your email and we'll send reset instructions.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email',
            controller: _emailController,
            hintText: 'you@business.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            enabled: !_isSubmitting,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Send reset instructions', onPressed: _submitRequest, isLoading: _isSubmitting),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _requestSent = true),
              child: const Text('Already have a reset token?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(BuildContext context) {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter your reset token', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Paste the token from your reset email and choose a new password.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Reset token',
            controller: _tokenController,
            hintText: 'Paste token here',
            prefixIcon: Icons.vpn_key_outlined,
            enabled: !_isSubmitting,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Reset token is required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'New password',
            controller: _newPasswordController,
            obscureText: _obscure,
            prefixIcon: Icons.lock_outline,
            enabled: !_isSubmitting,
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
          AppButton(label: 'Reset password', onPressed: _submitReset, isLoading: _isSubmitting),
        ],
      ),
    );
  }
}
