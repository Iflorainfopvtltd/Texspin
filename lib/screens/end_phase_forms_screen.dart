import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_badge.dart';
import '../widgets/custom_button.dart';
import '../widgets/end_phase_form_dialog.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

class EndPhaseFormsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final Project? project;
  final String? userRole;
  final bool isDialog;

  const EndPhaseFormsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.project,
    this.userRole,
    this.isDialog = false,
  });

  @override
  State<EndPhaseFormsScreen> createState() => _EndPhaseFormsScreenState();
}

class _EndPhaseFormsScreenState extends State<EndPhaseFormsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _endPhaseForms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEndPhaseForms();
  }

  Future<void> _fetchEndPhaseForms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getEndPhaseForms();
      final allForms = response['endPhaseForms'] as List<dynamic>;

      // Filter forms for this project
      final projectForms = allForms.where((form) {
        final project = form['apqpProject'];
        return project != null && project['_id'] == widget.projectId;
      }).toList();

      setState(() {
        _endPhaseForms = projectForms.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching end phase forms: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteForm(String formId) async {
    try {
      await _apiService.deleteEndPhaseForm(id: formId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('End phase form deleted successfully'),
              ],
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
        _fetchEndPhaseForms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  void _showTeamMembers(List<dynamic> teamMembers, bool isMobile) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppTheme.blue50.withOpacity(0.3)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.blue600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Team Members',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${teamMembers.length} members',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: teamMembers.length,
                  itemBuilder: (context, index) {
                    final member = teamMembers[index] as Map<String, dynamic>;
                    final name = '${member['firstName']} ${member['lastName']}';
                    final email = member['email'] ?? '';
                    final staffId = member['staffId'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gray200),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gray300.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.blue500, AppTheme.blue600],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gray900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                if (email.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: AppTheme.gray600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.gray600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (staffId.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.badge_outlined,
                                        size: 14,
                                        color: AppTheme.gray600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'ID: $staffId',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.gray600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachments(List<dynamic> attachments, bool isMobile) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final isMobileDialog = screenWidth < 600;

            return Container(
              constraints: BoxConstraints(
                maxWidth: isMobileDialog ? screenWidth * 0.9 : 500,
                maxHeight: isMobileDialog ? screenHeight * 0.8 : 550,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, AppTheme.green50.withOpacity(0.3)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.green600,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.attach_file,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attachments',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${attachments.length} files',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: attachments.length,
                      itemBuilder: (context, index) {
                        final attachment =
                            attachments[index] as Map<String, dynamic>;
                        final fileName = attachment['fileName'] ?? 'Unknown';
                        final fileUrl = attachment['fileUrl'] ?? '';
                        final fileExtension = fileName
                            .split('.')
                            .last
                            .toLowerCase();

                        return Container(
                          margin: EdgeInsets.only(
                            bottom: isMobileDialog ? 8 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gray200),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.gray300.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isMobileDialog
                              ? _buildMobileAttachmentItem(
                                  fileName,
                                  fileUrl,
                                  fileExtension,
                                )
                              : _buildDesktopAttachmentItem(
                                  fileName,
                                  fileUrl,
                                  fileExtension,
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return AppTheme.red500;
      case 'doc':
      case 'docx':
        return AppTheme.blue600;
      case 'xls':
      case 'xlsx':
        return AppTheme.green600;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'zip':
      case 'rar':
        return Colors.brown;
      default:
        return AppTheme.gray600;
    }
  }

  Widget _buildMobileAttachmentItem(
    String fileName,
    String fileUrl,
    String fileExtension,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // File icon and name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getFileColor(fileExtension),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileIcon(fileExtension),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getFileColor(fileExtension).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fileExtension.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getFileColor(fileExtension),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Download button (full width on mobile)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _downloadFile(fileUrl, fileName);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  developer.log('Download failed, keeping dialog open: $e');
                }
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAttachmentItem(
    String fileName,
    String fileUrl,
    String fileExtension,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getFileColor(fileExtension),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_getFileIcon(fileExtension), color: Colors.white, size: 24),
      ),
      title: Text(
        fileName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.gray900,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getFileColor(fileExtension).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fileExtension.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getFileColor(fileExtension),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.cloud_download_outlined,
              size: 14,
              color: AppTheme.gray500,
            ),
            const SizedBox(width: 4),
            const Text(
              'Click to download',
              style: TextStyle(fontSize: 12, color: AppTheme.gray500),
            ),
          ],
        ),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.green500, AppTheme.green600],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.download, color: Colors.white),
          onPressed: () async {
            try {
              await _downloadFile(fileUrl, fileName);
              if (mounted) {
                Navigator.pop(context);
              }
            } catch (e) {
              developer.log('Download failed, keeping dialog open: $e');
            }
          },
        ),
      ),
      onTap: () async {
        try {
          await _downloadFile(fileUrl, fileName);
          if (mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          developer.log('Download failed, keeping dialog open: $e');
        }
      },
    );
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $fileName...'),
          backgroundColor: AppTheme.blue600,
        ),
      );

      // Construct full URL using ApiService baseUrl
      final String fullUrl = ApiService.baseUrl + fileUrl;

      developer.log('Downloading file from: $fullUrl');

      // Check if running on mobile platform
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Mobile download using dio and path_provider
        await _downloadFileOnMobile(fullUrl, fileName);
      } else {
        // Web/Desktop download using url_launcher
        await _downloadFileOnWeb(fullUrl, fileName);
      }
    } catch (e) {
      developer.log('Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error downloading $fileName: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _downloadFileOnMobile(String fullUrl, String fileName) async {
    try {
      // Request storage permission first
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      } else if (Platform.isIOS) {
        await _requestIOSPermissions();
      }

      Directory? downloadsDirectory;
      String downloadPath = '';

      if (Platform.isAndroid) {
        // For Android, use the public Downloads directory
        downloadsDirectory = Directory('/storage/emulated/0/Download');

        // Create directory if it doesn't exist
        if (!await downloadsDirectory.exists()) {
          await downloadsDirectory.create(recursive: true);
        }

        downloadPath = '/storage/emulated/0/Download';
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
        downloadPath = downloadsDirectory.path;
      }

      if (downloadsDirectory == null) {
        throw 'Could not access downloads directory';
      }

      final String filePath = '${downloadsDirectory.path}/$fileName';

      developer.log('Attempting to download to: $filePath');

      // Download file using Dio
      final dio = Dio();
      await dio.download(
        fullUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            developer.log('Download progress: $progress%');
          }
        },
      );

      // Verify file was created
      final file = File(filePath);
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;

      developer.log(
        'File exists: $fileExists, Size: $fileSize bytes, Path: $filePath',
      );

      if (!fileExists) {
        throw 'File was not created successfully';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$fileName downloaded successfully')),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved to: Downloads folder',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  'Size: ${(fileSize / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: AppTheme.green500,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open Downloads',
              textColor: Colors.white,
              onPressed: () async {
                // Try to open the Downloads folder
                try {
                  if (Platform.isAndroid) {
                    // Open Downloads folder using intent
                    final Uri downloadsUri = Uri.parse(
                      'content://com.android.externalstorage.documents/document/primary%3ADownload',
                    );
                    if (await canLaunchUrl(downloadsUri)) {
                      await launchUrl(
                        downloadsUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      // Fallback: open file manager
                      final Uri fileManagerUri = Uri.parse(
                        'content://com.android.documentsui.DocumentsActivity',
                      );
                      await launchUrl(
                        fileManagerUri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                } catch (e) {
                  developer.log('Could not open Downloads folder: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please check your Downloads folder in the file manager',
                        ),
                        backgroundColor: AppTheme.blue600,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      throw 'Mobile download failed: $e';
    }
  }

  Future<void> _downloadFileOnWeb(String fullUrl, String fileName) async {
    try {
      final Uri url = Uri.parse(fullUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$fileName download started')),
                ],
              ),
              backgroundColor: AppTheme.green500,
            ),
          );
        }
      } else {
        throw 'Could not launch $fullUrl';
      }
    } catch (e) {
      throw 'Web download failed: $e';
    }
  }

  Future<void> _requestAndroidPermissions() async {
    // Check if storage permission is already granted
    final storageStatus = await Permission.storage.status;
    final manageStorageStatus = await Permission.manageExternalStorage.status;

    // If either permission is granted, we're good to go
    if (storageStatus == PermissionStatus.granted ||
        manageStorageStatus == PermissionStatus.granted) {
      developer.log('Storage permission already granted');
      return;
    }

    // Only show dialog if permission is not granted
    if (storageStatus == PermissionStatus.denied ||
        storageStatus == PermissionStatus.restricted) {
      // Show permission rationale dialog only if needed
      if (mounted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to download files to your device. '
              'The files will be saved to your Downloads folder.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Grant Permission',
                onPressed: () => Navigator.pop(context, true),
                variant: ButtonVariant.default_,
                size: ButtonSize.sm,
              ),
            ],
          ),
        );

        if (shouldRequest != true) {
          throw 'Storage permission is required to download files';
        }
      }

      // Request storage permission
      final storagePermission = await Permission.storage.request();

      if (storagePermission != PermissionStatus.granted) {
        // For Android 11+ (API 30+), try manage external storage
        final managePermission = await Permission.manageExternalStorage
            .request();

        if (managePermission != PermissionStatus.granted) {
          // Show settings dialog only if both permissions failed
          if (mounted) {
            final openSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permission Denied'),
                content: const Text(
                  'Storage permission was denied. Please grant storage permission in app settings to download files.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  CustomButton(
                    text: 'Open Settings',
                    onPressed: () => Navigator.pop(context, true),
                    variant: ButtonVariant.default_,
                    size: ButtonSize.sm,
                  ),
                ],
              ),
            );

            if (openSettings == true) {
              await openAppSettings();
            }
          }

          throw 'Storage permission denied. Please grant permission in app settings.';
        }
      }
    } else if (storageStatus == PermissionStatus.permanentlyDenied) {
      // Handle permanently denied case
      if (mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Storage permission is required to download files. Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Open Settings',
                onPressed: () => Navigator.pop(context, true),
                variant: ButtonVariant.default_,
                size: ButtonSize.sm,
              ),
            ],
          ),
        );

        if (openSettings == true) {
          await openAppSettings();
        }
      }

      throw 'Storage permission denied. Please grant permission in app settings.';
    }
  }

  Future<void> _requestIOSPermissions() async {
    // For iOS, check if we already have the necessary permissions
    final photosPermission = await Permission.photos.status;

    // If permission is already granted, no need to ask again
    if (photosPermission == PermissionStatus.granted ||
        photosPermission == PermissionStatus.limited) {
      developer.log('iOS file access permission already granted');
      return;
    }

    // Only show dialog if permission is denied or not determined
    if (photosPermission == PermissionStatus.denied ||
        photosPermission == PermissionStatus.restricted) {
      if (mounted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('File Access Permission'),
            content: const Text(
              'This app needs permission to save files to your device. '
              'Files will be saved to the app\'s Documents folder.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Grant Permission',
                onPressed: () => Navigator.pop(context, true),
                variant: ButtonVariant.default_,
                size: ButtonSize.sm,
              ),
            ],
          ),
        );

        if (shouldRequest != true) {
          throw 'File access permission is required to download files';
        }
      }

      final permission = await Permission.photos.request();

      if (permission == PermissionStatus.denied ||
          permission == PermissionStatus.permanentlyDenied) {
        if (mounted) {
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Please grant file access permission in Settings to download files.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                CustomButton(
                  text: 'Open Settings',
                  onPressed: () => Navigator.pop(context, true),
                  variant: ButtonVariant.default_,
                  size: ButtonSize.sm,
                ),
              ],
            ),
          );

          if (openSettings == true) {
            await openAppSettings();
          }
        }

        throw 'File access permission denied. Please grant permission in Settings.';
      }
    } else if (photosPermission == PermissionStatus.permanentlyDenied) {
      // Handle permanently denied case
      if (mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'File access permission is required. Please enable it in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Open Settings',
                onPressed: () => Navigator.pop(context, true),
                variant: ButtonVariant.default_,
                size: ButtonSize.sm,
              ),
            ],
          ),
        );

        if (openSettings == true) {
          await openAppSettings();
        }
      }

      throw 'File access permission denied. Please grant permission in Settings.';
    }
  }

  void _editForm(Map<String, dynamic> form, bool isMobile) {
    if (widget.project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project data not available'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    final phase = form['phase'] as Map<String, dynamic>?;
    final phaseId = phase?['_id'] ?? '';
    final phaseName = phase?['name'] ?? 'Unknown Phase';
    final formId = form['_id'] as String?;

    // Show dialog for both mobile and desktop/tablet
    showDialog(
      context: context,
      builder: (context) => EndPhaseFormDialog(
        projectId: widget.projectId,
        phaseId: phaseId,
        phaseName: phaseName,
        project: widget.project!,
        isEditMode: true,
        existingFormData: form,
        formId: formId,
        onSuccess: () {
          _fetchEndPhaseForms();
        },
      ),
    );
  }

  void _showDeleteConfirmation(String formId, String phaseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete End Phase Form'),
        content: Text(
          'Are you sure you want to delete the end phase form for $phaseName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () {
              Navigator.pop(context);
              _deleteForm(formId);
            },
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (widget.isDialog) {
      // Dialog version without Scaffold and AppBar
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Custom header for dialog
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(bottom: BorderSide(color: AppTheme.gray200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Phase Forms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.projectName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.gray900,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(child: _buildContent(isMobile, isTablet)),
          ],
        ),
      );
    }

    // Regular screen version with Scaffold and AppBar
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.gray900,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'End Phase Forms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              widget.projectName,
              style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
            ),
          ],
        ),
      ),
      body: _buildContent(isMobile, isTablet),
    );
  }

  Widget _buildContent(bool isMobile, bool isTablet) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.red500,
                ),
                const SizedBox(height: 16),
                Text('Error: $_error'),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Retry',
                  onPressed: _fetchEndPhaseForms,
                  variant: ButtonVariant.outline,
                ),
              ],
            ),
          )
        : _endPhaseForms.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: AppTheme.gray500,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No end phase forms found',
                  style: TextStyle(fontSize: 16, color: AppTheme.gray600),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: isMobile
                    ? _buildMobileView()
                    : isTablet
                    ? _buildTabletView()
                    : _buildDesktopView(),
              ),
            ),
          );
  }

  Widget _buildMobileView() {
    return Column(
      children: _endPhaseForms.map((form) => _buildMobileCard(form)).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> form) {
    final formId = form['_id'] as String;
    final phase = form['phase'] as Map<String, dynamic>?;
    final phaseName = phase?['name'] ?? 'Unknown Phase';
    final date = _formatDate(form['date'] as String?);
    final reviewNo = form['reviewNo'] as String? ?? 'N/A';
    final teamLeader = form['teamLeader'] as Map<String, dynamic>?;
    final teamLeaderName = teamLeader != null
        ? '${teamLeader['firstName']} ${teamLeader['lastName']}'
        : 'N/A';
    final teamMembers = form['teamMembers'] as List<dynamic>? ?? [];
    final attachments = form['attachments'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    phaseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                CustomBadge(text: reviewNo, variant: BadgeVariant.secondary),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Date', date),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showTeamMembers(teamMembers, true),
              child: _buildInfoRow(
                Icons.people,
                'Team Members',
                '${teamMembers.length} members',
                isClickable: false, // Remove blue styling for mobile
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showAttachments(attachments, true),
              child: _buildInfoRow(
                Icons.attach_file,
                'Attachments',
                '${attachments.length} files',
                isClickable: false, // Remove blue styling for mobile
              ),
            ),
            const SizedBox(height: 16),
            // Show action buttons only for non-admin users
            if (widget.userRole != 'admin')
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Edit',
                      onPressed: () => _editForm(form, true),
                      variant: ButtonVariant.default_,
                      size: ButtonSize.sm,
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Delete',
                      onPressed: () =>
                          _showDeleteConfirmation(formId, phaseName),
                      variant: ButtonVariant.destructive,
                      size: ButtonSize.sm,
                      icon: const Icon(
                        Icons.delete,
                        size: 16,
                        color: AppTheme.primaryForeground,
                      ),
                    ),
                  ),
                ],
              )
            else
              // Show read-only message for admin users
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.blue50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.blue200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: AppTheme.blue600),
                    SizedBox(width: 8),
                    Text(
                      'View Only',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.blue600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletView() {
    return _buildDesktopView();
  }

  Widget _buildDesktopView() {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'End Phase Filled Forms',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),
          DataTable(
            headingRowColor: MaterialStateProperty.all(AppTheme.blue50),
            columns: const [
              DataColumn(
                label: Text(
                  'Phase',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Review No',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Team Members',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Attachments',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            rows: _endPhaseForms.map((form) => _buildDataRow(form)).toList(),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> form) {
    final formId = form['_id'] as String;
    final phase = form['phase'] as Map<String, dynamic>?;
    final phaseName = phase?['name'] ?? 'Unknown Phase';
    final date = _formatDate(form['date'] as String?);
    final reviewNo = form['reviewNo'] as String? ?? 'N/A';
    final teamLeader = form['teamLeader'] as Map<String, dynamic>?;
    final teamLeaderName = teamLeader != null
        ? '${teamLeader['firstName']} ${teamLeader['lastName']}'
        : 'N/A';
    final teamMembers = form['teamMembers'] as List<dynamic>? ?? [];
    final attachments = form['attachments'] as List<dynamic>? ?? [];

    return DataRow(
      cells: [
        DataCell(Text(phaseName)),
        DataCell(CustomBadge(text: reviewNo, variant: BadgeVariant.secondary)),
        DataCell(Text(date)),
        DataCell(
          InkWell(
            onTap: () => _showTeamMembers(teamMembers, false),
            child: Text('${teamMembers.length} members'),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => _showAttachments(attachments, false),
            child: Text('${attachments.length} files'),
          ),
        ),
        DataCell(
          widget.userRole != 'admin'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppTheme.blue600,
                      ),
                      onPressed: () => _editForm(form, false),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.red500,
                      ),
                      onPressed: () =>
                          _showDeleteConfirmation(formId, phaseName),
                      tooltip: 'Delete',
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.blue50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.blue200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: AppTheme.blue600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'View Only',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.blue600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isClickable = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isClickable ? AppTheme.blue600 : AppTheme.gray600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppTheme.gray600),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isClickable ? AppTheme.blue600 : AppTheme.gray900,
                    decoration: isClickable ? TextDecoration.underline : null,
                  ),
                ),
              ),
              if (isClickable)
                const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: AppTheme.blue600,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
