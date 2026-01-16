import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

class ExcelExportService {
  static Future<String?> exportProjectToExcel(Project project) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Define Styles
      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString("#E0E0E0"),
      );

      CellStyle titleStyle = CellStyle(
        bold: true,
        fontSize: 18,
        horizontalAlign: HorizontalAlign.Center,
      );

      CellStyle labelStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
      );

      CellStyle valueStyle = CellStyle(horizontalAlign: HorizontalAlign.Left);

      CellStyle centeredValueStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
      );

      // Title
      var titleCell = sheetObject.cell(CellIndex.indexByString("A1"));
      titleCell.value = TextCellValue('APQP Project Report');
      titleCell.cellStyle = titleStyle;
      sheetObject.merge(
        CellIndex.indexByString("A1"),
        CellIndex.indexByString("H1"),
      );

      // Project Details - 2 Column Layout
      int infoStartRow = 3;

      // Left Column Data
      final leftInfo = [
        ['Customer', project.customerName],
        ['Location', project.location],
        ['Part Name', project.partName],
        ['Part Number', project.partNumber],
        ['Plan Number', project.planNumber],
      ];

      // Right Column Data
      final rightInfo = [
        ['Revision', '${project.revisionNumber} (${project.revisionDate})'],
        ['Team Leader', project.teamLeader],
        ['Date of Issue', project.dateOfIssue],
        ['Total Weeks', '${project.totalWeeks}'],
        ['Progress', '${project.progress}%'],
      ];

      // Draw Left Info Table
      for (int i = 0; i < leftInfo.length; i++) {
        var row = infoStartRow + i;

        // Label
        var labelCell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        );
        labelCell.value = TextCellValue(leftInfo[i][0]);
        labelCell.cellStyle = labelStyle; // bold left align

        // Value
        var valueCell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
        );
        valueCell.value = TextCellValue(leftInfo[i][1]);
        valueCell.cellStyle = valueStyle;
      }

      // Draw Right Info Table (Starting at Column 5 - F)
      for (int i = 0; i < rightInfo.length; i++) {
        var row = infoStartRow + i;

        // Label
        var labelCell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
        );
        labelCell.value = TextCellValue(rightInfo[i][0]);
        labelCell.cellStyle = labelStyle;

        // Value
        var valueCell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
        );
        valueCell.value = TextCellValue(rightInfo[i][1]);
        valueCell.cellStyle = valueStyle;
      }

      // Add borders for info tables (Optional visual improvement)
      // Note: excel package border API might be verbose, keeping simple styles for now.

      int currentRow = infoStartRow + leftInfo.length + 3;

      // Gantt Headers
      List<String> fixedHeaders = [
        'Phase',
        'Activity',
        'Responsible',
        'Appr. Member',
        'Technical Remarks',
        'Acceptance Status',
        'Review Date',
        'Status',
      ];

      // Write Fixed Headers
      for (int i = 0; i < fixedHeaders.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
        );
        cell.value = TextCellValue(fixedHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      // Write Week Headers
      int weekCount = project.totalWeeks > 0 ? project.totalWeeks : 20;
      for (int i = 1; i <= weekCount; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(
            columnIndex: fixedHeaders.length + i - 1,
            rowIndex: currentRow,
          ),
        );
        cell.value = TextCellValue('W$i');
        cell.cellStyle = headerStyle;
      }
      currentRow++;

      // Data Rows
      for (var phase in project.phases) {
        for (var activity in phase.activities) {
          // Phase
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
            )
            ..value = TextCellValue(phase.name)
            ..cellStyle = valueStyle;

          // Activity
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
            )
            ..value = TextCellValue(activity.name)
            ..cellStyle = valueStyle;

          // Responsible
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
            )
            ..value = TextCellValue(activity.responsiblePerson)
            ..cellStyle = centeredValueStyle;

          // Appr Member
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
            )
            ..value = TextCellValue(activity.approvingStaff ?? '')
            ..cellStyle = centeredValueStyle;

          // Technical Remarks
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
            )
            ..value = TextCellValue(activity.technicalRemarks ?? '')
            ..cellStyle = centeredValueStyle;

          // Acceptance Status
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
            )
            ..value = TextCellValue(activity.approvalStatus ?? '')
            ..cellStyle = centeredValueStyle;

          // Review Date
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
            )
            ..value = TextCellValue(_formatReviewDate(activity.reviewDate))
            ..cellStyle = centeredValueStyle;

          // Status
          sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
            )
            ..value = TextCellValue(activity.status.displayName)
            ..cellStyle = centeredValueStyle;

          // Fill week columns with Color
          CellStyle statusColorStyle = _getStatusColorStyle(activity.status);

          for (int i = 1; i <= weekCount; i++) {
            var colIndex = fixedHeaders.length + i - 1;
            var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: currentRow,
              ),
            );

            if (i >= activity.startWeek && i <= activity.endWeek) {
              cell.cellStyle = statusColorStyle;
              cell.value = TextCellValue(''); // Empty text, just color
            } else {
              cell.value = TextCellValue('');
              cell.cellStyle = centeredValueStyle;
            }
          }
          currentRow++;
        }
      }

      // Auto-fit is not natively fully supported in basic excel package creation often,
      // but we can set default width if needed. Leaving as default for now.

      // Save file
      final fileBytes = excel.save();
      if (fileBytes == null) return null;

      // Web Platform Check
      if (kIsWeb) {
        // Platform.is... throws on Web, so we must return early.
        // For actual Web download, we would need a different approach (e.g. anchor tag).
        // Since no web-specific download package is currently set up, we just return to avoid crash.
        return null;
      }

      // Mobile/Desktop Logic
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Project Excel',
          fileName: '${project.partName}_Report.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          return outputFile;
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        if (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted) {
          final directory = await getExternalStorageDirectory();
          final path =
              '${directory?.path}/${project.partName.replaceAll(' ', '_')}_Report.xlsx';
          File(path)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          return path;
        }
      }
      return null;
    } catch (e) {
      developer.log('Error exporting Excel: $e');
      rethrow;
    }
  }

  static String _formatReviewDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw);
      // Format as "yyyy-MM-dd HH:mm" or similar, here using a simpler format like "yyyy-MM-dd"
      return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  static CellStyle _getStatusColorStyle(ActivityStatus status) {
    String hexColor;
    switch (status) {
      case ActivityStatus.notStarted:
        hexColor = "#EF4444"; // Red
        break;
      case ActivityStatus.pending:
        hexColor = "#EF4444"; // Red (Same as Not Started)
        break;
      case ActivityStatus.inProgress:
        hexColor = "#EAB308"; // Yellow
        break;
      case ActivityStatus.submitted:
        hexColor = "#EAB308"; // Yellow (Same as In Progress)
        break;
      case ActivityStatus.completed:
        hexColor = "#22C55E"; // Green
        break;
    }

    return CellStyle(
      backgroundColorHex: ExcelColor.fromHexString(hexColor),
      horizontalAlign: HorizontalAlign.Center,
    );
  }
}
