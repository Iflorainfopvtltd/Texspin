import 'package:equatable/equatable.dart';

abstract class EntityEvent extends Equatable {
  const EntityEvent();

  @override
  List<Object?> get props => [];
}

// Load events
class LoadDesignations extends EntityEvent {
  const LoadDesignations();
}

class LoadZones extends EntityEvent {
  const LoadZones();
}

class LoadDepartments extends EntityEvent {
  const LoadDepartments();
}

class LoadPhases extends EntityEvent {
  const LoadPhases();
}

class LoadStaff extends EntityEvent {
  const LoadStaff();
}

class LoadActivities extends EntityEvent {
  const LoadActivities();
}

class LoadTemplates extends EntityEvent {
  const LoadTemplates();
}

// Create events
class CreateDesignation extends EntityEvent {
  final String name;
  final String status;

  const CreateDesignation({required this.name, required this.status});

  @override
  List<Object> get props => [name, status];
}

class CreateZone extends EntityEvent {
  final String name;
  final String status;

  const CreateZone({required this.name, required this.status});

  @override
  List<Object> get props => [name, status];
}

class CreateDepartment extends EntityEvent {
  final String name;
  final String status;

  const CreateDepartment({required this.name, required this.status});

  @override
  List<Object> get props => [name, status];
}

class CreatePhase extends EntityEvent {
  final String name;
  final String status;

  const CreatePhase({required this.name, required this.status});

  @override
  List<Object> get props => [name, status];
}

class CreateStaff extends EntityEvent {
  final Map<String, dynamic> staffData;

  const CreateStaff({required this.staffData});

  @override
  List<Object> get props => [staffData];
}

class CreateActivityEntity extends EntityEvent {
  final String name;
  final String status;

  const CreateActivityEntity({required this.name, required this.status});

  @override
  List<Object> get props => [name, status];
}

class CreateTemplate extends EntityEvent {
  final Map<String, dynamic> templateData;

  const CreateTemplate({required this.templateData});

  @override
  List<Object> get props => [templateData];
}

// Update events
class UpdateDesignation extends EntityEvent {
  final String id;
  final String status;

  const UpdateDesignation({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateZone extends EntityEvent {
  final String id;
  final String status;

  const UpdateZone({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateDepartment extends EntityEvent {
  final String id;
  final String status;

  const UpdateDepartment({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdatePhase extends EntityEvent {
  final String id;
  final String status;

  const UpdatePhase({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateStaff extends EntityEvent {
  final String id;
  final Map<String, dynamic> staffData;

  const UpdateStaff({required this.id, required this.staffData});

  @override
  List<Object> get props => [id, staffData];
}

class UpdateActivityEntity extends EntityEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateActivityEntity({required this.id, required this.data});

  @override
  List<Object> get props => [id, data];
}

class UpdateTemplate extends EntityEvent {
  final String id;
  final Map<String, dynamic> templateData;

  const UpdateTemplate({required this.id, required this.templateData});

  @override
  List<Object> get props => [id, templateData];
}

// Delete events
class DeleteDesignation extends EntityEvent {
  final String id;

  const DeleteDesignation({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteZone extends EntityEvent {
  final String id;

  const DeleteZone({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteDepartment extends EntityEvent {
  final String id;

  const DeleteDepartment({required this.id});

  @override
  List<Object> get props => [id];
}

class DeletePhase extends EntityEvent {
  final String id;

  const DeletePhase({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteStaff extends EntityEvent {
  final String id;

  const DeleteStaff({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteActivityEntity extends EntityEvent {
  final String id;

  const DeleteActivityEntity({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteTemplate extends EntityEvent {
  final String id;

  const DeleteTemplate({required this.id});

  @override
  List<Object> get props => [id];
}

// Update status events
class UpdateDesignationStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdateDesignationStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateZoneStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdateZoneStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateDepartmentStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdateDepartmentStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdatePhaseStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdatePhaseStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateStaffStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdateStaffStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateActivityStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdateActivityStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class UpdateTemplateStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdateTemplateStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

// Staff change password
class ChangeStaffPassword extends EntityEvent {
  final String staffId;
  final String email;
  final String newPassword;
  final String confirmPassword;

  const ChangeStaffPassword({
    required this.staffId,
    required this.email,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [staffId, email, newPassword, confirmPassword];
}


// Work Category events
class LoadWorkCategories extends EntityEvent {
  const LoadWorkCategories();
}

class CreateWorkCategory extends EntityEvent {
  final String name;
  final String status;

  const CreateWorkCategory({required this.name, required this.status});

  @override
  List<Object> get props => [name, status];
}

class UpdateWorkCategory extends EntityEvent {
  final String id;
  final String status;

  const UpdateWorkCategory({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class DeleteWorkCategory extends EntityEvent {
  final String id;

  const DeleteWorkCategory({required this.id});

  @override
  List<Object> get props => [id];
}

class UpdateWorkCategoryStatus extends EntityEvent {
  final String id;
  final String status;

  const UpdateWorkCategoryStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}
