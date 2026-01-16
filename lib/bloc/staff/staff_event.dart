part of 'staff_bloc.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

class LoadStaffProjects extends StaffEvent {
  final String staffId;

  const LoadStaffProjects(this.staffId);

  @override
  List<Object?> get props => [staffId];
}

class RefreshStaffProjects extends StaffEvent {
  final String staffId;

  const RefreshStaffProjects(this.staffId);

  @override
  List<Object?> get props => [staffId];
}

class UpdateStaffFcmToken extends StaffEvent {
  final String fcmToken;

  const UpdateStaffFcmToken(this.fcmToken);

  @override
  List<Object?> get props => [fcmToken];
}
