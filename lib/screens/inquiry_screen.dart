import 'package:Texspin/bloc/inqueiry/bloc/inqueiry_bloc.dart';
import 'package:Texspin/bloc/inqueiry/bloc/inqueiry_event.dart';
import 'package:Texspin/bloc/inqueiry/bloc/inqueiry_state.dart';
import 'package:Texspin/services/api_service.dart';
import 'package:Texspin/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Texspin/screens/create_project_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';

class InquiryScreen extends StatefulWidget {
  final VoidCallback onCancel;
  InquiryScreen({super.key, required this.onCancel});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  late final InquiryBloc _bloc;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bloc = InquiryBloc(apiService: ApiService())..add(FetchInquiries());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Inquiries')),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: widget.onCancel,
          color: AppTheme.gray900,
        ),
        title: const Text(
          'Inquiries',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
        ),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<InquiryBloc, InquiryState>(
          builder: (context, state) {
            if (state is InquiryLoading || state is InquiryInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is InquiryError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () {
                          context.read<InquiryBloc>().add(FetchInquiries());
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is InquiryLoaded) {
              final inquiries = state.inquiries;

              final filteredInquiries = inquiries.where((item) {
                if (_searchQuery.isEmpty) return true;

                final Map<String, dynamic> data = item is Map<String, dynamic>
                    ? item
                    : <String, dynamic>{};

                final createdByRaw = data['createdBy'];
                final Map<String, dynamic> createdBy =
                    createdByRaw is Map<String, dynamic>
                    ? createdByRaw
                    : <String, dynamic>{};

                final firstName = (createdBy['firstName'] ?? '')
                    .toString()
                    .toLowerCase();
                final lastName = (createdBy['lastName'] ?? '')
                    .toString()
                    .toLowerCase();
                final fullName = ('$firstName $lastName').trim();

                final customerName =
                    (data['description'] ?? data['customerName'] ?? '')
                        .toString()
                        .toLowerCase();
                final query = _searchQuery.toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                return firstName.contains(query) ||
                    lastName.contains(query) ||
                    fullName.contains(query) ||
                    customerName.contains(query);
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomTextInput(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      hint: 'Search by Staff or Customer...',
                      suffixIcon: const Icon(Icons.search),
                    ),
                  ),
                  Expanded(
                    child: filteredInquiries.isEmpty
                        ? Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.all(48),
                              margin: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 3),
                                    color: Colors.black.withOpacity(0.05),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _searchQuery.isEmpty
                                        ? Icons.inbox_outlined
                                        : Icons.search_off,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No Inquiries Found'
                                        : 'No Inquiries Found',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'There are no inquiries at the moment.'
                                        : 'Try adjusting your search terms.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: CustomButton(
                                        text: 'Clear Filter',
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _searchController.clear();
                                          });
                                        },
                                        variant: ButtonVariant.outline,
                                        size: ButtonSize.lg,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              int crossAxisCount;
                              if (width < 600) {
                                crossAxisCount = 1; // mobile
                              } else if (width < 1024) {
                                crossAxisCount = 2; // tablet
                              } else if (width < 1400) {
                                crossAxisCount = 3; // small web/laptop
                              } else {
                                crossAxisCount = 4; // large web
                              }

                              final filteredInquiriesList = filteredInquiries
                                  .map((item) => item as Map<String, dynamic>)
                                  .toList();

                              // FIXED: Use Expanded in Row-based ListView for non-mobile (replaces Wrap + SizedBox)
                              if (crossAxisCount == 1) {
                                return ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredInquiriesList.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: _InquiryCard(
                                        data: filteredInquiriesList[index],
                                      ),
                                    );
                                  },
                                );
                              }

                              // Non-mobile: Row-based grid with Expanded cards
                              final int numRows =
                                  (filteredInquiriesList.length +
                                      crossAxisCount -
                                      1) ~/
                                  crossAxisCount;

                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: numRows,
                                itemBuilder: (context, rowIndex) {
                                  final int startIndex =
                                      rowIndex * crossAxisCount;
                                  final int endIndex =
                                      (startIndex + crossAxisCount).clamp(
                                        0,
                                        filteredInquiriesList.length,
                                      );
                                  final List<Map<String, dynamic>> rowItems =
                                      filteredInquiriesList.sublist(
                                        startIndex,
                                        endIndex,
                                      );

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start, // Aligns tops; heights dynamic per card
                                      children: rowItems.asMap().entries.map((
                                        entry,
                                      ) {
                                        final int colIndex = entry.key;
                                        final Map<String, dynamic> data =
                                            entry.value;
                                        return Flexible(
                                          // Changed to Flexible to allow shrinking
                                          child: ConstrainedBox(
                                            // Added width cap to prevent stretching
                                            constraints: const BoxConstraints(
                                              maxWidth: 450,
                                            ), // Increased to 450px for better "Created on" display
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right:
                                                    colIndex <
                                                        crossAxisCount - 1
                                                    ? 16.0
                                                    : 0.0,
                                              ),
                                              child: _InquiryCard(data: data),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _InquiryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final createdBy = (data['createdBy'] ?? {}) as Map<String, dynamic>;
    final firstName = (createdBy['firstName'] ?? '').toString();
    final lastName = (createdBy['lastName'] ?? '').toString();
    final createdByFullName = '$firstName $lastName'.trim();

    final customerName = (data['description'] ?? '').toString();
    final createdDateStr =
        (data['createdDate'] ?? DateTime.now().toIso8601String()).toString();

    DateTime createdDate;
    try {
      createdDate = DateTime.parse(createdDateStr);
    } catch (e) {
      createdDate = DateTime.now();
    }

    final formattedDate = DateFormat('MMM d, yyyy').format(createdDate);

    final fileName = (data['fileName'] ?? '').toString();
    final viewUrl = (data['viewUrl'] ?? '').toString();

    final isMobile = MediaQuery.of(context).size.width < 600;
    final double sectionSpacing = isMobile ? 12.0 : 16.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      child: Container(
        width: double.infinity, // Fills the Expanded width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              blurRadius: isMobile ? 6 : 10,
              spreadRadius: isMobile ? 1 : 2,
              offset: const Offset(0, 3),
              color: Colors.black.withOpacity(0.09),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Dynamic height to content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP NAME + DELETE ICON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: isMobile ? 20 : 24,
                    color: Colors.red.shade400,
                  ),
                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final inquiryId = data['id']?.toString() ?? '';
                    if (inquiryId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid inquiry ID')),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Inquiry'),
                        content: const Text(
                          'Are you sure you want to delete this inquiry? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.read<InquiryBloc>().add(
                                DeleteInquiry(inquiryId),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Inquiry deleted'),
                                ),
                              );
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: sectionSpacing),

            // CREATED BY + CREATED ON (Enhanced with Expanded for even distribution)
            if (isMobile)
              // Mobile: Compact Row with flexible spacing
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          // Nested Expanded for text balance
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Created by",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                createdByFullName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Created on",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              // Non-Mobile: Full Row with balanced Expanded
              Row(
                children: [
                  Expanded(
                    flex: 2, // More space for name
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Created by",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                createdByFullName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Created on",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            SizedBox(height: sectionSpacing),

            // FILE BOX
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              ),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 36 : 40,
                    height: isMobile ? 36 : 40,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      size: isMobile ? 20 : 24,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            // BUTTONS (Already uses Expanded in Row for non-mobile)
            if (isMobile)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Create Project',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateProjectScreen(
                              onSave: (project) {
                                // Handle project creation success
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Project created successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              onCancel: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.lg,
                      icon: const Icon(
                        Icons.add_task,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Download',
                      onPressed: () {
                        launchUrl(
                          Uri.parse("${ApiService.baseUrl}$viewUrl"),
                          mode: LaunchMode.inAppWebView,
                        );
                      },
                      size: ButtonSize.lg,
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Create Project',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateProjectScreen(
                              onSave: (project) {
                                // Handle project creation success
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Project created successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              onCancel: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.lg,
                      icon: const Icon(
                        Icons.add_task,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Download',
                      onPressed: () {
                        launchUrl(
                          Uri.parse("${ApiService.baseUrl}$viewUrl"),
                          mode: LaunchMode.inAppWebView,
                        );
                      },
                      size: ButtonSize.lg,
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
