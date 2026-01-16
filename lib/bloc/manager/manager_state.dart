part of 'manager_bloc.dart';

abstract class ManagerState {}

class ManagerInitial extends ManagerState {}

class ManagerLoading extends ManagerState {}

class ManagerLoaded extends ManagerState {
  final List<Project> projects;
  final int total;

  ManagerLoaded({required this.projects, required this.total});
}

class ManagerError extends ManagerState {
  final String message;

  ManagerError(this.message);
}
