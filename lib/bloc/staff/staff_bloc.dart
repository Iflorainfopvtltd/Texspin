import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/project_converter.dart';

part 'staff_event.dart';
part 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final ApiService _apiService;

  StaffBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const StaffInitial()) {
    on<LoadStaffProjects>(_onLoadStaffProjects);
    on<RefreshStaffProjects>(_onRefreshStaffProjects);
    on<UpdateStaffFcmToken>(_onUpdateStaffFcmToken);
  }

  Future<void> _onLoadStaffProjects(
    LoadStaffProjects event,
    Emitter<StaffState> emit,
  ) async {
    emit(const StaffLoading());
    try {
      final response = await _apiService.getProjectsByTeamLeader(event.staffId);
      final projects = ProjectConverter.fromApiResponse(response);
      final total = response['total'] as int? ?? projects.length;

      emit(StaffLoaded(projects: projects, total: total));
    } catch (e) {
      developer.log(
        'Error loading staff projects: $e',
        name: 'StaffBloc',
      );
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onRefreshStaffProjects(
    RefreshStaffProjects event,
    Emitter<StaffState> emit,
  ) async {
    try {
      final response = await _apiService.getProjectsByTeamLeader(event.staffId);
      final projects = ProjectConverter.fromApiResponse(response);
      final total = response['total'] as int? ?? projects.length;

      emit(StaffLoaded(projects: projects, total: total));
    } catch (e) {
      developer.log(
        'Error refreshing staff projects: $e',
        name: 'StaffBloc',
      );
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onUpdateStaffFcmToken(
    UpdateStaffFcmToken event,
    Emitter<StaffState> emit,
  ) async {
    try {
      await _apiService.updateStaffFcmToken(event.fcmToken);
      emit(const StaffFcmTokenUpdated());
    } catch (e) {
      developer.log(
        'Error updating staff FCM token: $e',
        name: 'StaffBloc',
      );
      emit(StaffFcmTokenError(e.toString()));
    }
  }
}
