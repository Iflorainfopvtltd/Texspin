import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'entity_event.dart';
import 'entity_state.dart';
import '../../models/models.dart';
import '../../models/additional_entities.dart';

class EntityBloc extends Bloc<EntityEvent, EntityState> {
  final ApiService _apiService;

  EntityBloc({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      super(const EntityState()) {
    // Load events
    on<LoadDesignations>(_onLoadDesignations);
    on<LoadZones>(_onLoadZones);
    on<LoadDepartments>(_onLoadDepartments);
    on<LoadPhases>(_onLoadPhases);
    on<LoadStaff>(_onLoadStaff);
    on<LoadActivities>(_onLoadActivities);
    on<LoadTemplates>(_onLoadTemplates);
    on<LoadWorkCategories>(_onLoadWorkCategories);

    // Create events
    on<CreateDesignation>(_onCreateDesignation);
    on<CreateZone>(_onCreateZone);
    on<CreateDepartment>(_onCreateDepartment);
    on<CreatePhase>(_onCreatePhase);
    on<CreateStaff>(_onCreateStaff);
    on<CreateActivityEntity>(_onCreateActivity);
    on<CreateTemplate>(_onCreateTemplate);
    on<CreateWorkCategory>(_onCreateWorkCategory);

    // Update events
    on<UpdateDesignation>(_onUpdateDesignation);
    on<UpdateZone>(_onUpdateZone);
    on<UpdateDepartment>(_onUpdateDepartment);
    on<UpdatePhase>(_onUpdatePhase);
    on<UpdateStaff>(_onUpdateStaff);
    on<UpdateActivityEntity>(_onUpdateActivity);
    on<UpdateTemplate>(_onUpdateTemplate);
    on<UpdateWorkCategory>(_onUpdateWorkCategory);

    // Delete events
    on<DeleteDesignation>(_onDeleteDesignation);
    on<DeleteZone>(_onDeleteZone);
    on<DeleteDepartment>(_onDeleteDepartment);
    on<DeletePhase>(_onDeletePhase);
    on<DeleteStaff>(_onDeleteStaff);
    on<DeleteActivityEntity>(_onDeleteActivity);
    on<DeleteTemplate>(_onDeleteTemplate);
    on<DeleteWorkCategory>(_onDeleteWorkCategory);

    // Update status events
    on<UpdateDesignationStatus>(_onUpdateDesignationStatus);
    on<UpdateZoneStatus>(_onUpdateZoneStatus);
    on<UpdateDepartmentStatus>(_onUpdateDepartmentStatus);
    on<UpdatePhaseStatus>(_onUpdatePhaseStatus);
    on<UpdateStaffStatus>(_onUpdateStaffStatus);
    on<UpdateActivityStatus>(_onUpdateActivityStatus);
    on<UpdateTemplateStatus>(_onUpdateTemplateStatus);
    on<UpdateWorkCategoryStatus>(_onUpdateWorkCategoryStatus);

    // Misc
    on<ChangeStaffPassword>(_onChangeStaffPassword);
  }

  // Load handlers
  Future<void> _onLoadDesignations(
    LoadDesignations event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getDesignations();
      List<dynamic> data = [];
      // Handle different response formats
      if (response['designations'] != null) {
        if (response['designations'] is List) {
          data = response['designations'] as List<dynamic>;
        } else {
          data = [response['designations']];
        }
      } else if (response['data'] != null) {
        if (response['data'] is List) {
          data = response['data'] as List<dynamic>;
        } else {
          data = [response['data']];
        }
      }
      final designations = data
          .map((json) => Designation.fromJson(json))
          .toList();
      emit(state.copyWith(designations: designations, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoadZones(LoadZones event, Emitter<EntityState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getZones();
      List<dynamic> data = [];
      // Handle different response formats
      if (response['zones'] != null) {
        if (response['zones'] is List) {
          data = response['zones'] as List<dynamic>;
        } else {
          data = [response['zones']];
        }
      } else if (response['data'] != null) {
        if (response['data'] is List) {
          data = response['data'] as List<dynamic>;
        } else {
          data = [response['data']];
        }
      }
      final zones = data.map((json) => Zone.fromJson(json)).toList();
      emit(state.copyWith(zones: zones, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoadDepartments(
    LoadDepartments event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getDepartments();
      List<dynamic> data = [];
      // Handle different response formats
      if (response['departments'] != null) {
        if (response['departments'] is List) {
          data = response['departments'] as List<dynamic>;
        } else {
          data = [response['departments']];
        }
      } else if (response['data'] != null) {
        if (response['data'] is List) {
          data = response['data'] as List<dynamic>;
        } else {
          data = [response['data']];
        }
      }
      final departments = data
          .map((json) => Department.fromJson(json))
          .toList();
      emit(state.copyWith(departments: departments, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoadPhases(
    LoadPhases event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getPhaseEntities();
      List<dynamic> data = [];
      // Handle different response formats
      if (response['phases'] != null) {
        if (response['phases'] is List) {
          data = response['phases'] as List<dynamic>;
        } else {
          data = [response['phases']];
        }
      } else if (response['data'] != null) {
        if (response['data'] is List) {
          data = response['data'] as List<dynamic>;
        } else {
          data = [response['data']];
        }
      }
      final phases = data.map((json) => PhaseEntity.fromJson(json)).toList();
      emit(state.copyWith(phases: phases, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  // Create handlers
  Future<void> _onCreateDesignation(
    CreateDesignation event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createDesignation(
        name: event.name,
        status: event.status,
      );
      if (response['message'] != null || response['designation'] != null) {
        emit(state.copyWith(isCreating: false, clearError: true));
        // Reload designations directly
        await _onLoadDesignations(const LoadDesignations(), emit);
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            errorMessage: 'Failed to create designation',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreateZone(
    CreateZone event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createZone(
        name: event.name,
        status: event.status,
      );
      if (response['message'] != null || response['zone'] != null) {
        emit(state.copyWith(isCreating: false, clearError: true));
        // Reload zones directly
        await _onLoadZones(const LoadZones(), emit);
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            errorMessage: 'Failed to create zone',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreateDepartment(
    CreateDepartment event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createDepartment(
        name: event.name,
        status: event.status,
      );
      if (response['message'] != null || response['department'] != null) {
        emit(state.copyWith(isCreating: false, clearError: true));
        // Reload departments directly
        await _onLoadDepartments(const LoadDepartments(), emit);
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            errorMessage: 'Failed to create department',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreatePhase(
    CreatePhase event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createPhaseEntity(
        name: event.name,
        status: event.status,
      );
      if (response['message'] != null || response['phase'] != null) {
        emit(state.copyWith(isCreating: false, clearError: true));
        // Reload phases directly
        await _onLoadPhases(const LoadPhases(), emit);
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            errorMessage: 'Failed to create phase',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  // Update handlers
  Future<void> _onUpdateDesignation(
    UpdateDesignation event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateDesignation(id: event.id, status: event.status);
      final updatedDesignations = state.designations.map((d) {
        if (d.id == event.id) {
          return Designation(
            id: d.id,
            name: d.name,
            status: event.status,
            createdBy: d.createdBy,
            createdAt: d.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        return d;
      }).toList();
      emit(
        state.copyWith(designations: updatedDesignations, isUpdating: false),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateZone(
    UpdateZone event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateZone(id: event.id, status: event.status);
      final updatedZones = state.zones.map((z) {
        if (z.id == event.id) {
          return Zone(
            id: z.id,
            name: z.name,
            status: event.status,
            createdBy: z.createdBy,
            createdAt: z.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        return z;
      }).toList();
      emit(state.copyWith(zones: updatedZones, isUpdating: false));
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateDepartment(
    UpdateDepartment event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateDepartment(id: event.id, status: event.status);
      final updatedDepartments = state.departments.map((d) {
        if (d.id == event.id) {
          return Department(
            id: d.id,
            name: d.name,
            status: event.status,
            createdBy: d.createdBy,
            createdAt: d.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        return d;
      }).toList();
      emit(state.copyWith(departments: updatedDepartments, isUpdating: false));
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdatePhase(
    UpdatePhase event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updatePhaseEntity(id: event.id, status: event.status);
      final updatedPhases = state.phases.map((p) {
        if (p.id == event.id) {
          return PhaseEntity(
            id: p.id,
            name: p.name,
            status: event.status,
            createdBy: p.createdBy,
            createdAt: p.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        return p;
      }).toList();
      emit(state.copyWith(phases: updatedPhases, isUpdating: false));
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  // Delete handlers
  Future<void> _onDeleteDesignation(
    DeleteDesignation event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deleteDesignation(id: event.id);
      emit(state.copyWith(isDeleting: false, clearError: true));
      // Reload designations directly
      await _onLoadDesignations(const LoadDesignations(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteZone(
    DeleteZone event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deleteZone(id: event.id);
      emit(state.copyWith(isDeleting: false, clearError: true));
      // Reload zones directly
      await _onLoadZones(const LoadZones(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteDepartment(
    DeleteDepartment event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deleteDepartment(id: event.id);
      emit(state.copyWith(isDeleting: false, clearError: true));
      // Reload departments directly
      await _onLoadDepartments(const LoadDepartments(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeletePhase(
    DeletePhase event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deletePhaseEntity(id: event.id);
      emit(state.copyWith(isDeleting: false, clearError: true));
      // Reload phases directly
      await _onLoadPhases(const LoadPhases(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  // Update status handlers
  Future<void> _onUpdateDesignationStatus(
    UpdateDesignationStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateDesignationStatus(
        id: event.id,
        status: event.status,
      );
      emit(state.copyWith(isUpdating: false, clearError: true));
      // Reload designations directly
      await _onLoadDesignations(const LoadDesignations(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateZoneStatus(
    UpdateZoneStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateZoneStatus(id: event.id, status: event.status);
      emit(state.copyWith(isUpdating: false, clearError: true));
      // Reload zones directly
      await _onLoadZones(const LoadZones(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateDepartmentStatus(
    UpdateDepartmentStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateDepartmentStatus(
        id: event.id,
        status: event.status,
      );
      emit(state.copyWith(isUpdating: false, clearError: true));
      // Reload departments directly
      await _onLoadDepartments(const LoadDepartments(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdatePhaseStatus(
    UpdatePhaseStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updatePhaseEntityStatus(
        id: event.id,
        status: event.status,
      );
      emit(state.copyWith(isUpdating: false, clearError: true));
      // Reload phases directly
      await _onLoadPhases(const LoadPhases(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  // Staff and Activity handlers
  Future<void> _onLoadStaff(LoadStaff event, Emitter<EntityState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getStaff();
      List<dynamic> data = [];
      if (response['staff'] != null) {
        data = response['staff'] is List
            ? response['staff']
            : [response['staff']];
      } else if (response['data'] != null) {
        data = response['data'] is List ? response['data'] : [response['data']];
      }
      final staff = data.map((json) => StaffEntity.fromJson(json)).toList();
      emit(state.copyWith(staff: staff, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getActivities();
      List<dynamic> data = [];
      if (response['activities'] != null) {
        data = response['activities'] is List
            ? response['activities']
            : [response['activities']];
      } else if (response['data'] != null) {
        data = response['data'] is List ? response['data'] : [response['data']];
      }
      final activities = data.map((j) => ActivityEntity.fromJson(j)).toList();
      emit(state.copyWith(activities: activities, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoadTemplates(
    LoadTemplates event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getTemplates();
      List<dynamic> data = [];
      if (response['templates'] != null) {
        data = response['templates'] is List
            ? response['templates']
            : [response['templates']];
      } else if (response['data'] != null) {
        data = response['data'] is List ? response['data'] : [response['data']];
      }
      final templates = data.map((j) => TemplateEntity.fromJson(j)).toList();
      emit(state.copyWith(templates: templates, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreateStaff(
    CreateStaff event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createStaff(
        staffData: event.staffData,
      );
      if (response['message'] != null || response['staff'] != null) {
        emit(state.copyWith(isCreating: false, clearError: true));
        await _onLoadStaff(const LoadStaff(), emit);
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            errorMessage: 'Failed to create staff',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreateActivity(
    CreateActivityEntity event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createActivity(
        name: event.name,
        status: event.status,
      );
      if (response['message'] != null || response['activity'] != null) {
        emit(state.copyWith(isCreating: false, clearError: true));
        await _onLoadActivities(const LoadActivities(), emit);
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            errorMessage: 'Failed to create activity',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreateTemplate(
    CreateTemplate event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createTemplate(
        data: event.templateData,
      );
      if (response['message'] != null || response['template'] != null) {
        emit(state.copyWith(isCreating: false, clearError: true));
        await _onLoadTemplates(const LoadTemplates(), emit);
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            errorMessage: 'Failed to create template',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateStaff(
    UpdateStaff event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateStaff(id: event.id, staffData: event.staffData);
      emit(state.copyWith(isUpdating: false, clearError: true));
      await _onLoadStaff(const LoadStaff(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateActivity(
    UpdateActivityEntity event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateActivity(id: event.id, data: event.data);
      emit(state.copyWith(isUpdating: false, clearError: true));
      await _onLoadActivities(const LoadActivities(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateTemplate(
    UpdateTemplate event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateTemplate(id: event.id, data: event.templateData);
      emit(state.copyWith(isUpdating: false, clearError: true));
      await _onLoadTemplates(const LoadTemplates(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteStaff(
    DeleteStaff event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deleteStaff(id: event.id);
      emit(state.copyWith(isDeleting: false, clearError: true));
      await _onLoadStaff(const LoadStaff(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteActivity(
    DeleteActivityEntity event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deleteActivity(id: event.id);
      emit(state.copyWith(isDeleting: false, clearError: true));
      await _onLoadActivities(const LoadActivities(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteTemplate(
    DeleteTemplate event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deleteTemplate(id: event.id);
      emit(state.copyWith(isDeleting: false, clearError: true));
      await _onLoadTemplates(const LoadTemplates(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateStaffStatus(
    UpdateStaffStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateStaffStatus(id: event.id, status: event.status);
      emit(state.copyWith(isUpdating: false, clearError: true));
      await _onLoadStaff(const LoadStaff(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateActivityStatus(
    UpdateActivityStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateActivityStatus(
        id: event.id,
        status: event.status,
      );
      emit(state.copyWith(isUpdating: false, clearError: true));
      await _onLoadActivities(const LoadActivities(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateTemplateStatus(
    UpdateTemplateStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _apiService.updateTemplateStatus(
        id: event.id,
        status: event.status,
      );
      emit(state.copyWith(isUpdating: false, clearError: true));
      await _onLoadTemplates(const LoadTemplates(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onChangeStaffPassword(
    ChangeStaffPassword event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      final resp = await _apiService.changeStaffPassword(
        staffId: event.staffId,
        email: event.email,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );
      emit(
        state.copyWith(
          errorMessage:
              (resp is Map<String, dynamic> && resp['message'] is String)
              ? resp['message'] as String
              : 'Staff password changed successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  // Work Category handlers
  Future<void> _onLoadWorkCategories(
    LoadWorkCategories event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiService.getWorkCategories();
      List<dynamic> data = [];
      if (response['workCategories'] != null) {
        if (response['workCategories'] is List) {
          data = response['workCategories'] as List<dynamic>;
        } else {
          data = [response['workCategories']];
        }
      } else if (response['data'] != null) {
        if (response['data'] is List) {
          data = response['data'] as List<dynamic>;
        } else {
          data = [response['data']];
        }
      }
      final workCategories = data
          .map((json) => WorkCategory.fromJson(json))
          .toList();
      emit(state.copyWith(workCategories: workCategories, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreateWorkCategory(
    CreateWorkCategory event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));
    try {
      final response = await _apiService.createWorkCategory(
        name: event.name,
        status: event.status,
      );
      final newCategory = WorkCategory.fromJson(
        response['workCategory'] ?? response['data'] ?? response,
      );
      emit(
        state.copyWith(
          workCategories: [...state.workCategories, newCategory],
          isCreating: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateWorkCategory(
    UpdateWorkCategory event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      final category = state.workCategories.firstWhere((c) => c.id == event.id);
      final response = await _apiService.updateWorkCategory(
        id: event.id,
        name: category.name,
        status: event.status,
      );
      final updatedCategory = WorkCategory.fromJson(
        response['workCategory'] ?? response['data'] ?? response,
      );
      final updatedList = state.workCategories.map((c) {
        return c.id == event.id ? updatedCategory : c;
      }).toList();
      emit(
        state.copyWith(
          workCategories: updatedList,
          isUpdating: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteWorkCategory(
    DeleteWorkCategory event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _apiService.deleteWorkCategory(id: event.id);
      final updatedList = state.workCategories
          .where((c) => c.id != event.id)
          .toList();
      emit(
        state.copyWith(
          workCategories: updatedList,
          isDeleting: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateWorkCategoryStatus(
    UpdateWorkCategoryStatus event,
    Emitter<EntityState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      final response = await _apiService.updateWorkCategoryStatus(
        id: event.id,
        status: event.status,
      );
      final updatedCategory = WorkCategory.fromJson(
        response['workCategory'] ?? response['data'] ?? response,
      );
      final updatedList = state.workCategories.map((c) {
        return c.id == event.id ? updatedCategory : c;
      }).toList();
      emit(
        state.copyWith(
          workCategories: updatedList,
          isUpdating: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
  