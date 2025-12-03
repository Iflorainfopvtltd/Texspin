import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final String userId;
  final String password;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? loginData;

  const LoginState({
    this.userId = '',
    this.password = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.loginData,
  });

  bool get isValid {
    return userId.isNotEmpty && password.isNotEmpty;
  }

  LoginState copyWith({
    String? userId,
    String? password,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    Map<String, dynamic>? loginData,
    bool clearError = false,
    bool clearLoginData = false,
  }) {
    return LoginState(
      userId: userId ?? this.userId,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loginData: clearLoginData ? null : (loginData ?? this.loginData),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    password,
    isSubmitting,
    isSuccess,
    errorMessage,
    loginData,
  ];
}
