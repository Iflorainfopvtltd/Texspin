import 'package:equatable/equatable.dart';

class RegistrationState extends Equatable {
  final String name;
  final String id;
  final String password;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  const RegistrationState({
    this.name = '',
    this.id = '',
    this.password = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.userData,
  });

  bool get isValid {
    return name.isNotEmpty && id.isNotEmpty && password.isNotEmpty;
  }

  RegistrationState copyWith({
    String? name,
    String? id,
    String? password,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    Map<String, dynamic>? userData,
    bool clearError = false,
    bool clearUserData = false,
  }) {
    return RegistrationState(
      name: name ?? this.name,
      id: id ?? this.id,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userData: clearUserData ? null : (userData ?? this.userData),
    );
  }

  @override
  List<Object?> get props => [
        name,
        id,
        password,
        isSubmitting,
        isSuccess,
        errorMessage,
        userData,
      ];
}

