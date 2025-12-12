# Department Task Management System

## Overview
A comprehensive department task management system with responsive design, file download capabilities, and status-based workflow management.

## 🚀 Features

### ✅ **Complete API Integration**
- **GET** `/texspin/api/department-task` - Fetch all department tasks
- **POST** `/texspin/api/department-task` - Create new department task
- **PUT** `/texspin/api/department-task/:id/review` - Accept/Reject tasks
- **DELETE** `/texspin/api/department-task/:id` - Delete department task
- **PUT** `/texspin/api/department-task/:id/reassign` - Reassign rejected tasks

### 📱 **Responsive UI Design**
- **Mobile**: Full-screen grid view with card layout
- **Desktop/Tablet**: Dialog-based table view with search and filters
- **Adaptive**: Automatically switches based on screen width (600px breakpoint)

### 📊 **Status Management**
Supports all 5 status types with appropriate actions:
- **Pending**: Edit, Delete
- **Accepted**: View, Download (if files available)
- **Submitted**: Download, Accept, Reject
- **Completed**: View, Download (if files available)
- **Rejected**: Reassign, Delete

### 📁 **File Download System**
- **Proper file naming**: Downloads with original filenames and extensions
- **Storage permissions**: Automatic permission handling for Android/iOS
- **Cross-platform**: Works on Android, iOS, Windows, macOS, Linux
- **Progress tracking**: Shows download progress and completion status
- **File location**: Saves to Downloads folder (Android) or Documents (iOS)

## 🏗️ **Architecture**

### **Models**
```dart
class DepartmentTask {
  final String id;
  final String name;
  final String description;
  final String deadline;
  final Map<String, dynamic> assignedStaff;
  final Map<String, dynamic> createdBy;
  final String status;
  final String? fileName;
  final String? downloadUrl;
  // ... other fields
}
```

### **API Service Methods**
```dart
// Get all department tasks
Future<Map<String, dynamic>> getDepartmentTasks()

// Create new department task
Future<Map<String, dynamic>> createDepartmentTask({
  required String name,
  required String description,
  required String deadline,
  required String assignedStaffId,
})

// Review task (accept/reject)
Future<Map<String, dynamic>> reviewDepartmentTask({
  required String taskId,
  required String status, // 'completed' or 'rejected'
  String? rejectionReason,
})

// Reassign rejected task
Future<Map<String, dynamic>> reassignDepartmentTask({
  required String taskId,
  required String assignedStaffId,
  required String deadline,
})

// Delete department task
Future<Map<String, dynamic>> deleteDepartmentTask({
  required String taskId,
})
```

## 🎯 **User Interface Components**

### **1. Department Task Card (`DepartmentTaskCard`)**
- **Compact & Full modes**: Adapts to grid layout requirements
- **Status-based actions**: Shows relevant buttons based on task status
- **File download**: Integrated download functionality
- **Responsive design**: Works on all screen sizes

### **2. Grid Screen (`DepartmentTaskGridScreen`)**
- **Mobile-first**: Full-screen experience for mobile devices
- **Search & Filter**: Real-time search and status-based filtering
- **Responsive grid**: 1-3 columns based on screen width
- **Pull-to-refresh**: Swipe down to refresh task list

### **3. Management Dialog (`DepartmentTaskManagementDialog`)**
- **Table view**: Comprehensive table layout for desktop/tablet
- **Search functionality**: Filter tasks by name or staff
- **Bulk actions**: Efficient task management
- **Modal design**: Overlay dialog for desktop experience

## 🔄 **Workflow Management**

### **Task Creation Flow**
1. Manager creates department task
2. Assigns to staff member with deadline
3. Task status: `pending`

### **Task Execution Flow**
1. Staff receives task (`pending`)
2. Staff accepts task → `accepted`
3. Staff works on task and submits → `submitted`
4. Manager reviews submission:
   - **Accept** → `completed`
   - **Reject** → `rejected`

