import 'package:Texspin/screens/create_project_screen.dart';
import 'package:Texspin/screens/edit_project_screen.dart';
import 'package:Texspin/screens/project_view_screen.dart';
import 'package:Texspin/screens/inquiry_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../models/models.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/manager_dashboard_screen.dart';
import '../screens/staff_dashboard_screen.dart';
import '../screens/worker_dashboard_screen.dart';
import '../bloc/registration/registration_bloc.dart';
import '../bloc/login/login_bloc.dart';
import '../bloc/forgot_password/forgot_password_bloc.dart';
import '../bloc/entity/entity_bloc.dart';
import '../bloc/manager/manager_bloc.dart';
import '../bloc/staff/staff_bloc.dart';
import '../bloc/worker/worker_bloc.dart';
import '../utils/shared_preferences_manager.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/project_converter.dart';

class App extends StatefulWidget {
  const App({super.key});

  static void Function()? onGlobalLogout;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  View _currentView = View.login;
  User? _user;
  List<Project> _projects = [];
  String? _selectedProjectId;
  Project? _selectedProject;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    // Auto-login if token exists
    final loginData = await SharedPreferencesManager.getLoginData();
    // Check if login data exists and has a token
    if (loginData != null &&
        loginData['token'] != null &&
        loginData['token'].toString().isNotEmpty &&
        mounted) {
      _handleLogin(loginData);
    }
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  int _calculateProgress(Project project) {
    final totalActivities = project.phases.fold<int>(
      0,
      (sum, phase) => sum + phase.activities.length,
    );
    final completedActivities = project.phases.fold<int>(
      0,
      (sum, phase) =>
          sum +
          phase.activities
              .where((a) => a.status == ActivityStatus.completed)
              .length,
    );

    if (totalActivities == 0) return 0;
    return ((completedActivities / totalActivities) * 100).round();
  }

  void _handleLogin(Map<String, dynamic> loginData) async {
    final role = loginData['role'] ?? 'admin';

    // Save staff ID and role to SharedPreferences for manager/staff/worker
    if (role == 'manager' || role == 'staff' || role == 'worker') {
      final staffId = loginData['staff']?['id'] ?? loginData['staff']?['_id'];
      if (staffId != null) {
        await SharedPreferencesManager.saveStaffId(staffId);
        developer.log('Saved staff ID: $staffId', name: 'App');
      }
      await SharedPreferencesManager.saveUserRole(role);
    }

    final newUser = User(
      id: role == 'admin'
          ? (loginData['admin']?['id'] ?? loginData['adminId'] ?? '1')
          : (loginData['staff']?['_id'] ??
                loginData['staff']?['id'] ??
                loginData['staff']?['staffId'] ??
                '1'),
      email: role == 'admin'
          ? (loginData['admin']?['email'] ?? loginData['email'] ?? '')
          : (loginData['staff']?['email'] ?? ''),
      name: role == 'admin'
          ? (loginData['admin']?['fullName'] ?? loginData['fullName'] ?? '')
          : ('${loginData['staff']?['firstName'] ?? ''} ${loginData['staff']?['lastName'] ?? ''}'
                .trim()),
      role: role,
    );
    setState(() {
      _user = newUser;
      // _projects = demoProjects;
      // Redirect based on role
      if (role == 'staff') {
        _currentView = View.staffDashboard;
      } else if (role == 'worker') {
        _currentView = View.workerDashboard;
      } else if (role == 'manager') {
        _currentView = View.managerDashboard;
      } else {
        _currentView = View.dashboard;
      }
    });

    // Get and update FCM token after successful login
    _handleFcmTokenAfterLogin();
  }

