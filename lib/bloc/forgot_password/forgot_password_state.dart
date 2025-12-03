import 'package:equatable/equatable.dart';

class ForgotPasswordState extends Equatable {
  final String userId;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;

  const ForgotPasswordState({
    this.userId = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isValid {
    return userId.isNotEmpty;
  }

  ForgotPasswordState copyWith({
    String? userId,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return ForgotPasswordState(
      userId: userId ?? this.userId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        isSubmitting,
        isSuccess,
        errorMessage,
        successMessage,
      ];
}

