part of 'worker_bloc.dart';

abstract class WorkerState extends Equatable {
  const WorkerState();

  @override
  List<Object?> get props => [];
}

class WorkerInitial extends WorkerState {
  const WorkerInitial();
}

class WorkerLoading extends WorkerState {
  const WorkerLoading();
}

class WorkerLoaded extends WorkerState {
  final List<Project> projects;
  final int total;

  const WorkerLoaded({required this.projects, required this.total});

  @override
  List<Object?> get props => [projects, total];
}

class WorkerError extends WorkerState {
  final String message;

  const WorkerError(this.message);

  @override
  List<Object?> get props => [message];
}

class WorkerFcmTokenUpdated extends WorkerState {
  const WorkerFcmTokenUpdated();
}

class WorkerFcmTokenError extends WorkerState {
  final String message;

  const WorkerFcmTokenError(this.message);

  @override
  List<Object?> get props => [message];
}