  Future<void> _handleFcmTokenAfterLogin() async {
    try {
      // Get FCM token from Firebase after login
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Store it for future use
        await SharedPreferencesManager.saveFcmToken(fcmToken);
        developer.log('FCM Token obtained: $fcmToken', name: 'App');

        // Send to backend based on user role
        final api = ApiService();
        final userRole = await SharedPreferencesManager.getUserRole();

        if (userRole == 'staff') {
          await api.updateStaffFcmToken(fcmToken);
          developer.log('Staff FCM token sent to backend', name: 'App');
        } else if (userRole == 'manager') {
          await api.updateManagerFcmToken(fcmToken);
          developer.log('Manager FCM token sent to backend', name: 'App');
        } else if (userRole == 'worker') {
          await api.updateWorkerFcmToken(fcmToken);
          developer.log('Worker FCM token sent to backend', name: 'App');
        } else {
          await api.updateFcmToken(fcmToken);
          developer.log('Admin FCM token sent to backend', name: 'App');
        }
      }
    } catch (e) {
      developer.log('Error handling FCM token after login: $e', name: 'App');
    }
  }

  void _handleLogout() async {
    await SharedPreferencesManager.clearAll();
    setState(() {
      _user = null;
      _projects = [];
      _selectedProjectId = null;
      _selectedProject = null;
      _currentView = View.login;
    });
  }

  void _handleCreateProject(Project project) {
    final newProject = project.copyWith(
      id: 'project-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now().toIso8601String(),
      progress: _calculateProgress(project),
    );
    setState(() {
      _projects = [..._projects, newProject];
      _currentView = View.dashboard;
    });
  }

  void _handleEditProject(Project project) {
    setState(() {
      _projects = _projects.map((p) {
        if (p.id != _selectedProjectId) return p;
        final updated = project.copyWith(
          id: p.id,
          createdAt: p.createdAt,
          progress: _calculateProgress(project),
        );
        // Also update _selectedProject if it's the one being edited
        if (_selectedProject?.id == p.id) {
          _selectedProject = updated;
        }
        return updated;
      }).toList();
      _currentView = View.view;
    });
  }

  void _handleViewProject(Project project) {
    setState(() {
      _selectedProject = project;
      _selectedProjectId = project.id;
      _currentView = View.view;
    });
  }

  void _handleUpdateActivityStatus(
    String projectId,
    String phaseId,
    String activityId,
    ActivityStatus status,
  ) {
    setState(() {
      _projects = _projects.map((project) {
        if (project.id != projectId) return project;

        final updatedPhases = project.phases.map((phase) {
          if (phase.id != phaseId) return phase;

          final updatedActivities = phase.activities.map((activity) {
            if (activity.id != activityId) return activity;
            return activity.copyWith(status: status);
          }).toList();

          return phase.copyWith(activities: updatedActivities);
        }).toList();

        final updatedProject = project.copyWith(phases: updatedPhases);
        return updatedProject.copyWith(
          progress: _calculateProgress(updatedProject),
        );
      }).toList();
    });
  }

  Future<void> _handleDeleteProject(Project project) async {
    final apiService = ApiService();
    try {
      final response = await apiService.deleteProject(projectId: project.id);
      developer.log('Project deleted: $response', name: 'App');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response['message'] ?? 'Project deleted successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.green500,
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          _projects = _projects.where((p) => p.id != project.id).toList();
          _selectedProject = null;
          _selectedProjectId = null;
          // Return to appropriate dashboard based on user role
          if (_user?.role == 'manager') {
            _currentView = View.managerDashboard;
          } else if (_user?.role == 'staff') {
            _currentView = View.staffDashboard;
          } else if (_user?.role == 'worker') {
            _currentView = View.workerDashboard;
          } else if (_user?.role == 'admin') {
            _currentView = View.dashboard;
          }
        });
      }
    } catch (e) {
      developer.log('Error deleting project: $e', name: 'App');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error deleting project: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _refreshCurrentProject() async {
    if (_selectedProjectId == null) return;

    // Show loading indicator if needed, but for refresh usually we just update
    try {
      final apiService = ApiService();
      Map<String, dynamic> response;

      // Determine which API to use based on role
      if (_user?.role == 'manager') {
        // Managers might use getProjectsByTeamLeader, but usually getProjects returns filtered list for them if backend is set up that way?
        // Actually looking at ApiService, getProjects calls /texspin/api/apqpproject
        // getProjectsByTeamLeader calls /texspin/api/apqpproject/by-teamleader
        // Let's assume the user has rights to see the project they are viewing.
        // If they are a manager viewing a project, they likely got it from their list.
        // However, simply calling getProjects() is safe if backend returns what they can see.
        // Or we can try to find the specific project in the list if we re-fetch all.

        // For now, let's use getProjects as it seems generic enough or check if there is a specific one.
        // Given the complexity of different endpoints for list, maybe we should just look for the project in the list we get.

        // If user is manager, we might need to fetch by team leader to see their projects?
        // Let's check how DashboardScreen fetches projects.
        // DashboardScreen uses _apiService.getProjects().
        // ManagerDashboardScreen uses _apiService.getProjectsByTeamLeader.

        if (_user?.role == 'manager') {
          final staffId = await SharedPreferencesManager.getStaffId();
          if (staffId != null) {
            response = await apiService.getProjectsByTeamLeader(staffId);
          } else {
            // Fallback
            response = await apiService.getProjects();
          }
        } else if (_user?.role == 'staff') {
          // Staff sees projects they are part of? api_service doesn't show getProjectsByStaff
          // StaffDashboard doesn't seem to fetch projects in the main view code provided in earlier turns (it was just BlocProvider).
          // But let's assume getProjects works or returns all allowed projects.
          response = await apiService.getProjects();
        } else {
          response = await apiService.getProjects();
        }
      } else {
        response = await apiService.getProjects();
      }

      final projects = ProjectConverter.fromApiResponse(response);

      if (mounted) {
        setState(() {
          _projects = projects;
          // Update selected project from the fresh list
          try {
            _selectedProject = _projects.firstWhere(
              (p) => p.id == _selectedProjectId,
            );
          } catch (e) {
            // Project might have been deleted or lost access
            developer.log(
              'Project $_selectedProjectId not found in refreshed list',
            );
          }
        });
      }
    } catch (e) {
      developer.log('Error refreshing project: $e', name: 'App');
    }
  }

  @override
  Widget build(BuildContext context) {
    App.onGlobalLogout ??= _handleLogout;
    if (!_isInitialized) {
      // Show loading screen while checking saved login
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedProject =
        _selectedProject ??
        _projects.firstWhere(
          (p) => p.id == _selectedProjectId,
          orElse: () =>
              _projects.isNotEmpty ? _projects.first : _createEmptyProject(),
        );

    switch (_currentView) {
      case View.login:
        return BlocProvider(
          create: (context) => LoginBloc(),
          child: LoginScreen(
            onLoginSuccess: _handleLogin,
            onNavigateToRegister: () =>
                setState(() => _currentView = View.register),
            onNavigateToForgot: () =>
                setState(() => _currentView = View.forgot),
          ),
        );
      case View.register:
        return BlocProvider(
          create: (context) => RegistrationBloc(),
          child: RegisterScreen(
            onNavigateToLogin: () => setState(() => _currentView = View.login),
            onRegistrationSuccess: (userData) {
              setState(() {
                _currentView = View.login;
              });
            },
          ),
        );
      case View.forgot:
        return BlocProvider(
          create: (context) => ForgotPasswordBloc(),
          child: ForgotPasswordScreen(
            onNavigateToLogin: () => setState(() => _currentView = View.login),
          ),
        );
      case View.dashboard:
        return BlocProvider(
          create: (context) => EntityBloc(),
          child: DashboardScreen(
            projects: _projects,
            onCreateProject: () => setState(() => _currentView = View.create),
            onViewProject: _handleViewProject,
            onLogout: _handleLogout,
            userName: _user?.name,
            onRefresh: () {
              // Projects are fetched automatically in DashboardScreen
            },
            onInquiry: () => setState(() => _currentView = View.inquiry),
          ),
        );
      case View.staffDashboard:
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => StaffBloc()),
            BlocProvider(create: (context) => EntityBloc()),
          ],
          child: StaffDashboardScreen(
            onViewProject: _handleViewProject,
            onLogout: _handleLogout,
            userName: _user?.name,
          ),
        );
      case View.workerDashboard:
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => WorkerBloc()),
            BlocProvider(create: (context) => EntityBloc()),
          ],
          child: WorkerDashboardScreen(
            onViewProject: _handleViewProject,
            onLogout: _handleLogout,
            userName: _user?.name,
          ),
        );
      case View.managerDashboard:
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => ManagerBloc()),
            BlocProvider(create: (context) => EntityBloc()),
          ],
          child: ManagerDashboardScreen(
            onViewProject: _handleViewProject,
            onLogout: _handleLogout,
            userName: _user?.name,
            onInquiry: () => setState(() => _currentView = View.inquiry),
          ),
        );
      case View.create:
        return CreateProjectScreen(
          onSave: _handleCreateProject,
          onCancel: () => setState(() => _currentView = View.dashboard),
        );
      case View.edit:
        return EditProjectScreen(
          project: selectedProject,
          onSave: _handleEditProject,
          onCancel: () => setState(() => _currentView = View.view),
        );
      case View.view:
        return ProjectViewScreen(
          project: selectedProject,
          userRole: _user?.role,
          onRefresh: _refreshCurrentProject,
          onBack: () => setState(() {
            _selectedProject = null;
            _selectedProjectId = null;
            // Return to appropriate dashboard based on user role
            if (_user?.role == 'manager') {
              _currentView = View.managerDashboard;
            } else if (_user?.role == 'staff') {
              _currentView = View.staffDashboard;
            } else if (_user?.role == 'worker') {
              _currentView = View.workerDashboard;
            } else {
              _currentView = View.dashboard;
            }
          }),
          onEdit: () => setState(() => _currentView = View.edit),
          onDelete: () => _handleDeleteProject(selectedProject),
          onUpdateActivityStatus: (phaseId, activityId, status) =>
              _handleUpdateActivityStatus(
                selectedProject.id,
                phaseId,
                activityId,
                status,
              ),
        );
      case View.inquiry:
        return InquiryScreen(
          onCancel: () => setState(() {
            // Return to appropriate dashboard based on user role
            if (_user?.role == 'manager') {
              _currentView = View.managerDashboard;
            } else {
              _currentView = View.dashboard;
            }
          }),
        );
    }
  }

  Project _createEmptyProject() {
    return Project(
      id: '',
      customerName: '',
      location: '',
      partName: '',
      partNumber: '',
      revisionNumber: '',
      revisionDate: '',
      teamLeader: '',
      teamMembers: [],
      planNumber: '',
      dateOfIssue: '',
      teamLeaderAuthorization: '',
      totalWeeks: 0,
      phases: [],
      createdAt: '',
      progress: 0,
      projectStatus: 'ongoing',
    );
  }
}

enum View {
  login,
  register,
  forgot,
  dashboard,
  staffDashboard,
  workerDashboard,
  managerDashboard,
  create,
  edit,
  view,
  inquiry,
}
