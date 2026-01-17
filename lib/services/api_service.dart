import 'package:dio/dio.dart';
import '../utils/shared_preferences_manager.dart';
import '../screens/app.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiService {
  //local
  static const String baseUrl = 'http://192.168.29.219:5000';
  //live
  // static const String baseUrl = 'https://texspinapi.ifloriana.com';
  late final Dio _dio;

  static ApiService? _instance;

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (!baseUrl.contains('texspinapi.ifloriana.com')) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
          enabled: kDebugMode,
          filter: (options, args) {
            // don't print requests with uris containing '/posts'
            if (options.path.contains('/posts')) {
              return false;
            }
            // don't print responses with unit8 list data
            return !args.isResponse || !args.hasUint8ListData;
          },
        ),
      );
    }

    // Debug logging to verify base URL configuration
    // print('  🔥 ApiService initialized with baseUrl: $baseUrl');
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

  // Get Staff Performance
  Future<Map<String, dynamic>> getStaffPerformance({
    required String staffId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/staff-performance/$staffId',
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

  // Create Inquiry
  Future<Map<String, dynamic>> createInquiry({
    required Map<String, dynamic> data,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String? bearerToken,
  }) async {
    try {
      final token =
          bearerToken ?? await SharedPreferencesManager.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception('No authentication token available');
      }

      MultipartFile filePart;
      if (kIsWeb) {
        if (fileBytes == null)
          throw Exception('File bytes are required on web');
        filePart = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else {
        if (filePath == null)
          throw Exception('File path is required on mobile');
        filePart = await MultipartFile.fromFile(filePath, filename: fileName);
      }

      FormData formData = FormData.fromMap({...data, 'file': filePart});

      final response = await _dio.post(
        '/texspin/api/inquiry',
        data: formData,
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

  // Get Single Project by ID
  Future<Map<String, dynamic>> getProjectById(
    String projectId, {
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/apqpproject/$projectId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Staff APQP Projects
  Future<Map<String, dynamic>> getStaffApqpProjects({
    required String staffId,
  }) async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/texspin/api/apqpproject/staff/$staffId',
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
    String? technicalRemarks,
    String? assignmentAction,
    String? rejectionReason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{'phase': phase, 'activity': activity};
      if (staff != null) data['staff'] = staff;
      if (numberOfWeeks != null) data['numberOfWeeks'] = numberOfWeeks;
      if (fileUrl != null) data['fileUrl'] = fileUrl;
      if (technicalRemarks != null) data['technicalRemarks'] = technicalRemarks;
      if (assignmentAction != null) data['assignmentAction'] = assignmentAction;
      if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
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

  // Staff Respond to Activity (Accept, Reject, Upload)
  Future<Map<String, dynamic>> staffRespondToActivity({
    required String projectId,
    required String phaseId,
    required String activityId,
    String? assignmentAction,
    String? rejectionReason,
    String? fileUrl,
    String? technicalRemarks,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{
        'phase': phaseId.trim(),
        'activity': activityId.trim(),
      };

      if (assignmentAction != null) {
        data['assignmentAction'] = assignmentAction.trim();
      }
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        data['rejectionReason'] = rejectionReason.trim();
      }
      if (fileUrl != null && fileUrl.isNotEmpty) {
        data['fileUrl'] = fileUrl.trim();
      }
      if (technicalRemarks != null) {
        data['technicalRemarks'] = technicalRemarks.trim();
      }

      final response = await _dio.patch(
        '/texspin/api/apqpproject/$projectId/activity',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: Headers.jsonContentType,
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Staff Submit Work (Upload File via PATCH)
  Future<Map<String, dynamic>> staffSubmitProjectWork({
    required String projectId,
    required String phaseId,
    required String activityId,
    required FormData formData,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      // Ensure phase and activity are added to FormData if not already
      // Note: The calling code should populate FormData, but we can verify or document.
      // We assume FormData contains 'file', 'phase', 'activity' fields.

      final response = await _dio.patch(
        '/texspin/api/apqpproject/$projectId/activity',
        data: formData, // Sending FormData directly
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          // Dio sets multipart content type automatically when data is FormData
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload Project File API
  Future<String> uploadProjectFile(
    FormData formData, {
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/upload',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data is Map && response.data.containsKey('fileUrl')) {
        return response.data['fileUrl'];
      }
      return response.data.toString();
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
      // Safely handle different response data types
      final responseData = error.response?.data;
      String message = 'An error occurred';

      if (responseData != null) {
        if (responseData is Map<String, dynamic>) {
          // Handle JSON response
          final messageData = responseData['message'];
          if (messageData != null) {
            message = messageData.toString();
          }
        } else if (responseData is String) {
          // Handle string response
          message = responseData;
        } else {
          // Handle other types
          message = responseData.toString();
        }
      }

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

  // Review Task (Approve/Reject)
  Future<Map<String, dynamic>> reviewTask({
    required String taskId,
    required String status, // 'completed' or 'rejected'
    String? rejectionReason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final data = <String, dynamic>{'status': status};

      if (status == 'rejected' && rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }

      final response = await _dio.put(
        '/texspin/api/task/$taskId/review',
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
    String? deadline,
    int? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{'assignedStaffId': assignedStaffId};
      if (deadline != null) {
        data['deadline'] = deadline;
      }
      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }
      final response = await _dio.put(
        '/texspin/api/task/$taskId/reassign',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send Individual Task Reminder (POST)
  Future<Map<String, dynamic>> sendIndividualTaskReminder({
    required String taskId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/task/$taskId/reminder',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send Department Task Reminder (POST)
  Future<Map<String, dynamic>> sendDepartmentTaskReminder({
    required String taskId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/department-task/$taskId/reminder',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send APQP Task Reminder (POST)
  Future<Map<String, dynamic>> sendApqpTaskReminder({
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
    int? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {
        'phase': phase,
        'activity': activity,
        'staff': staff,
        'startDate': startDate,
        'endDate': endDate,
        'startWeek': startWeek,
        'endWeek': endWeek,
      };

      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }

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

  // Reassign APQP Project Activity Staff
  Future<Map<String, dynamic>> reassignActivityStaff({
    required String projectId,
    required String phaseId,
    required String activityId,
    required String staffId,
    required String startDate,
    required String endDate,
    required int startWeek,
    required int endWeek,
    int? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {
        'phaseId': phaseId,
        'activityId': activityId,
        'staffId': staffId,
        'startDate': startDate,
        'endDate': endDate,
        'startWeek': startWeek,
        'endWeek': endWeek,
      };

      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }

      final response = await _dio.put(
        '/texspin/api/apqpproject/$projectId/reassign-activity',
        data: data,
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

  Future<Map<String, dynamic>> respondToTask({
    required String taskId,
    required String status,
    String? rejectionReason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final data = <String, dynamic>{'status': status};

      if (status == 'rejected' && rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }

      final response = await _dio.put(
        '/texspin/api/task/$taskId/status',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitTask({
    required String taskId,
    required String? filePath,
    required List<int>? fileBytes,
    required String fileName,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      MultipartFile multipartFile;

      if (fileBytes != null) {
        // For web platform, use bytes
        multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else if (filePath != null) {
        // For mobile/desktop platforms, use file path
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('Either filePath or fileBytes must be provided');
      }

      // Only sending file as per user request
      FormData formData = FormData.fromMap({'file': multipartFile});

      final response = await _dio.put(
        '/texspin/api/task/$taskId/submit',
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

  Future<Map<String, dynamic>> createTask({
    required String name,
    required String description,
    String? deadline,
    required String assignedStaffId,
    int? frequency,
    bool isRecurringActive = false,
    List<int>? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {
        'name': name,
        'description': description,
        'assignedStaffId': assignedStaffId,
        'isRecurringActive': isRecurringActive,
      };

      if (deadline != null) {
        data['deadline'] = deadline;
      }
      if (frequency != null) {
        data['frequency'] = frequency;
      }
      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }

      final response = await _dio.post(
        '/texspin/api/task',
        data: data,
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
    String? deadline,
    required String assignedStaffId,
    int? frequency,
    bool isRecurringActive = false,
    List<int>? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {
        'name': name,
        'description': description,
        'assignedStaffId': assignedStaffId,
        'isRecurringActive': isRecurringActive,
      };

      if (deadline != null) {
        data['deadline'] = deadline;
      }
      if (frequency != null) {
        data['frequency'] = frequency;
      }
      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }

      final response = await _dio.put(
        '/texspin/api/task/$taskId',
        data: data,
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
    List<dynamic>? files,
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
        formFields['teamMembers'] =
            '[${teamMembersList.map((id) => '"$id"').join(',')}]';
      }

      FormData formData = FormData.fromMap(formFields);

      // Add files if provided
      final filesToUpload = files ?? (file != null ? [file] : <dynamic>[]);
      print('API: Files to upload: ${filesToUpload.length}');

      for (final fileItem in filesToUpload) {
        if (fileItem != null) {
          print('API: Processing file: ${fileItem.name}');
          // Use bytes for web platform, path for mobile
          if (fileItem.bytes != null) {
            print('API: Using bytes for ${fileItem.name}');
            formData.files.add(
              MapEntry(
                'attachments',
                MultipartFile.fromBytes(
                  fileItem.bytes!,
                  filename: fileItem.name,
                ),
              ),
            );
          } else if (fileItem.path != null) {
            print('API: Using path for ${fileItem.name}');
            formData.files.add(
              MapEntry(
                'attachments',
                await MultipartFile.fromFile(
                  fileItem.path!,
                  filename: fileItem.name,
                ),
              ),
            );
          }
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

  // Update End Phase Form (PUT)
  Future<Map<String, dynamic>> updateEndPhaseForm({
    required String formId,
    required Map<String, dynamic> data,
    dynamic file,
    List<dynamic>? files,
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
        formFields['teamMembers'] =
            '[${teamMembersList.map((id) => '"$id"').join(',')}]';
      }

      FormData formData = FormData.fromMap(formFields);

      // Add files if provided
      final filesToUpload = files ?? (file != null ? [file] : <dynamic>[]);
      print('API UPDATE: Files to upload: ${filesToUpload.length}');

      for (final fileItem in filesToUpload) {
        if (fileItem != null) {
          print('API UPDATE: Processing file: ${fileItem.name}');
          // Use bytes for web platform, path for mobile
          if (fileItem.bytes != null) {
            print('API UPDATE: Using bytes for ${fileItem.name}');
            formData.files.add(
              MapEntry(
                'attachments',
                MultipartFile.fromBytes(
                  fileItem.bytes!,
                  filename: fileItem.name,
                ),
              ),
            );
          } else if (fileItem.path != null) {
            print('API UPDATE: Using path for ${fileItem.name}');
            formData.files.add(
              MapEntry(
                'attachments',
                await MultipartFile.fromFile(
                  fileItem.path!,
                  filename: fileItem.name,
                ),
              ),
            );
          }
        }
      }

      final response = await _dio.put(
        '/texspin/api/endphaseform/$formId',
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

  // Get Project Approvals for Task Updates
  Future<Map<String, dynamic>> getProjectApprovals({
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/status/project-approvals',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'approvals': response.data};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update APQP Project Activity Status (Approve/Reject)
  Future<Map<String, dynamic>> updateApqpActivityStatus({
    required String projectId,
    required String phaseId,
    required String activityId,
    required String fileAction, // 'approve' or 'reject'
    String? rejectionReason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      // Ensure all values are properly formatted as strings
      final phaseIdStr = phaseId.toString().trim();
      final activityIdStr = activityId.toString().trim();
      final fileActionStr = fileAction.toString().trim();

      final data = <String, dynamic>{
        'phase': phaseIdStr,
        'activity': activityIdStr,
        'fileAction': fileActionStr,
      };

      if (fileAction == 'reject' && rejectionReason != null) {
        data['rejectionReason'] = rejectionReason.toString().trim();
      }

      final url = '/texspin/api/apqpproject/$projectId/activity';

      final response = await _dio.patch(
        url,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Keep the old method for backward compatibility (deprecated)
  @deprecated
  Future<Map<String, dynamic>> updateTaskStatus({
    required String taskId,
    required String status, // 'approved' or 'rejected'
    String? rejectionReason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final data = <String, dynamic>{'status': status};

      if (status == 'rejected' && rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }

      final url = '/texspin/api/task/$taskId/status';

      final response = await _dio.put(
        url,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Department Task APIs
  Future<Map<String, dynamic>> getDepartmentTasks({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/department-task',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> respondToDepartmentTask({
    required String taskId,
    required String status,
    String? rejectionReason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final data = <String, dynamic>{'status': status};

      if (status == 'rejected' && rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }

      // User requested /texspin/api/department-task/:id/accept
      // Changing to PUT as PATCH returned 404
      final response = await _dio.put(
        '/texspin/api/department-task/$taskId/accept',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitDepartmentTask({
    required String taskId,
    required String? filePath,
    required List<int>? fileBytes,
    required String fileName,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      MultipartFile multipartFile;

      if (fileBytes != null) {
        // For web platform, use bytes
        multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else if (filePath != null) {
        // For mobile/desktop platforms, use file path
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('Either filePath or fileBytes must be provided');
      }

      // Only sending file as per user request
      FormData formData = FormData.fromMap({'file': multipartFile});

      final response = await _dio.put(
        '/texspin/api/department-task/$taskId/submit',
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

  Future<Map<String, dynamic>> createDepartmentTask({
    required String name,
    required String description,
    String? deadline,
    required String assignedStaffId,
    int? frequency,
    bool isRecurringActive = false,
    List<int>? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {
        'name': name,
        'description': description,
        'assignedStaffId': assignedStaffId,
        'isRecurringActive': isRecurringActive,
      };

      if (deadline != null) {
        data['deadline'] = deadline;
      }
      if (frequency != null) {
        data['frequency'] = frequency;
      }
      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }

      final response = await _dio.post(
        '/texspin/api/department-task',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateDepartmentTask({
    required String taskId,
    required String name,
    required String description,
    String? deadline,
    required String assignedStaffId,
    int? frequency,
    bool isRecurringActive = false,
    List<int>? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {
        'name': name,
        'description': description,
        'assignedStaffId': assignedStaffId,
        'isRecurringActive': isRecurringActive,
      };

      if (deadline != null) {
        data['deadline'] = deadline;
      }
      if (frequency != null) {
        data['frequency'] = frequency;
      }
      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }

      final response = await _dio.put(
        '/texspin/api/department-task/$taskId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> reviewDepartmentTask({
    required String taskId,
    required String status, // 'completed' or 'rejected'
    String? rejectionReason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final data = <String, dynamic>{'status': status};

      if (status == 'rejected' && rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }

      final response = await _dio.put(
        '/texspin/api/department-task/$taskId/review',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteDepartmentTask({
    required String taskId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/department-task/$taskId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> reassignDepartmentTask({
    required String taskId,
    required String assignedStaffId,
    String? deadline,
    int? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{'assignedStaffId': assignedStaffId};
      if (deadline != null) {
        data['deadline'] = deadline;
      }
      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }
      final response = await _dio.put(
        '/texspin/api/department-task/$taskId/reassign',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Audit Type APIs
  Future<Map<String, dynamic>> getAuditTypes({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-type',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAuditType({
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/audit-type',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditType({
    required String id,
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/audit-type/$id',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditTypeStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/audit-type/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteAuditType({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/audit-type/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Audit Segment APIs
  Future<Map<String, dynamic>> getAuditSegments({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-segment',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAuditSegment({
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/audit-segment',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditSegment({
    required String id,
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/audit-segment/$id',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditSegmentStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/audit-segment/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteAuditSegment({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/audit-segment/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Audit Questions APIs
  Future<Map<String, dynamic>> getAuditQuestions({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-questions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAuditQuestion({
    required String question,
    String? answer,
    String? categoryId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {'question': question};
      if (answer != null) data['answer'] = answer;
      if (answer != null) data['answer'] = answer;
      if (categoryId != null) data['auditQueCategory'] = categoryId;

      final response = await _dio.post(
        '/texspin/api/audit-questions',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditQuestion({
    required String id,
    String? question,
    String? answer,
    String? categoryId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{};
      if (question != null) data['question'] = question;
      if (answer != null) data['answer'] = answer;
      if (categoryId != null) data['auditQueCategory'] = categoryId;

      final response = await _dio.put(
        '/texspin/api/audit-questions/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditQuestionStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/audit-questions/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteAuditQuestion({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/audit-questions/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Audit Template APIs
  Future<Map<String, dynamic>> getAuditTemplates({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-template',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAuditTemplate({
    required String name,
    required String auditSegment,
    required String auditType,
    required List<String> auditQuestions,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/audit-template',
        data: {
          'name': name,
          'auditSegment': auditSegment,
          'auditType': auditType,
          'auditQuestions': auditQuestions,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditTemplate({
    required String id,
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/audit-template/$id',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateFullAuditTemplate({
    required String id,
    required String name,
    required String auditSegment,
    required String auditType,
    required List<String> auditQuestions,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/audit-template/$id',
        data: {
          'name': name,
          'auditSegment': auditSegment,
          'auditType': auditType,
          'auditQuestions': auditQuestions,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditTemplateStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/audit-template/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteAuditTemplate({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/audit-template/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Audit Template by ID
  Future<Map<String, dynamic>> getAuditTemplateById({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-template/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Visitor Names APIs
  Future<Map<String, dynamic>> getVisitorNames({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/visiter-name',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createVisitorName({
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/visiter-name',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Audit Main APIs
  Future<Map<String, dynamic>> createAuditMain({
    required Map<String, dynamic> auditData,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/audit-main',
        data: auditData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAuditMains({String? bearerToken}) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-main',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStaffAuditMains({
    required String staffId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-main/staff/$staffId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Staff Dashboard Data
  Future<Map<String, dynamic>> getStaffDashboardData({
    required String staffId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/staff-dashboard/$staffId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> closeAuditMain({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.patch(
        '/texspin/api/audit-main/$id/close',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAuditMainById({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-main/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Assign Question to Staff
  Future<Map<String, dynamic>> assignQuestionToStaff({
    required String auditId,
    required String questionId,
    required String assignedTo,
    required String deadline,
    int? reminderDays,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = <String, dynamic>{
        'assignedTo': assignedTo,
        'deadline': deadline,
      };

      if (reminderDays != null) {
        data['reminderDays'] = reminderDays;
      }

      final response = await _dio.patch(
        '/texspin/api/audit-main/$auditId/assign-question/$questionId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Review Question (Approve/Reject)
  Future<Map<String, dynamic>> reviewQuestion({
    required String auditId,
    required String questionId,
    required String action, // "approve" or "reject"
    String? reason, // Required for reject action
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final data = {'action': action};
      if (action == 'reject' && reason != null) {
        data['reason'] = reason;
      }

      final response = await _dio.patch(
        '/texspin/api/audit-main/$auditId/review-question/$questionId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete Audit Main
  Future<Map<String, dynamic>> deleteAuditMain({
    required String auditId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/audit-main/$auditId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Audit Main (for audit transaction)
  Future<Map<String, dynamic>> updateAuditMain({
    required String auditId,
    Map<String, dynamic>? data,
    List<String>? methodologyFiles,
    List<String>? observationFiles,
    List<String>? actionPlanFiles,
    List<String>? actionEvidenceFiles,
    List<String>? otherFiles,
    int? auditScore,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      // Prepare the FormData payload
      Map<String, dynamic> formFields = {};

      if (auditScore != null) {
        formFields['auditScore'] = auditScore.toString();
      }

      if (methodologyFiles != null && methodologyFiles.isNotEmpty) {
        formFields['auditMethodology'] =
            methodologyFiles.first; // API seems to expect single file
      }

      if (observationFiles != null && observationFiles.isNotEmpty) {
        formFields['auditObservation'] = observationFiles.first;
      }

      if (actionPlanFiles != null && actionPlanFiles.isNotEmpty) {
        formFields['actionPlan'] = actionPlanFiles.first;
      }

      if (actionEvidenceFiles != null && actionEvidenceFiles.isNotEmpty) {
        formFields['actionEvidence'] = actionEvidenceFiles.first;
      }

      if (otherFiles != null && otherFiles.isNotEmpty) {
        // For multiple files, send as array or comma-separated string
        formFields['otherDocs'] = otherFiles.join(',');
      }

      // Add any additional data
      if (data != null) {
        formFields.addAll(
          data.map((key, value) => MapEntry(key, value.toString())),
        );
      }

      // Create FormData
      FormData formData = FormData.fromMap(formFields);

      // Debug: Log the data being sent
      developer.log(
        'Sending audit update FormData: $formFields',
        name: 'ApiService',
      );

      final response = await _dio.put(
        '/texspin/api/audit-main/$auditId',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      developer.log(
        'Audit update API response: ${response.data}',
        name: 'ApiService',
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Audit Main (for editing audit basic info)
  Future<Map<String, dynamic>> updateAuditBasicInfo({
    required String auditId,
    required Map<String, dynamic> auditData,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final response = await _dio.put(
        '/texspin/api/audit-main/$auditId',
        data: auditData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload file (generic file upload method)
  Future<Map<String, dynamic>> uploadFile({
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      MultipartFile multipartFile;

      if (fileBytes != null) {
        // For web platform, use bytes
        multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else if (filePath != null) {
        // For mobile/desktop platforms, use file path
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('Either filePath or fileBytes must be provided');
      }

      FormData formData = FormData.fromMap({'file': multipartFile});

      final response = await _dio.post(
        '/texspin/api/audit-main/upload', // Try audit-specific upload endpoint
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

  // Audit Main Status Update
  Future<Map<String, dynamic>> respondToAuditTask({
    required String auditId,
    required String status,
    String? rejectionReason,
    String? questionId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final data = <String, dynamic>{'status': status};

      if (status == 'rejected' && rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }

      if (questionId != null) {
        data['questionId'] = questionId;
      }

      final response = await _dio.put(
        '/texspin/api/audit-main/$auditId/status',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload Audit Question File
  Future<Map<String, dynamic>> uploadAuditQuestionFile({
    required String auditId,
    required String questionId,
    required String? filePath,
    required Uint8List? fileBytes,
    required String fileName,
  }) async {
    try {
      final token = await _getToken();

      FormData formData;
      if (kIsWeb) {
        formData = FormData.fromMap({
          'taskFile': MultipartFile.fromBytes(fileBytes!, filename: fileName),
        });
      } else {
        formData = FormData.fromMap({
          'taskFile': await MultipartFile.fromFile(
            filePath!,
            filename: fileName,
          ),
        });
      }

      final response = await _dio.patch(
        '/texspin/api/audit-main/$auditId/upload-question-file/$questionId',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send Audit Question Reminder
  Future<Map<String, dynamic>> sendAuditQuestionReminder({
    required String auditId,
    required String questionId,
    required String reminderNote,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/audit-main/$auditId/reminder/$questionId',
        data: {'reminderNote': reminderNote},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Staff Action on Audit Question (Approve/Reject)
  Future<Map<String, dynamic>> respondToAuditQuestion({
    required String auditId,
    required String questionId,
    required String action, // 'approve' or 'reject'
    String? reason,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      final data = <String, dynamic>{'action': action};

      if (action == 'reject' && reason != null) {
        data['reason'] = reason;
      }

      final response = await _dio.patch(
        '/texspin/api/audit-main/$auditId/staff-action/$questionId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitAuditTask({
    required String auditId,
    required Map<String, dynamic> data,
    String? methodologyPath,
    String? observationPath,
    String? actionPlanPath,
    String? actionEvidencePath,
    List<String>? otherFilesPaths,
    List<int>? methodologyBytes,
    List<int>? observationBytes,
    List<int>? actionPlanBytes,
    List<int>? actionEvidenceBytes,
    List<List<int>>? otherFilesBytes,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      Map<String, dynamic> formFields = Map.from(data);
      FormData formData = FormData.fromMap(formFields);

      if (methodologyBytes != null) {
        formData.files.add(
          MapEntry(
            'auditMethodology',
            MultipartFile.fromBytes(
              methodologyBytes,
              filename: 'methodology.xlsx',
            ),
          ),
        );
      } else if (methodologyPath != null) {
        formData.files.add(
          MapEntry(
            'auditMethodology',
            await MultipartFile.fromFile(
              methodologyPath,
              filename: 'methodology.xlsx',
            ),
          ),
        );
      }

      if (observationBytes != null) {
        formData.files.add(
          MapEntry(
            'auditObservation',
            MultipartFile.fromBytes(
              observationBytes,
              filename: 'observation.xlsx',
            ),
          ),
        );
      } else if (observationPath != null) {
        formData.files.add(
          MapEntry(
            'auditObservation',
            await MultipartFile.fromFile(
              observationPath,
              filename: 'observation.xlsx',
            ),
          ),
        );
      }

      if (actionPlanBytes != null) {
        formData.files.add(
          MapEntry(
            'actionPlan',
            MultipartFile.fromBytes(
              actionPlanBytes,
              filename: 'actionPlan.xlsx',
            ),
          ),
        );
      } else if (actionPlanPath != null) {
        formData.files.add(
          MapEntry(
            'actionPlan',
            await MultipartFile.fromFile(
              actionPlanPath,
              filename: 'actionPlan.xlsx',
            ),
          ),
        );
      }

      if (actionEvidenceBytes != null) {
        formData.files.add(
          MapEntry(
            'actionEvidence',
            MultipartFile.fromBytes(
              actionEvidenceBytes,
              filename: 'actionEvidence.xlsx',
            ),
          ),
        );
      } else if (actionEvidencePath != null) {
        formData.files.add(
          MapEntry(
            'actionEvidence',
            await MultipartFile.fromFile(
              actionEvidencePath,
              filename: 'actionEvidence.xlsx',
            ),
          ),
        );
      }

      // Handle other files
      if (otherFilesBytes != null && otherFilesBytes.isNotEmpty) {
        for (var i = 0; i < otherFilesBytes.length; i++) {
          formData.files.add(
            MapEntry(
              'otherDocs',
              MultipartFile.fromBytes(
                otherFilesBytes[i],
                filename: 'otherDoc_$i.xlsx',
              ),
            ),
          );
        }
      } else if (otherFilesPaths != null && otherFilesPaths.isNotEmpty) {
        for (var i = 0; i < otherFilesPaths.length; i++) {
          formData.files.add(
            MapEntry(
              'otherDocs',
              await MultipartFile.fromFile(
                otherFilesPaths[i],
                filename: 'otherDoc_$i.xlsx',
              ),
            ),
          );
        }
      }

      final response = await _dio.put(
        '/texspin/api/audit-main/$auditId',
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

  // Create MOM
  Future<Map<String, dynamic>> createMom({
    required String auditId,
    required Map<String, dynamic> data,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();

      FormData formData = FormData.fromMap(data);

      if (kIsWeb) {
        if (fileBytes != null && fileName != null) {
          formData.files.add(
            MapEntry(
              'otherDocuments',
              MultipartFile.fromBytes(fileBytes, filename: fileName),
            ),
          );
        }
      } else {
        if (filePath != null && fileName != null) {
          formData.files.add(
            MapEntry(
              'otherDocuments',
              await MultipartFile.fromFile(filePath, filename: fileName),
            ),
          );
        }
      }

      final response = await _dio.post(
        '/texspin/api/mom/$auditId',
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

  // Update MOM
  Future<Map<String, dynamic>> updateMom({
    required String auditId,
    required String momId,
    required Map<String, dynamic> data,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      FormData formData = FormData.fromMap(data);

      if (kIsWeb) {
        if (fileBytes != null && fileName != null) {
          formData.files.add(
            MapEntry(
              'otherDocuments',
              MultipartFile.fromBytes(fileBytes, filename: fileName),
            ),
          );
        }
      } else {
        if (filePath != null && fileName != null) {
          formData.files.add(
            MapEntry(
              'otherDocuments',
              await MultipartFile.fromFile(filePath, filename: fileName),
            ),
          );
        }
      }

      final response = await _dio.put(
        '/texspin/api/mom/$auditId/$momId',
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

  // Delete MOM
  Future<Map<String, dynamic>> deleteMom({
    required String auditId,
    required String momId,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/mom/$auditId/$momId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Audit Question Category APIs
  Future<Map<String, dynamic>> getAuditQuestionCategories({
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.get(
        '/texspin/api/audit-qus-category',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAuditQuestionCategory({
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.post(
        '/texspin/api/audit-qus-category',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditQuestionCategory({
    required String id,
    required String name,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/audit-qus-category/$id',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateAuditQuestionCategoryStatus({
    required String id,
    required String status,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.put(
        '/texspin/api/audit-qus-category/$id',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteAuditQuestionCategory({
    required String id,
    String? bearerToken,
  }) async {
    try {
      final token = bearerToken ?? await _getToken();
      final response = await _dio.delete(
        '/texspin/api/audit-qus-category/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
