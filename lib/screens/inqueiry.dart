
// import 'package:convert2dart/bloc/inqueiry/bloc/inqueiry_bloc.dart';
// import 'package:convert2dart/bloc/inqueiry/bloc/inqueiry_event.dart';
// import 'package:convert2dart/bloc/inqueiry/bloc/inqueiry_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class InquiryScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // Assume bloc is provided via BlocProvider
//     return Scaffold(
//       appBar: AppBar(title: Text('Inquiries')),
//       body: BlocBuilder<InquiryBloc, InquiryState>(
//         builder: (context, state) {
//           if (state is InquiryLoading) {
//             return Center(child: CircularProgressIndicator());
//           } else if (state is InquiryError) {
//             return Center(child: Text('Error: ${state.message}'));
//           } else if (state is InquiryLoaded) {
//             return ResponsiveInquiryList(inquiries: state.inquiries);
//           }
//           return Center(
//             child: ElevatedButton(
//               onPressed: () =>
//                   context.read<InquiryBloc>().add(FetchInquiries()),
//               child: Text('Load Inquiries'),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class ResponsiveInquiryList extends StatelessWidget {
//   final List<dynamic> inquiries;

//   const ResponsiveInquiryList({Key? key, required this.inquiries})
//     : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isMobile = screenWidth < 600;
//     final isTablet = screenWidth >= 600 && screenWidth < 1200;
//     final isWebOrDesktop = screenWidth >= 1200;

//     if (isMobile) {
//       // Mobile: Vertical ListView
//       return ListView.builder(
//         padding: EdgeInsets.all(8.0),
//         itemCount: inquiries.length,
//         itemBuilder: (context, index) => InquiryCard(inquiry: inquiries[index]),
//       );
//     } else if (isTablet) {
//       // Tablet: 2-column Grid
//       return Padding(
//         padding: EdgeInsets.all(16.0),
//         child: GridView.builder(
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             childAspectRatio: 3,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//           ),
//           itemCount: inquiries.length,
//           itemBuilder: (context, index) =>
//               InquiryCard(inquiry: inquiries[index]),
//         ),
//       );
//     } else {
//       // Web/Desktop: 3-column Grid
//       return Padding(
//         padding: EdgeInsets.all(16.0),
//         child: GridView.builder(
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3,
//             childAspectRatio: 3,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//           ),
//           itemCount: inquiries.length,
//           itemBuilder: (context, index) =>
//               InquiryCard(inquiry: inquiries[index]),
//         ),
//       );
//     }
//   }
// }

// // Card Widget for each Inquiry
// class InquiryCard extends StatelessWidget {
//   final dynamic inquiry;

//   const InquiryCard({Key? key, required this.inquiry}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final customerName = inquiry['customerName'] as String? ?? 'N/A';
//     final description = inquiry['description'] as String? ?? 'No description';
//     final fileName = inquiry['fileName'] as String? ?? 'No file';
//     final fileUrl = inquiry['fileUrl'] as String? ?? 'No URL';
//     final createdBy = inquiry['createdBy'] as Map<String, dynamic>?;
//     final firstName = createdBy?['firstName'] as String? ?? '';
//     final lastName = createdBy?['lastName'] as String? ?? '';
//     final fullName = '$firstName $lastName'.trim();

//     return Card(
//       elevation: 4,
//       margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
//       child: Padding(
//         padding: EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               customerName,
//               style: Theme.of(
//                 context,
//               ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             Expanded(
//               child: Text(
//                 description,
//                 style: Theme.of(context).textTheme.bodyMedium,
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(Icons.description, size: 20, color: Colors.grey[600]),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'File: $fileName',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       ElevatedButton(
//                         onPressed: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text('Preview: $fileUrl')),
//                           );
//                         },
//                         child: Text('Preview'),
//                         style: ElevatedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Created by: $fullName',
//               style: Theme.of(
//                 context,
//               ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
