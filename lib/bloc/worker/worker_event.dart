part of 'worker_bloc.dart';

abstract class WorkerEvent extends Equatable {
  const WorkerEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkerProjects extends WorkerEvent {
  final String staffId;

  const LoadWorkerProjects(this.staffId);

  @override
  List<Object?> get props => [staffId];
}

class RefreshWorkerProjects extends WorkerEvent {
  final String staffId;

  const RefreshWorkerProjects(this.staffId);

  @override
  List<Object?> get props => [staffId];
}

class UpdateWorkerFcmToken extends WorkerEvent {
  final String fcmToken;

  const UpdateWorkerFcmToken(this.fcmToken);

  @override
  List<Object?> get props => [fcmToken];
}
