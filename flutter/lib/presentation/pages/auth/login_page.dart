import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo / Branding
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/app_icon.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your AI-powered dating coach',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(flex: 2),

              // Error message
              if (authState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBackground,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Sign in with Google
              _SignInButton(
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authProvider.notifier).signInWithGoogle().then((success) {
                          if (success && context.mounted) context.go('/');
                        }),
                icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
                label: 'Sign in with Google',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
              ),

              const SizedBox(height: 12),

              // Sign in with Apple (iOS/macOS only)
              if (AuthNotifier.isAppleSignInAvailable)
                _SignInButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signInWithApple().then((success) {
                            if (success && context.mounted) context.go('/');
                          }),
                  icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                  label: 'Sign in with Apple',
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  borderColor: AppColors.borderLight,
                ),

              if (AuthNotifier.isAppleSignInAvailable) const SizedBox(height: 12),

              // Loading indicator
              if (authState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),

              const Spacer(),

              // Skip button
              TextButton(
                onPressed: authState.isLoading ? null : () => context.go('/'),
                child: const Text(
                  'Continue without signing in',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SignInButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
