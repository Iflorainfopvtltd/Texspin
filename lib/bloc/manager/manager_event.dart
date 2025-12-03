part of 'manager_bloc.dart';

abstract class ManagerEvent {}

class LoadManagerProjects extends ManagerEvent {
  final String staffId;

  LoadManagerProjects(this.staffId);
}

class RefreshManagerProjects extends ManagerEvent {
  final String staffId;

  RefreshManagerProjects(this.staffId);
}
