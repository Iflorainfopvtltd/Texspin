import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_input.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_alert.dart';
import '../../theme/app_theme.dart';
import '../../bloc/registration/registration_bloc.dart';
import '../../bloc/registration/registration_event.dart';
import '../../bloc/registration/registration_state.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final Function(Map<String, dynamic>? userData)? onRegistrationSuccess;

  const RegisterScreen({
    super.key,
    required this.onNavigateToLogin,
    this.onRegistrationSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Email ID';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<RegistrationBloc>().add(
          RegistrationNameChanged(_nameController.text.trim()),
        );
    context.read<RegistrationBloc>().add(
          RegistrationIdChanged(_idController.text.trim()),
        );
    context.read<RegistrationBloc>().add(
          RegistrationPasswordChanged(_passwordController.text),
        );
    context.read<RegistrationBloc>().add(const RegistrationSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.blue50,
              Colors.white,
              AppTheme.purple50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    // Logo/Brand
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.blue600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bar_chart,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join the APQP Management System',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.gray600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Form
                    BlocConsumer<RegistrationBloc, RegistrationState>(
                      listener: (context, state) {
                        if (state.isSuccess) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registration successful!'),
                              backgroundColor: AppTheme.green500,
                            ),
                          );
                          // Call success callback if provided
                          if (widget.onRegistrationSuccess != null) {
                            widget.onRegistrationSuccess!(state.userData);
                          }
                        }
                      },
                      builder: (context, state) {
                        return CustomCard(
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
                                    icon: const Icon(Icons.error_outline, size: 16),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                CustomTextInput(
                                  label: 'Full Name',
                                  hint: 'John Doe',
                                  controller: _nameController,
                                  validator: _validateName,
                                  enabled: !state.isSubmitting,
                                  onChanged: (value) {
                                    context.read<RegistrationBloc>().add(
                                          RegistrationNameChanged(value),
                                        );
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextInput(
                                  label: 'Email ID',
                                  hint: 'Enter your Email ID',
                                  controller: _idController,
                                  validator: _validateId,
                                  enabled: !state.isSubmitting,
                                  onChanged: (value) {
                                    context.read<RegistrationBloc>().add(
                                          RegistrationIdChanged(value),
                                        );
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextInput(
                                  label: 'Password',
                                  hint: 'Create a password',
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: _validatePassword,
                                  enabled: !state.isSubmitting,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppTheme.gray600,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  onChanged: (value) {
                                    context.read<RegistrationBloc>().add(
                                          RegistrationPasswordChanged(value),
                                        );
                                  },
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Create Account',
                                  onPressed: state.isSubmitting ? null : _handleSubmit,
                                  isLoading: state.isSubmitting,
                                  isFullWidth: true,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToLogin,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(color: AppTheme.blue600),
                          ),
                        ),
                      ],
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
