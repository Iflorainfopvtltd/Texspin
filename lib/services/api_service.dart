import 'package:dio/dio.dart';
import '../utils/shared_preferences_manager.dart';
import '../screens/app.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.29.110:5000'; // Update with actual base URL
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  // Create Activity
  Future<Map<String, dynamic>> createActivity({
    required String name,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/activity',
        data: {'name': name, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Activity (PUT)
  Future<Map<String, dynamic>> updateActivity({
    required String id,
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/activity/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete Activity
  Future<Map<String, dynamic>> deleteActivity({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/activity/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Activity Status (PATCH)
  Future<Map<String, dynamic>> updateActivityStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/activity/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Registration API
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'admin',
  }) async {
    try {
      final response = await _dio.post(
        '/texspin/api/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Login API
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/texspin/api/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Forgot Password API
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/texspin/api/forgot-password',
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Staff API
  Future<Map<String, dynamic>> getStaff({String? bearerToken}) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }
      final response = await _dio.get(
        '/texspin/api/staff',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getInquiries({String? bearerToken}) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final response = await _dio.get(
        '/texspin/api/inquiry',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create Staff
  Future<Map<String, dynamic>> createStaff({
    required Map<String, dynamic> staffData,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/staff',
        data: staffData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Staff (PUT)
  Future<Map<String, dynamic>> updateStaff({
    required String id,
    required Map<String, dynamic> staffData,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/staff/$id',
        data: staffData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete Staff
  Future<Map<String, dynamic>> deleteStaff({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/staff/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Staff Status (PATCH)
  Future<Map<String, dynamic>> updateStaffStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/staff/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Staff by ID
  Future<Map<String, dynamic>> getStaffById({
    required String staffId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/staff/$staffId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Change Staff Password
  Future<Map<String, dynamic>> changeStaffPassword({
    required String staffId,
    required String email,
    required String newPassword,
    required String confirmPassword,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/staff/change-password',
        data: {
          'staffId': staffId,
          'email': email.trim(),
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Phases API
  Future<Map<String, dynamic>> getPhases({String? bearerToken}) async {
    try {
      // Get token from parameter or from SharedPreferences
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }
      final response = await _dio.get(
        '/texspin/api/phase',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Activities API
  Future<Map<String, dynamic>> getActivities({String? bearerToken}) async {
    try {
      // Get token from parameter or from SharedPreferences
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }
      final response = await _dio.get(
        '/texspin/api/activity',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get APQP Projects API
  Future<Map<String, dynamic>> getProjects({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/apqpproject',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get APQP Projects by Team Leader (Manager Dashboard)
  Future<Map<String, dynamic>> getProjectsByTeamLeader(
    String staffId, {
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/apqpproject/by-teamleader',
        queryParameters: {'staffId': staffId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update APQP Project Activity (Assign Staff, Update Status, etc.)
  Future<Map<String, dynamic>> updateProjectActivity({
    required String projectId,
    required Map<String, dynamic> activityData,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/apqpproject/$projectId',
        data: activityData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create APQP Project API
  Future<Map<String, dynamic>> createProject({
    required Map<String, dynamic> projectData,
    String? bearerToken,
  }) async {
    try {
      // Get token from parameter or from SharedPreferences
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }
      final response = await _dio.post(
        '/texspin/api/apqpproject',
        data: projectData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update APQP Project API (PUT)
  Future<Map<String, dynamic>> updateProject({
    required String projectId,
    required Map<String, dynamic> projectData,
    String? bearerToken,
  }) async {
    try {
      // Get token from parameter or from SharedPreferences
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }
      final response = await _dio.put(
        '/texspin/api/apqpproject/$projectId',
        data: projectData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update APQP Project Activity API (PATCH)
  Future<Map<String, dynamic>> assignProjectActivityStaff({
    required String projectId,
    required String phase,
    required String activity,
    String? staff,
    int? numberOfWeeks,
    String? fileUrl,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{'phase': phase, 'activity': activity};
      if (staff != null) data['staff'] = staff;
      if (numberOfWeeks != null) data['numberOfWeeks'] = numberOfWeeks;
      if (fileUrl != null) data['fileUrl'] = fileUrl;

      final response = await _dio.patch(
        '/texspin/api/apqpproject/$projectId/activity',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete APQP Project API
  Future<Map<String, dynamic>> deleteProject({
    required String projectId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/apqpproject/$projectId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get token helper
  Future<String> _getToken() async {
    final token = await SharedPreferencesManager.getToken() ?? '';
    if (token.isEmpty) {
      throw Exception('No authentication token available');
    }
    return token;
  }

  // Designation APIs
  Future<Map<String, dynamic>> getDesignations({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/designation',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createDesignation({
    required String name,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/designation',
        data: {'name': name, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateDesignation({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/designation/$id',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteDesignation({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/designation/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateDesignationStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/designation/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Zone APIs
  Future<Map<String, dynamic>> getZones({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/zone',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createZone({
    required String name,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/zone',
        data: {'name': name, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateZone({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/zone/$id',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteZone({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/zone/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateZoneStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/zone/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Department APIs
  Future<Map<String, dynamic>> getDepartments({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/department',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/department',
        data: {'name': name, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateDepartment({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/department/$id',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteDepartment({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/department/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateDepartmentStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/department/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Phase APIs
  Future<Map<String, dynamic>> getPhaseEntities({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/phase',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPhaseEntity({
    required String name,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/phase',
        data: {'name': name, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updatePhaseEntity({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/phase/$id',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deletePhaseEntity({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/phase/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updatePhaseEntityStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/phase/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Template APIs
  Future<Map<String, dynamic>> getTemplates({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/template',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTemplate({
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/template',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTemplate({
    required String id,
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/template/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteTemplate({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/template/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTemplateStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/template/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error
      final statusCode = error.response?.statusCode;
      final message = error.response?.data?['message'] ?? 'An error occurred';
      if (statusCode == 401) {
        SharedPreferencesManager.clearAll();
        if (App.onGlobalLogout != null) {
          App.onGlobalLogout!.call();
        }
        return 'Session expired. Please log in again.';
      }
      return 'Error $statusCode: $message';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    } else {
      return error.message ?? 'An unexpected error occurred';
    }
  }

  Future<void> updateFcmToken(String fcmToken, {String? bearerToken}) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }

      await _dio.post(
        '/texspin/api/fcm-token',
        data: {"fcmToken": fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteInquiry({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/inquiry/$id', // Your endpoint
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Work Category APIs
  Future<Map<String, dynamic>> getWorkCategories({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/workcategory',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createWorkCategory({
    required String name,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/workcategory',
        data: {'name': name, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateWorkCategory({
    required String id,
    required String name,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/workcategory/$id',
        data: {'name': name, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteWorkCategory({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/workcategory/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateWorkCategoryStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/workcategory/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FCM Token APIs for Staff, Manager, and Worker
  Future<void> updateStaffFcmToken(
    String fcmToken, {
    String? bearerToken,
  }) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }

      await _dio.post(
        '/texspin/api/staff/fcm-token',
        data: {"fcmToken": fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateManagerFcmToken(
    String fcmToken, {
    String? bearerToken,
  }) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }

      await _dio.post(
        '/texspin/api/staff/fcm-token',
        data: {"fcmToken": fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateWorkerFcmToken(
    String fcmToken, {
    String? bearerToken,
  }) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }

      await _dio.post(
        '/texspin/api/staff/fcm-token',
        data: {"fcmToken": fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic method to update FCM token based on user role
  Future<void> updateFcmTokenByRole(
    String fcmToken,
    String userRole, {
    String? bearerToken,
  }) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }

      String endpoint;

      if (userRole == 'staff' ||
          userRole == 'manager' ||
          userRole == 'worker') {
        endpoint = '/texspin/api/staff/fcm-token';
      } else if (userRole == 'admin') {
        endpoint = '/texspin/api/fcm-token';
      } else {
        throw Exception('Invalid user role');
      }

      await _dio.post(
        endpoint,
        data: {"fcmToken": fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reassign Project Activity Staff (PATCH for existing assignment)
  Future<Map<String, dynamic>> reassignProjectActivityStaff({
    required String projectId,
    required String phase,
    required String activity,
    String? staff,
    int? numberOfWeeks,
    String? fileUrl,
    required String template,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{
        'phase': phase,
        'activity': activity,
        'template': template,
      };
      if (staff != null) data['staff'] = staff;
      if (numberOfWeeks != null) data['numberOfWeeks'] = numberOfWeeks;
      if (fileUrl != null) data['fileUrl'] = fileUrl;

      final response = await _dio.patch(
        '/texspin/api/apqpproject/$projectId/activity',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Assign Project Activity Staff with dates and weeks (POST for new assignment)
  Future<Map<String, dynamic>> assignProjectActivityStaffWithDates({
    required String projectId,
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/apqpproject/$projectId/activity',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reassign Project Activity Staff with dates and weeks (PATCH for existing assignment)
  Future<Map<String, dynamic>> reassignProjectActivityStaffWithDates({
    required String projectId,
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/apqpproject/$projectId/activity',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reassign Task Staff (PUT for task reassignment)
  Future<Map<String, dynamic>> reassignTaskStaff({
    required String taskId,
    required String assignedStaffId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/task/$taskId/reassign',
        data: {'assignedStaffId': assignedStaffId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Assign Activity Staff (PATCH for new assignment)
  Future<Map<String, dynamic>> assignActivityStaff({
    required String projectId,
    required String phase,
    required String activity,
    required String staff,
    required String startDate,
    required String endDate,
    required int startWeek,
    required int endWeek,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/apqpproject/$projectId/activity',
        data: {
          'phase': phase,
          'activity': activity,
          'staff': staff,
          'startDate': startDate,
          'endDate': endDate,
          'startWeek': startWeek,
          'endWeek': endWeek,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reassign Activity Staff (PUT for reassignment)
  Future<Map<String, dynamic>> reassignActivityStaff({
    required String projectId,
    required String phaseId,
    required String activityId,
    required String staffId,
    required String startDate,
    required String endDate,
    required int startWeek,
    required int endWeek,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/apqpproject/$projectId/reassign-activity',
        data: {
          'phaseId': phaseId,
          'activityId': activityId,
          'staffId': staffId,
          'startDate': startDate,
          'endDate': endDate,
          'startWeek': startWeek,
          'endWeek': endWeek,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Task APIs
  Future<Map<String, dynamic>> getTasks({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/task',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTask({
    required String name,
    required String description,
    required String deadline,
    required String assignedStaffId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/task',
        data: {
          'name': name,
          'description': description,
          'deadline': deadline,
          'assignedStaffId': assignedStaffId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    required String name,
    required String description,
    required String deadline,
    required String assignedStaffId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/task/$taskId',
        data: {
          'name': name,
          'description': description,
          'deadline': deadline,
          'assignedStaffId': assignedStaffId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteTask({
    required String taskId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/task/$taskId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendTaskReminder({
    required String projectId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/apqpproject/$projectId/reminder',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // End Phase Form API
  Future<Map<String, dynamic>> createEndPhaseForm({
    required Map<String, dynamic> data,
    dynamic file,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      
      // Create FormData with proper field mapping
      Map<String, dynamic> formFields = {
        'apqpProject': data['apqpProject'],
        'phase': data['phase'],
        'date': data['date'],
        'teamLeader': data['teamLeader'],
      };
      
      // Add team members as JSON array string
      if (data['teamMembers'] != null && data['teamMembers'] is List) {
        // Convert list to JSON array string format that backend expects
        // e.g., ["id1", "id2"]
        final teamMembersList = data['teamMembers'] as List;
        formFields['teamMembers'] = '[${teamMembersList.map((id) => '"$id"').join(',')}]';
      }
      
      FormData formData = FormData.fromMap(formFields);
      
      // Add file if provided
      if (file != null) {
        // Use bytes for web platform, path for mobile
        if (file.bytes != null) {
          formData.files.add(
            MapEntry(
              'attachments',
              MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
              ),
            ),
          );
        } else if (file.path != null) {
          formData.files.add(
            MapEntry(
              'attachments',
              await MultipartFile.fromFile(
                file.path!,
                filename: file.name,
              ),
            ),
          );
        }
      }

      final response = await _dio.post(
        '/texspin/api/endphaseform',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get End Phase Forms
  Future<Map<String, dynamic>> getEndPhaseForms({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/endphaseform',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update End Phase Form
  Future<Map<String, dynamic>> updateEndPhaseForm({
    required String id,
    required Map<String, dynamic> data,
    dynamic file,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      
      // Create FormData with proper field mapping
      Map<String, dynamic> formFields = {
        'apqpProject': data['apqpProject'],
        'phase': data['phase'],
        'date': data['date'],
        'teamLeader': data['teamLeader'],
      };
      
      // Add team members as JSON array string
      if (data['teamMembers'] != null && data['teamMembers'] is List) {
        final teamMembersList = data['teamMembers'] as List;
        formFields['teamMembers'] = '[${teamMembersList.map((id) => '"$id"').join(',')}]';
      }
      
      FormData formData = FormData.fromMap(formFields);
      
      // Add file if provided
      if (file != null) {
        // Use bytes for web platform, path for mobile
        if (file.bytes != null) {
          formData.files.add(
            MapEntry(
              'attachments',
              MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
              ),
            ),
          );
        } else if (file.path != null) {
          formData.files.add(
            MapEntry(
              'attachments',
              await MultipartFile.fromFile(
                file.path!,
                filename: file.name,
              ),
            ),
          );
        }
      }

      final response = await _dio.put(
        '/texspin/api/endphaseform/$id',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete End Phase Form
  Future<Map<String, dynamic>> deleteEndPhaseForm({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/endphaseform/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Accept End Phase Form (if there's an endpoint for this)
  Future<Map<String, dynamic>> acceptEndPhaseForm({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/endphaseform/$id/accept',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reject End Phase Form (if there's an endpoint for this)
  Future<Map<String, dynamic>> rejectEndPhaseForm({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/endphaseform/$id/reject',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
