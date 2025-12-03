import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/project_converter.dart';

part 'worker_event.dart';
part 'worker_state.dart';

class WorkerBloc extends Bloc<WorkerEvent, WorkerState> {
  final ApiService _apiService;

  WorkerBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const WorkerInitial()) {
    on<LoadWorkerProjects>(_onLoadWorkerProjects);
    on<RefreshWorkerProjects>(_onRefreshWorkerProjects);
    on<UpdateWorkerFcmToken>(_onUpdateWorkerFcmToken);
  }

  Future<void> _onLoadWorkerProjects(
    LoadWorkerProjects event,
    Emitter<WorkerState> emit,
  ) async {
    emit(const WorkerLoading());
    try {
      final response = await _apiService.getProjectsByTeamLeader(event.staffId);
      final projects = ProjectConverter.fromApiResponse(response);
      final total = response['total'] as int? ?? projects.length;

      emit(WorkerLoaded(projects: projects, total: total));
    } catch (e) {
      developer.log(
        'Error loading worker projects: $e',
        name: 'WorkerBloc',
      );
      emit(WorkerError(e.toString()));
    }
  }

  Future<void> _onRefreshWorkerProjects(
    RefreshWorkerProjects event,
    Emitter<WorkerState> emit,
  ) async {
    try {
      final response = await _apiService.getProjectsByTeamLeader(event.staffId);
      final projects = ProjectConverter.fromApiResponse(response);
      final total = response['total'] as int? ?? projects.length;

      emit(WorkerLoaded(projects: projects, total: total));
    } catch (e) {
      developer.log(
        'Error refreshing worker projects: $e',
        name: 'WorkerBloc',
      );
      emit(WorkerError(e.toString()));
    }
  }

  Future<void> _onUpdateWorkerFcmToken(
    UpdateWorkerFcmToken event,
    Emitter<WorkerState> emit,
  ) async {
    try {
      await _apiService.updateWorkerFcmToken(event.fcmToken);
      emit(const WorkerFcmTokenUpdated());
    } catch (e) {
      developer.log(
        'Error updating worker FCM token: $e',
        name: 'WorkerBloc',
      );
      emit(WorkerFcmTokenError(e.toString()));
    }
  }
}
