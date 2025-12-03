import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../models/additional_entities.dart';
import '../../models/models.dart' show WorkCategory;

class EntityState extends Equatable {
  final List<Designation> designations;
  final List<Zone> zones;
  final List<Department> departments;
  final List<PhaseEntity> phases;
  final List<StaffEntity> staff;
  final List<ActivityEntity> activities;
  final List<TemplateEntity> templates;
  final List<WorkCategory> workCategories;
  final bool isLoading;
  final String? errorMessage;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;

  const EntityState({
    this.designations = const [],
    this.zones = const [],
    this.departments = const [],
    this.phases = const [],
    this.staff = const [],
    this.activities = const [],
    this.templates = const [],
    this.workCategories = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
  });

  EntityState copyWith({
    List<Designation>? designations,
    List<Zone>? zones,
    List<Department>? departments,
    List<PhaseEntity>? phases,
    List<StaffEntity>? staff,
    List<ActivityEntity>? activities,
    List<TemplateEntity>? templates,
    List<WorkCategory>? workCategories,
    bool? isLoading,
    String? errorMessage,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool clearError = false,
  }) {
    return EntityState(
      designations: designations ?? this.designations,
      zones: zones ?? this.zones,
      departments: departments ?? this.departments,
      phases: phases ?? this.phases,
      staff: staff ?? this.staff,
      activities: activities ?? this.activities,
      templates: templates ?? this.templates,
      workCategories: workCategories ?? this.workCategories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  @override
  List<Object?> get props => [
        designations,
        zones,
        departments,
        phases,
        staff,
        activities,
        templates,
        workCategories,
        isLoading,
        errorMessage,
        isCreating,
        isUpdating,
        isDeleting,
      ];
}

