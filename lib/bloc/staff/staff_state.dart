part of 'staff_bloc.dart';

abstract class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {
  const StaffInitial();
}

class StaffLoading extends StaffState {
  const StaffLoading();
}

class StaffLoaded extends StaffState {
  final List<Project> projects;
  final int total;

  const StaffLoaded({required this.projects, required this.total});

  @override
  List<Object?> get props => [projects, total];
}

class StaffError extends StaffState {
  final String message;

  const StaffError(this.message);

  @override
  List<Object?> get props => [message];
}

class StaffFcmTokenUpdated extends StaffState {
  const StaffFcmTokenUpdated();
}

class StaffFcmTokenError extends StaffState {
  final String message;

  const StaffFcmTokenError(this.message);

  @override
  List<Object?> get props => [message];
}
