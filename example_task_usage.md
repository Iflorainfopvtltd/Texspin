# Task Management System - Updated Implementation

## Overview
The task management system has been updated to handle the new JSON response structure with file download capabilities. The system now supports both card-based grid view and table-based list view.

## Key Features

### 1. Updated Task Model
- Added support for `fileName`, `fileUrl`, `viewUrl`, and `downloadUrl` fields
- Maintains backward compatibility with existing `attachments` structure
- Handles the new JSON response format from your API

### 2. Task Card Widget (`TaskCard`)
- Consistent sizing and theming across different screen sizes
- Responsive design that adapts to mobile, tablet, and desktop
- Built-in download functionality for submitted tasks
- Approve/Reject actions for submitted tasks
- Edit/Delete actions for non-submitted tasks

### 3. Grid View Screen (`TaskGridScreen`)
- Card-based layout with responsive grid (1-3 columns based on screen width)
- Search functionality by task name or staff name
- Filter chips for different task statuses (All, Pending, In Progress, Submitted, Completed, Rejected)
- Pull-to-refresh support
- Switch to table view option

### 4. Download Functionality
The system now properly handles file downloads using the new JSON structure:

```dart
// For submitted tasks with downloadUrl
if (task.status.toLowerCase() == 'submitted' && 
    task.downloadUrl != null && 
    task.downloadUrl!.isNotEmpty) {
  // Show download button
  // On click: ApiService.baseUrl + task.downloadUrl
}
```

## JSON Response Handling

The system now properly handles your JSON response structure:

```json
{
  "message": "Tasks fetched successfully",
  "count": 4,
  "tasks": [
    {
      "_id": "693abbe55845bcc8a87f9e2b",
      "name": "test2",
      "description": "test2",
      "deadline": "2025-12-30T18:30:00.000Z",
      "assignedStaff": {
        "_id": "6925964c3aeeefdd4b8ed66c",
        "firstName": "Prem",
        "lastName": "Chopra",
        "email": "ifloratap@gmail.com",
        "staffId": "TEXSPINEMP-9B8D25"
      },
      "createdBy": {
        "_id": "691dac1022af03f34d15d47d",
        "firstName": "Dhairya",
        "lastName": "Soni",
        "email": "tosikoc197@gyknife.com",
        "staffId": "TEXSPINEMP-1620C4"
      },
      "status": "submitted",
      "createdAt": "2025-12-11T12:41:09.232Z",
      "updatedAt": "2025-12-11T12:42:07.797Z",
      "fileName": "dfds.xlsx",
      "fileUrl": "/texspin/api/task/view-file/task-1765456927794-798953226.xlsx",
      "viewUrl": "/texspin/api/task/view-file/task-1765456927794-798953226.xlsx",
      "downloadUrl": "/texspin/api/task/download-file/task-1765456927794-798953226.xlsx"
    }
  ]
}
```

## Usage Examples

### 1. Basic Task Card
```dart
TaskCard(
  task: task,
  onEdit: () => _showEditDialog(task),
  onDelete: () => _deleteTask(task.id),
  onRefresh: _loadTasks,
)
```

### 2. Compact Task Card (for grid layouts)
```dart
TaskCard(
  task: task,
  isCompact: true,
  showActions: true,
  onRefresh: _loadTasks,
)
```

### 3. Grid View with Responsive Layout
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: screenWidth > 1200 ? 3 : screenWidth > 800 ? 2 : 1,
    childAspectRatio: crossAxisCount == 1 ? 3.5 : 1.2,
  ),
  itemBuilder: (context, index) => TaskCard(
    task: tasks[index],
    isCompact: crossAxisCount > 1,
  ),
)
```

## File Download Implementation

The download functionality has been significantly improved to properly save files with correct names and extensions:

### Features:
1. **Proper file saving**: Downloads files to the device's Downloads folder (Android) or Documents folder (iOS)
2. **Permission handling**: Automatically requests storage permissions when needed
3. **File naming**: Preserves original file names and extensions from the server
4. **Duplicate handling**: Automatically creates unique names if files already exist
5. **Progress tracking**: Shows download progress and completion status
6. **File opening**: Provides option to open downloaded files

### Implementation Flow:

1. **Check for downloadUrl**: First checks if the task has a `downloadUrl` field
2. **Fallback to attachments**: If no `downloadUrl`, falls back to the old `attachments` structure
3. **Permission check**: Verifies and requests storage permissions if needed
4. **Download with progress**: Uses Dio to download files with progress tracking
5. **Save with proper naming**: Saves files with correct extensions and handles duplicates
6. **User feedback**: Shows detailed progress and completion messages with file location

```dart
Future<void> _downloadTaskFile(Task task) async {
  String? fileUrl;
  String? fileName;

  // Check new structure first
  if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty) {
    fileUrl = task.downloadUrl;
    fileName = task.fileName ?? 'task_file';
  } 
  // Fallback to old structure
  else if (task.attachments != null && task.attachments!.isNotEmpty) {
    final attachment = task.attachments!.first;
    fileUrl = attachment['fileUrl'] ?? '';
    fileName = attachment['fileName'] ?? 'task_file';
  }

  if (fileUrl != null && fileUrl.isNotEmpty) {
    // Check permissions
    if (!await FileDownloadService.hasStoragePermission()) {
      await FileDownloadService.requestStoragePermission();
    }

    // Download file with proper naming
    final String fullUrl = ApiService.baseUrl + fileUrl;
    final filePath = await FileDownloadService.downloadFile(
      url: fullUrl,
      fileName: fileName!,
      onProgress: (received, total) {
        // Track download progress
      },
    );
    
    // Show success message with file location and open option
  }
}
```

### FileDownloadService Features:

- **Cross-platform support**: Works on Android, iOS, Windows, macOS, and Linux
- **Smart directory selection**: Uses Downloads folder on Android, Documents on iOS
- **Permission management**: Handles storage permissions automatically
- **File extension detection**: Automatically adds extensions if missing
- **Duplicate prevention**: Creates unique filenames for duplicate downloads
- **File opening**: Platform-specific file opening capabilities

## Navigation Integration

The system is integrated into the manager dashboard:

- **Mobile**: Opens full-screen grid view (`TaskGridScreen`)
- **Desktop/Tablet**: Opens dialog with table view (`TaskManagementDialog`)
- **Grid View**: Includes option to switch to table view
- **Table View**: Maintains existing functionality with updated download support

## Status-Based Actions

### For Submitted Tasks:
- **Download** button (if `downloadUrl` is available)
- **Approve** button (changes status to 'completed')
- **Reject** button (changes status to 'rejected' with reason)

### For Other Tasks:
- **Download** button (if files are available)
- **Edit** button (for pending/in-progress tasks)
- **Delete** button (for all non-completed tasks)

This implementation provides a consistent, responsive, and feature-rich task management experience that properly handles your new JSON structure and file download requirements.