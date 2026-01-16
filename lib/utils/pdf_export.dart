import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class PdfExportService {
  // static const _weekCount = 20;

  static Future<void> exportProjectToPdf(Project project) async {
    final pdf = pw.Document();
    final weekCount = project.totalWeeks > 0 ? project.totalWeeks : 1;

    // Calculate dynamic weeks per page based on available width
    final weeksPerPage = _calculateWeeksPerPage();

    // First page with title and project details
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (_) => [
          _buildTitle(project),
          pw.SizedBox(height: 12),
          _buildProjectDetailsSection(project),
          pw.SizedBox(height: 18),
          _buildGanttTable(project, 0, weeksPerPage, weekCount),
          pw.SizedBox(height: 12),
          _buildStatusLegend(),
        ],
      ),
    );

    // Additional pages for remaining weeks
    int startWeek = weeksPerPage + 1;
    while (startWeek <= weekCount) {
      final endWeek = (startWeek + weeksPerPage - 1).clamp(0, weekCount);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (_) => [
            _buildTitle(project),
            pw.SizedBox(height: 12),
            pw.Text(
              'Gantt Chart - Weeks $startWeek to $endWeek',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            _buildGanttTable(project, startWeek - 1, endWeek, weekCount),
            pw.SizedBox(height: 12),
            _buildStatusLegend(),
          ],
        ),
      );
      startWeek = endWeek + 1;
    }

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static int _calculateWeeksPerPage() {
    // A3 landscape: 420mm width
    // Margins: 16mm each side = 32mm total
    // Available width: 420 - 32 = 388mm
    const a3LandscapeWidth = 420.0; // mm
    const marginTotal = 32.0; // 16mm each side
    const availableWidth = a3LandscapeWidth - marginTotal;

    // Fixed column widths (in mm, converted from points)
    const phaseWidth = 80.0 / 2.834; // ~28mm
    const activityWidth = 150.0 / 2.834; // ~53mm
    const respWidth = 100.0 / 2.834; // ~35mm
    const approvalWidth = 110.0 / 2.834; // ~39mm
    const remarksWidth = 100.0 / 2.834; // ~35mm
    const acceptanceWidth = 90.0 / 2.834; // ~32mm
    const reviewWidth = 90.0 / 2.834; // ~32mm
    const statusWidth = 80.0 / 2.834; // ~28mm
    const weekWidth = 26.0 / 2.834; // ~9mm per week

    final fixedColumnsWidth =
        phaseWidth +
        activityWidth +
        respWidth +
        approvalWidth +
        remarksWidth +
        acceptanceWidth +
        reviewWidth +
        statusWidth;

    final remainingWidth = availableWidth - fixedColumnsWidth;
    final maxWeeks = (remainingWidth / weekWidth).floor();

    // Ensure at least 8 weeks, max 20 weeks per page
    return maxWeeks.clamp(8, 20);
  }

  static pw.Widget _buildTitle(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'APQP Project Report - Gantt Chart',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Project: ${project.partName}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProjectDetailsSection(Project project) {
    final fmt = DateFormat('MMM dd, yyyy');
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
    final inProgressActivities = project.phases.fold<int>(
      0,
      (sum, phase) =>
          sum +
          phase.activities
              .where((a) => a.status == ActivityStatus.inProgress)
              .length,
    );

    pw.Widget detailCell(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Project Summary',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: detailCell('Customer', project.customerName)),
              pw.Expanded(child: detailCell('Location', project.location)),
              pw.Expanded(child: detailCell('Part Number', project.partNumber)),
              pw.Expanded(
                child: detailCell(
                  'Plan Number',
                  project.planNumber.isEmpty ? 'N/A' : project.planNumber,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(child: detailCell('Team Leader', project.teamLeader)),
              pw.Expanded(
                child: detailCell(
                  'Date of Issue',
                  fmt.format(DateTime.parse(project.dateOfIssue)),
                ),
              ),
              pw.Expanded(
                child: detailCell('Total Weeks', '${project.totalWeeks} weeks'),
              ),
              pw.Expanded(
                child: detailCell(
                  'Total Phases',
                  '${project.phases.length} phases',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: detailCell('Progress', '${project.progress}%'),
              ),
              pw.Expanded(
                child: detailCell('Total Activities', '$totalActivities'),
              ),
              pw.Expanded(
                child: detailCell('Completed', '$completedActivities'),
              ),
              pw.Expanded(
                child: detailCell('In Progress', '$inProgressActivities'),
              ),
            ],
          ),
          if (project.teamMembers.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Team Members',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  project.teamMembers.join(', '),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // static pw.Widget _buildHeaderTable(Project project) {
  //   final fmt = DateFormat('MMM dd, yyyy');
  //   final revision = _formatRevision(project, fmt);
  //   final issue = _formatDate(project.dateOfIssue, fmt);
  //   final members = project.teamMembers.isEmpty
  //       ? '—'
  //       : project.teamMembers.join(', ');

  //   pw.Widget headerCell(String label, String value) {
  //     return pw.Container(
  //       padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
  //       decoration: pw.BoxDecoration(
  //         border: pw.Border.all(color: PdfColors.black, width: 0.8),
  //       ),
  //       child: pw.Column(
  //         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //         children: [
  //           pw.Text(
  //             label,
  //             style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
  //           ),
  //           pw.SizedBox(height: 2),
  //           pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
  //         ],
  //       ),
  //     );
  //   }

  //   return pw.Table(
  //     columnWidths: const {
  //       0: pw.FlexColumnWidth(),
  //       1: pw.FlexColumnWidth(),
  //       2: pw.FlexColumnWidth(),
  //       3: pw.FlexColumnWidth(),
  //       4: pw.FlexColumnWidth(),
  //     },
  //     children: [
  //       pw.TableRow(
  //         children: [
  //           headerCell('Customer', project.customerName),
  //           headerCell('Location', project.location),
  //           headerCell('Part Name', project.partName),
  //           headerCell('Part Number', project.partNumber),
  //           headerCell('Revision Number and Date', revision),
  //         ],
  //       ),
  //       pw.TableRow(
  //         children: [
  //           headerCell('Team Leader', project.teamLeader),
  //           headerCell('Team Members', members),
  //           headerCell('Plan Number', project.planNumber),
  //           headerCell('Date of Issue', issue),
  //           headerCell(
  //             'Team Leader Authorization',
  //             project.teamLeader,
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  static pw.Widget _buildGanttTable(
    Project project,
    int startWeekIndex,
    int endWeek,
    int totalWeeks,
  ) {
    const phaseWidth = 80.0;
    const activityWidth = 150.0;
    const respWidth = 100.0;
    const approvalWidth = 110.0;
    const weekWidth = 26.0;
    const remarksWidth = 100.0;
    const acceptanceWidth = 90.0;
    const reviewWidth = 90.0;
    const statusWidth = 80.0;
    const rowHeight = 22.0;

    final displayWeekCount = endWeek - startWeekIndex;
    final rows = <pw.Widget>[];

    // Header row
    rows.add(
      pw.Row(
        children: [
          _headerCell('Phase', width: phaseWidth),
          _headerCell('Activity', width: activityWidth),
          _headerCell('Responsible', width: respWidth),
          _headerCell('Appr. member', width: approvalWidth),
          _headerCell('Week Number', width: weekWidth * displayWeekCount),
          _headerCell('Remarks', width: remarksWidth),
          _headerCell('Acce. Status', width: acceptanceWidth),
          _headerCell('Review Date', width: reviewWidth),
          _headerCell('Status', width: statusWidth),
        ],
      ),
    );

    // Week numbers row
    rows.add(
      pw.Row(
        children: [
          _emptyCell(width: phaseWidth),
          _emptyCell(width: activityWidth),
          _emptyCell(width: respWidth),
          _emptyCell(width: approvalWidth),
          pw.Row(
            children: List.generate(
              displayWeekCount,
              (i) => _headerCell('${startWeekIndex + i + 1}', width: weekWidth),
            ),
          ),
          _emptyCell(width: remarksWidth),
          _emptyCell(width: acceptanceWidth),
          _emptyCell(width: reviewWidth),
          _emptyCell(width: statusWidth),
        ],
      ),
    );

    // Data rows with rowspan support
    for (final phase in project.phases) {
      if (phase.activities.isEmpty) continue;

      final totalActivitiesInPhase = phase.activities.length;
      final phaseRowHeight = rowHeight * totalActivitiesInPhase;

      // Build phase cell with rowspan effect
      final phaseCell = pw.Container(
        width: phaseWidth,
        height: phaseRowHeight,
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          phase.name,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      );

      // Build activities column
      final activitiesColumn = pw.Column(
        children: List.generate(totalActivitiesInPhase, (i) {
          final activity = phase.activities[i];
          return pw.Row(
            children: [
              _bodyCellWithBorder(
                activity.name,
                width: activityWidth,
                height: rowHeight,
              ),
              _bodyCellWithBorder(
                activity.responsiblePerson.isEmpty
                    ? 'Team'
                    : activity.responsiblePerson,
                width: respWidth,
                height: rowHeight,
                align: pw.Alignment.center,
              ),
              _bodyCellWithBorder(
                activity.approvingStaff ?? '—',
                width: approvalWidth,
                height: rowHeight,
                align: pw.Alignment.center,
              ),
              pw.Row(
                children: List.generate(displayWeekCount, (weekIndex) {
                  final week = startWeekIndex + weekIndex + 1;
                  final active =
                      week >= activity.startWeek && week <= activity.endWeek;
                  return pw.Container(
                    width: weekWidth,
                    height: rowHeight,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.4),
                      color: active
                          ? _statusColor(activity.status)
                          : PdfColors.white,
                    ),
                  );
                }),
              ),
              _bodyCellWithBorder(
                activity.technicalRemarks ?? '—',
                width: remarksWidth,
                height: rowHeight,
                align: pw.Alignment.center,
              ),
              _bodyCellWithBorder(
                activity.approvalStatus ?? '—',
                width: acceptanceWidth,
                height: rowHeight,
                align: pw.Alignment.center,
              ),
              _bodyCellWithBorder(
                _formatReviewDate(activity.reviewDate),
                width: reviewWidth,
                height: rowHeight,
                align: pw.Alignment.center,
              ),
              _bodyCellWithBorder(
                activity.status.displayName,
                width: statusWidth,
                height: rowHeight,
                align: pw.Alignment.center,
              ),
            ],
          );
        }),
      );

      // Combine phase cell with activities
      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [phaseCell, activitiesColumn],
        ),
      );
    }

    return pw.Column(children: rows);
  }

  static PdfColor _statusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.notStarted:
        return PdfColors.red300; // Red for not started
      case ActivityStatus.pending:
        return PdfColors.red300; // Red for pending
      case ActivityStatus.inProgress:
        return PdfColors.yellow300; // Yellow for in progress
      case ActivityStatus.submitted:
        return PdfColors.yellow300; // Yellow for submitted
      case ActivityStatus.completed:
        return PdfColors.green300; // Green for completed
    }
  }

  static pw.Widget _buildStatusLegend() {
    pw.Widget legendItem(String label, PdfColor color) {
      return pw.Row(
        children: [
          pw.Container(
            width: 16,
            height: 16,
            decoration: pw.BoxDecoration(
              color: color,
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ],
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Status Legend',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: legendItem('Not Started', PdfColors.red300)),
              pw.Expanded(
                child: legendItem('In Progress', PdfColors.yellow300),
              ),
              pw.Expanded(child: legendItem('Completed', PdfColors.green300)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRevision(Project project, DateFormat fmt) {
    if (project.revisionNumber.isEmpty) return 'N/A';
    if (project.revisionDate.isEmpty) return project.revisionNumber;
    try {
      return '${project.revisionNumber} (${fmt.format(DateTime.parse(project.revisionDate))})';
    } catch (_) {
      return project.revisionNumber;
    }
  }

  static String _formatDate(String raw, DateFormat fmt) {
    if (raw.isEmpty) return 'N/A';
    try {
      return fmt.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _formatReviewDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  static final _headerStyle = pw.TextStyle(
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  static final _headerBoxDecoration = pw.BoxDecoration(
    color: PdfColors.grey300,
    border: pw.Border.all(color: PdfColors.black, width: 0.9),
  );

  static pw.Widget _headerCell(String text, {required double width}) =>
      pw.Container(
        width: width,
        padding: const pw.EdgeInsets.all(5),
        decoration: _headerBoxDecoration,
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: _headerStyle,
          textAlign: pw.TextAlign.center,
        ),
      );

  static pw.Widget _emptyCell({required double width, double height = 22}) =>
      pw.Container(
        width: width,
        height: height,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.4),
        ),
      );

  static pw.Widget _bodyCell(
    String text, {
    required double width,
    required double height,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) => pw.Container(
    width: width,
    height: height,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4),
    alignment: align,
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
  );

  static pw.Widget _bodyCellWithBorder(
    String text, {
    required double width,
    required double height,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) => pw.Container(
    width: width,
    height: height,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4),
    alignment: align,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 0.5),
    ),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
  );
}
