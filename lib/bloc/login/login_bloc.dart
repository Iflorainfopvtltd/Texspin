import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../utils/shared_preferences_manager.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService _apiService;

  LoginBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const LoginState()) {
    on<LoginUserIdChanged>(_onUserIdChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginReset>(_onReset);
  }

  void _onUserIdChanged(
    LoginUserIdChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(userId: event.userId, clearError: true));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(password: event.password, clearError: true));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(
        errorMessage: 'Please fill in all fields',
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final response = await _apiService.login(
        email: state.userId, // Using userId field to store email
        password: state.password,
      );

      // Always save login data (token) on every login
      await SharedPreferencesManager.saveLoginData(response);
      // Save token separately for easy access
      if (response['token'] != null) {
        await SharedPreferencesManager.saveToken(response['token']);
      }

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        loginData: response,
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
    LoginReset event,
    Emitter<LoginState> emit,
  ) {
    emit(const LoginState());
  }
}