### **Rejection & Reassignment Flow**
1. Task rejected by manager → `rejected`
2. Manager can reassign to different staff
3. New staff receives task as `pending`
4. Process repeats

## 📲 **Navigation Integration**

### **Manager Dashboard**
```dart
NavigationItem(
  icon: Icons.business,
  label: 'Department Tasks',
  onTap: () {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      // Mobile: Full-screen grid
      Navigator.push(context, DepartmentTaskGridScreen());
    } else {
      // Desktop: Dialog table view
      showDialog(context, DepartmentTaskManagementDialog());
    }
  },
)
```

## 🎨 **Status-Based UI Elements**

### **Status Colors**
- **Pending**: Yellow (`AppTheme.yellow500`)
- **Accepted**: Green (`AppTheme.green500`)
- **Submitted**: Blue (`AppTheme.blue500`)
- **Completed**: Green (`AppTheme.green500`)
- **Rejected**: Red (`AppTheme.red500`)

### **Action Buttons by Status**

#### **Submitted Tasks**
- 🔽 **Download** (if file available)
- ✅ **Accept** → Changes status to `completed`
- ❌ **Reject** → Changes status to `rejected` (requires reason)

#### **Rejected Tasks**
- 👥 **Reassign** → Assign to different staff with new deadline
- 🗑️ **Delete** → Remove task permanently

#### **Pending Tasks**
- ✏️ **Edit** → Modify task details
- 🗑️ **Delete** → Remove task

#### **Other Statuses**
- 🔽 **Download** (if file available)
- 👁️ **View** → Read-only access

## 🔧 **File Download Implementation**

### **Download Process**
1. **Permission Check**: Verify storage permissions
2. **URL Construction**: `ApiService.baseUrl + task.downloadUrl`
3. **File Download**: Use `FileDownloadService` for proper saving
4. **User Feedback**: Progress indicators and completion messages
5. **File Opening**: Option to open downloaded files

### **Example Download Flow**
```dart
// Check permissions
if (!await FileDownloadService.hasStoragePermission()) {
  await FileDownloadService.requestStoragePermission();
}

// Download file
final filePath = await FileDownloadService.downloadFile(
  url: ApiService.baseUrl + task.downloadUrl!,
  fileName: task.fileName ?? 'department_task_file',
  onProgress: (received, total) {
    // Show progress
  },
);

// Show success message with file location
ScaffoldMessenger.showSnackBar(
  SnackBar(
    content: Text('File downloaded: ${filePath.split('/').last}'),
    action: SnackBarAction(
      label: 'Open',
      onPressed: () => FileDownloadService.openFile(filePath),
    ),
  ),
);
```

## 🎯 **Key Benefits**

### **For Managers**
- ✅ **Centralized Control**: Manage all department tasks from one place
- ✅ **Status Tracking**: Real-time visibility into task progress
- ✅ **File Management**: Easy access to submitted files
- ✅ **Flexible Assignment**: Reassign tasks when needed

### **For Staff**
- ✅ **Clear Workflow**: Understand task status and next steps
- ✅ **File Submission**: Easy file upload and download
- ✅ **Mobile Friendly**: Full functionality on mobile devices

### **For System**
- ✅ **Scalable Architecture**: Clean separation of concerns
- ✅ **Responsive Design**: Works on all devices and screen sizes
- ✅ **Consistent UX**: Same design patterns as individual tasks
- ✅ **Robust Error Handling**: Comprehensive error management

## 🚀 **Getting Started**

1. **Access Department Tasks**: From Manager Dashboard → "Department Tasks"
2. **Create Task**: Click "+" button → Fill form → Assign to staff
3. **Monitor Progress**: Use search and filters to track tasks
4. **Review Submissions**: Download files → Accept/Reject with feedback
5. **Handle Rejections**: Reassign to different staff if needed

The department task system provides a complete workflow management solution with modern UI/UX, robust file handling, and comprehensive status management.