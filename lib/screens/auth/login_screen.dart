import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_input.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_alert.dart';
import '../../theme/app_theme.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic> loginData)? onLoginSuccess;
  final VoidCallback onNavigateToRegister;
  final VoidCallback onNavigateToForgot;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    required this.onNavigateToRegister,
    required this.onNavigateToForgot,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateUserId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<LoginBloc>().add(
      LoginUserIdChanged(_userIdController.text.trim()),
    );
    context.read<LoginBloc>().add(
      LoginPasswordChanged(_passwordController.text),
    );
    context.read<LoginBloc>().add(const LoginSubmitted());
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
                child: Column(
                  children: [
                    // Logo/Brand
                    Image.asset(
                      'assets/images/logo_white.png',
                      width: 128,
                      height: 128,
                    ),
                    // const SizedBox(height: 12),
                    const Text(
                      'Project Management System',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to your account',
                      style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                    ),
                    const SizedBox(height: 32),

                    // Login Form
                    BlocConsumer<LoginBloc, LoginState>(
                      listener: (context, state) {
                        if (state.isSuccess && state.loginData != null) {
                          // Call success callback if provided
                          if (widget.onLoginSuccess != null) {
                            widget.onLoginSuccess!(state.loginData!);
                          }
                        }
                      },
                      builder: (context, state) {
                        // Sync controllers with state when credentials are loaded
                        if (state.userId.isNotEmpty &&
                            _userIdController.text != state.userId) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _userIdController.text = state.userId;
                          });
                        }
                        if (state.password.isNotEmpty &&
                            _passwordController.text != state.password) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _passwordController.text = state.password;
                          });
                        }

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
                                    icon: const Icon(
                                      Icons.error_outline,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                CustomTextInput(
                                  label: 'Email',
                                  hint: 'Enter your Email',
                                  controller: _userIdController,
                                  validator: _validateUserId,
                                  enabled: !state.isSubmitting,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (value) {
                                    context.read<LoginBloc>().add(
                                      LoginUserIdChanged(value),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.foreground,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: widget.onNavigateToForgot,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.blue600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CustomTextInput(
                                  hint: 'Enter your Password',
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
                                    context.read<LoginBloc>().add(
                                      LoginPasswordChanged(value),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Sign In',
                                  onPressed: state.isSubmitting
                                      ? null
                                      : _handleSubmit,
                                  isLoading: state.isSubmitting,
                                  isFullWidth: true,
                                  size: ButtonSize.lg,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // const SizedBox(height: 16),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     const Text(
                    //       "Don't have an account? ",
                    //       style: TextStyle(color: AppTheme.gray600),
                    //     ),
                    //     TextButton(
                    //       onPressed: widget.onNavigateToRegister,
                    //       style: TextButton.styleFrom(
                    //         padding: EdgeInsets.zero,
                    //         minimumSize: Size.zero,
                    //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //       ),
                    //       child: const Text(
                    //         'Create account',
                    //         style: TextStyle(color: AppTheme.blue600),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 32),
                    const Text(
                      '© 2025 Project Management System. All rights reserved by IFLORA INFO PVT LTD.',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray600),
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
