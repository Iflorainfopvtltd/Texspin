import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final ApiService _apiService;

  RegistrationBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const RegistrationState()) {
    on<RegistrationNameChanged>(_onNameChanged);
    on<RegistrationIdChanged>(_onIdChanged);
    on<RegistrationPasswordChanged>(_onPasswordChanged);
    on<RegistrationSubmitted>(_onSubmitted);
    on<RegistrationReset>(_onReset);
  }

  void _onNameChanged(
    RegistrationNameChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(name: event.name, clearError: true));
  }

  void _onIdChanged(
    RegistrationIdChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(id: event.id, clearError: true));
  }

  void _onPasswordChanged(
    RegistrationPasswordChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(password: event.password, clearError: true));
  }

  Future<void> _onSubmitted(
    RegistrationSubmitted event,
    Emitter<RegistrationState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(
        errorMessage: 'Please fill in all fields',
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final response = await _apiService.register(
        email: state.id, // Using id field to store email
        password: state.password,
        fullName: state.name,
        role: 'admin', // Default role as per API
      );

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        userData: response['user'],
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
    RegistrationReset event,
    Emitter<RegistrationState> emit,
  ) {
    emit(const RegistrationState());
  }
}

