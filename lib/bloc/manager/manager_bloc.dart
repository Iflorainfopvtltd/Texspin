import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/project_converter.dart';

part 'manager_event.dart';
part 'manager_state.dart';

class ManagerBloc extends Bloc<ManagerEvent, ManagerState> {
  final ApiService _apiService;

  ManagerBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(ManagerInitial()) {
    on<LoadManagerProjects>(_onLoadManagerProjects);
    on<RefreshManagerProjects>(_onRefreshManagerProjects);
  }

  Future<void> _onLoadManagerProjects(
    LoadManagerProjects event,
    Emitter<ManagerState> emit,
  ) async {
    emit(ManagerLoading());
    try {
      final response = await _apiService.getProjectsByTeamLeader(event.staffId);
      final projects = ProjectConverter.fromApiResponse(response);
      final total = response['total'] as int? ?? projects.length;

      emit(ManagerLoaded(projects: projects, total: total));
    } catch (e) {
      developer.log(
        'Error loading manager projects: $e',
        name: 'ManagerBloc',
      );
      emit(ManagerError(e.toString()));
    }
  }

  Future<void> _onRefreshManagerProjects(
    RefreshManagerProjects event,
    Emitter<ManagerState> emit,
  ) async {
    try {
      final response = await _apiService.getProjectsByTeamLeader(event.staffId);
      final projects = ProjectConverter.fromApiResponse(response);
      final total = response['total'] as int? ?? projects.length;

      emit(ManagerLoaded(projects: projects, total: total));
    } catch (e) {
      developer.log(
        'Error refreshing manager projects: $e',
        name: 'ManagerBloc',
      );
      emit(ManagerError(e.toString()));
    }
  }
}
