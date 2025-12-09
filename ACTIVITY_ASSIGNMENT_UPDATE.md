# Activity Assignment & Reassignment Feature Update

## Overview
Updated the activity assignment flow in the Gantt chart to properly handle both new assignments and reassignments using the correct API endpoints.

## Changes Made

### 1. API Service Updates (`lib/services/api_service.dart`)

Added two new API methods to handle activity assignment and reassignment:

#### **assignActivityStaff()** - For New Assignments (PATCH)
Used when an activity has no staff assigned (responsible person is "Unassigned").

**Endpoint:** `PATCH /api/apqpproject/:projectId/activity`

**Parameters:**
```dart
{
  "phase": "PHASE_ID",
  "activity": "ACTIVITY_ID",
  "staff": "STAFF_ID_TO_ASSIGN",
  "startDate": "2023-11-01",
  "endDate": "2023-11-07",
  "startWeek": 1,
  "endWeek": 2
}
```

#### **reassignActivityStaff()** - For Reassignments (PUT)
Used when an activity already has a staff member assigned.

**Endpoint:** `PUT /api/apqpproject/:projectId/reassign-activity`

**Parameters:**
```dart
{
  "phaseId": "PHASE_OBJECT_ID",
  "activityId": "ACTIVITY_OBJECT_ID",
  "staffId": "NEW_STAFF_OBJECT_ID",
  "startDate": "2023-11-01",
  "endDate": "2023-11-07",
  "startWeek": 1,
  "endWeek": 2
}
```

**Response:**
```json
{
  "message": "Activity reassigned successfully",
  "apqpProject": { ... }
}
```

### 2. Assignment Dialog Updates (`lib/widgets/assign_staff_dialog.dart`)

Updated the `_assignStaff()` method to:

1. **Check if activity is unassigned:**
   - If `currentStaffId` is null or empty → Use PATCH (new assignment)
   - If `currentStaffId` exists → Use PUT (reassignment)

2. **Validate all required fields:**
   - Staff member selected
   - Start and end dates selected
   - Start and end weeks entered

3. **Call the appropriate API:**
   - **Unassigned:** Calls `assignActivityStaff()` with PATCH
   - **Already assigned:** Calls `reassignActivityStaff()` with PUT

4. **Provide user feedback:**
   - Success message indicates whether it was an assignment or reassignment
   - Error messages show specific issues

### 3. Gantt Chart Integration (`lib/widgets/gantt_chart.dart`)

The Gantt chart already handles the flow correctly:

1. **Click on "Responsible" column:**
   - If unassigned → Opens assignment dialog directly
   - If assigned → Shows confirmation dialog first, then opens reassignment dialog

2. **Passes current data:**
   - Current staff ID and name
   - Current start/end dates
   - Current start/end weeks
   - Phase ID and Activity ID

## User Flow

### For Unassigned Activities:

1. Manager clicks on "Unassigned" in the Responsible column
2. Assignment dialog opens with 4 steps:
   - **Step 1:** Select staff member
   - **Step 2:** Select date range
   - **Step 3:** Enter week numbers
   - **Step 4:** Review and confirm
3. Click "Done" → **PATCH** request is sent
4. Success message: "Staff assigned successfully!"
5. Returns to dashboard with updated data

### For Already Assigned Activities:

1. Manager clicks on staff name in the Responsible column
2. Confirmation dialog appears showing current assignment
3. Click "Reassign" → Assignment dialog opens with prefilled data:
   - Current staff member pre-selected
   - Current dates pre-filled
   - Current weeks pre-filled
4. Manager can modify any field through the 4 steps
5. Click "Done" → **PUT** request is sent
6. Success message: "Staff reassigned successfully!"
7. Returns to dashboard with updated data

## Technical Details

### Date Format
Dates are formatted as: `YYYY-MM-DD` (e.g., "2023-11-01")

### Week Numbers
Week numbers are integers (1-52) representing the project timeline weeks.

### Error Handling
- Validates all required fields before API call
- Shows specific error messages for missing data
- Catches and displays API errors
- Prevents multiple submissions with loading state

### State Management
- `isCurrentlyUnassigned` flag determines which API to call
- Loading state (`_isAssigning`) prevents duplicate submissions
- Form validation ensures data completeness

## Files Modified

1. **lib/services/api_service.dart**
   - Added `assignActivityStaff()` method (PATCH)
   - Added `reassignActivityStaff()` method (PUT)

2. **lib/widgets/assign_staff_dialog.dart**
   - Updated `_assignStaff()` to use correct API based on assignment status
   - Added validation for dates and weeks
   - Improved error messages

3. **ACTIVITY_ASSIGNMENT_UPDATE.md** (this file)
   - Documentation of changes

## Testing Checklist

- [ ] Unassigned activity can be assigned using PATCH
- [ ] Assigned activity shows confirmation dialog
- [ ] Reassignment uses PUT endpoint
- [ ] All 4 steps of assignment dialog work
- [ ] Date picker works correctly
- [ ] Week number inputs accept valid numbers
- [ ] Review step shows all selected data
- [ ] Success messages display correctly
- [ ] Error messages show for validation failures
- [ ] API errors are caught and displayed
- [ ] Dashboard refreshes after assignment/reassignment
- [ ] Gantt chart updates with new staff assignment

## API Endpoints Summary

| Action | Method | Endpoint | When to Use |
|--------|--------|----------|-------------|
| Assign | PATCH | `/api/apqpproject/:projectId/activity` | Activity is unassigned |
| Reassign | PUT | `/api/apqpproject/:projectId/reassign-activity` | Activity already has staff |

## Benefits

✅ **Correct API Usage:** Uses PATCH for new assignments, PUT for reassignments
✅ **Better UX:** Confirmation dialog for reassignments prevents accidental changes
✅ **Data Validation:** Ensures all required fields are provided
✅ **Clear Feedback:** Distinct messages for assignment vs reassignment
✅ **Prefilled Data:** Reassignment dialog shows current values for easy modification
✅ **Error Handling:** Comprehensive error messages guide users

All diagnostics passed with no errors!
