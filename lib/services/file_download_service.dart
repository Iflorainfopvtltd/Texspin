import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:developer' as developer;

class FileDownloadService {
  static final Dio _dio = Dio();

  /// Downloads a file from the given URL and saves it to the device
  static Future<String> downloadFile({
    required String url,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Get the appropriate directory for downloads
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Try to get the Downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For desktop platforms
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Ensure the filename has proper extension
      String finalFileName = fileName;
      if (!fileName.contains('.')) {
        // Try to extract extension from URL
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final lastSegment = pathSegments.last;
          if (lastSegment.contains('.')) {
            final extension = lastSegment.split('.').last;
            finalFileName = '$fileName.$extension';
          }
        }
      }

      // Create the full file path
      final filePath = '${directory.path}/$finalFileName';
      
      // Check if file already exists and create a unique name if needed
      String uniqueFilePath = filePath;
      int counter = 1;
      while (await File(uniqueFilePath).exists()) {
        final nameWithoutExt = finalFileName.split('.').first;
        final extension = finalFileName.contains('.') ? '.${finalFileName.split('.').last}' : '';
        uniqueFilePath = '${directory.path}/${nameWithoutExt}_($counter)$extension';
        counter++;
      }

      developer.log('Downloading file to: $uniqueFilePath');

      // Download the file
      await _dio.download(
        url,
        uniqueFilePath,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      developer.log('File downloaded successfully: $uniqueFilePath');
      return uniqueFilePath;
    } catch (e) {
      developer.log('Error downloading file: $e');
      rethrow;
    }
  }

  /// Opens the file with the default system application
  static Future<void> openFile(String filePath) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, we can use url_launcher or open_file package
        // For now, we'll just show the file location
        developer.log('File saved at: $filePath');
      } else {
        // For desktop platforms
        if (Platform.isWindows) {
          await Process.run('explorer', ['/select,', filePath]);
        } else if (Platform.isMacOS) {
          await Process.run('open', ['-R', filePath]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [File(filePath).parent.path]);
        }
      }
    } catch (e) {
      developer.log('Error opening file: $e');
    }
  }

  /// Gets a human-readable file size string
  static String getFileSizeString(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Checks if the app has storage permission
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      return await Permission.storage.isGranted;
    }
    return true; // iOS and other platforms don't need explicit storage permission for app documents
  }

  /// Requests storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }
}