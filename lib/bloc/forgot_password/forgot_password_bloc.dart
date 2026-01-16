import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ApiService _apiService;

  ForgotPasswordBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const ForgotPasswordState()) {
    on<ForgotPasswordUserIdChanged>(_onUserIdChanged);
    on<ForgotPasswordSubmitted>(_onSubmitted);
    on<ForgotPasswordReset>(_onReset);
  }

  void _onUserIdChanged(
    ForgotPasswordUserIdChanged event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(state.copyWith(userId: event.userId, clearError: true));
  }

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(
        errorMessage: 'Please enter your user ID',
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final response = await _apiService.forgotPassword(
        email: state.userId, // Using userId field to store email
      );

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        successMessage: response['message'] ??
            'New password sent to your email. Please check your inbox.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onReset(
    ForgotPasswordReset event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(const ForgotPasswordState());
  }
}

