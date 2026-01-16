import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_input.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_alert.dart';
import '../../theme/app_theme.dart';
import '../../bloc/forgot_password/forgot_password_bloc.dart';
import '../../bloc/forgot_password/forgot_password_event.dart';
import '../../bloc/forgot_password/forgot_password_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;

  const ForgotPasswordScreen({super.key, required this.onNavigateToLogin});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordUserIdChanged(_emailController.text.trim()),
    );
    context.read<ForgotPasswordBloc>().add(const ForgotPasswordSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.blue50, Colors.white, AppTheme.purple50],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
                  listener: (context, state) {
                    // Success is handled in the UI below
                  },
                  builder: (context, state) {
                    if (state.isSuccess) {
                      return CustomCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.green100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppTheme.green600,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Check Your Email',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.successMessage ??
                                  "We've sent password reset instructions to ${state.userId.isEmpty ? 'your email' : state.userId}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.gray600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Please check your inbox and follow the link to reset your password. The link will expire in 24 hours.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.gray600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: 'Back to Sign In',
                              onPressed: widget.onNavigateToLogin,
                              icon: const Icon(Icons.arrow_back, size: 16),
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Didn't receive the email? ",
                                  style: TextStyle(color: AppTheme.gray600),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<ForgotPasswordBloc>().add(
                                      const ForgotPasswordReset(),
                                    );
                                    _emailController.clear();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Try again',
                                    style: TextStyle(color: AppTheme.blue600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Logo/Brand
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.blue600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mail,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your email to receive reset instructions',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Reset Form
                        CustomCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (state.errorMessage != null) ...[
                                  CustomAlert(
                                    message: state.errorMessage!,
                                    variant: AlertVariant.destructive,
                                    icon: const Icon(
                                      Icons.error_outline,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                CustomTextInput(
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  enabled: !state.isSubmitting,
                                  textInputAction: TextInputAction.send,
                                  onChanged: (value) {
                                    context.read<ForgotPasswordBloc>().add(
                                      ForgotPasswordUserIdChanged(value),
                                    );
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "We'll send you instructions to reset your password",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Send Reset Link',
                                  onPressed: state.isSubmitting
                                      ? null
                                      : _handleSubmit,
                                  isLoading: state.isSubmitting,
                                  icon: const Icon(Icons.mail, size: 16),
                                  isFullWidth: true,
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: 'Back to Sign In',
                                  onPressed: widget.onNavigateToLogin,
                                  variant: ButtonVariant.ghost,
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  isFullWidth: true,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Text(
                          '© 2025 Project Management System. All rights reserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
