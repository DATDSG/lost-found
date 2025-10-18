# Admin Bulk Operations API Documentation

## Overview

The Admin Bulk Operations API provides endpoints for performing batch operations on reports, users, and matches. All endpoints require admin authentication and return a standardized response format.

---

## Authentication

All endpoints require an admin user with a valid JWT token:

```
Authorization: Bearer <admin_jwt_token>
```

---

## Common Request/Response Format

### Request Body

All bulk operations use the same request format:

```json
{
  "ids": ["id1", "id2", "id3"]
}
```

**Validation Rules:**

- `ids` must be an array
- Minimum 1 ID required
- Maximum 100 IDs per request
- IDs must be valid UUID strings

### Response Body

All bulk operations return the same response format:

```json
{
  "success": 2,
  "failed": 1,
  "errors": [
    {
      "id": "invalid-id",
      "error": "Report not found"
    }
  ]
}
```

**Fields:**

- `success` (int): Number of successfully processed items
- `failed` (int): Number of failed items
- `errors` (array): List of errors for failed items, each containing:
  - `id` (string): The ID that failed
  - `error` (string): Error message

---

## Reports Endpoints

### Bulk Approve Reports

**Endpoint:** `POST /admin/reports/bulk/approve`

**Description:** Approve multiple reports at once, changing their status to `APPROVED`.

**Request Example:**

```json
{
  "ids": [
    "550e8400-e29b-41d4-a716-446655440000",
    "550e8400-e29b-41d4-a716-446655440001",
    "550e8400-e29b-41d4-a716-446655440002"
  ]
}
```

**Response Example:**

```json
{
  "success": 3,
  "failed": 0,
  "errors": []
}
```

**Status Codes:**

- `200 OK`: Operation completed (check success/failed counts)
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: User is not an admin
- `422 Unprocessable Entity`: Invalid request body

**Audit Log:** Creates an audit log entry for each approved report with action `report_bulk_approved`.

---

### Bulk Reject Reports

**Endpoint:** `POST /admin/reports/bulk/reject`

**Description:** Reject (hide) multiple reports at once, changing their status to `HIDDEN`.

**Request Example:**

```json
{
  "ids": ["550e8400-e29b-41d4-a716-446655440000"]
}
```

**Response Example:**

```json
{
  "success": 1,
  "failed": 0,
  "errors": []
}
```

**Status Codes:** Same as bulk approve

**Audit Log:** Creates an audit log entry for each rejected report with action `report_bulk_rejected`.

---

### Bulk Delete Reports

**Endpoint:** `POST /admin/reports/bulk/delete`

**Description:** Delete multiple reports at once (soft delete by changing status to `REMOVED`).

**Request Example:**

```json
{
  "ids": [
    "550e8400-e29b-41d4-a716-446655440000",
    "550e8400-e29b-41d4-a716-446655440001"
  ]
}
```

**Response Example:**

```json
{
  "success": 2,
  "failed": 0,
  "errors": []
}
```

**Status Codes:** Same as bulk approve

**Audit Log:** Creates an audit log entry for each deleted report with action `report_bulk_deleted`.

---

## Users Endpoints

### Bulk Activate Users

**Endpoint:** `POST /admin/users/bulk/activate`

**Description:** Activate multiple users at once, setting `is_active` to `true`.

**Request Example:**

```json
{
  "ids": [
    "550e8400-e29b-41d4-a716-446655440010",
    "550e8400-e29b-41d4-a716-446655440011"
  ]
}
```

**Response Example:**

```json
{
  "success": 2,
  "failed": 0,
  "errors": []
}
```

**Special Rules:**

- Cannot modify your own account status (will be added to errors)

**Audit Log:** Creates an audit log entry for each activated user with action `user_bulk_activated`.

---

### Bulk Deactivate Users

**Endpoint:** `POST /admin/users/bulk/deactivate`

**Description:** Deactivate multiple users at once, setting `is_active` to `false`.

**Request Example:**

```json
{
  "ids": ["550e8400-e29b-41d4-a716-446655440010"]
}
```

**Response Example:**

```json
{
  "success": 1,
  "failed": 0,
  "errors": []
}
```

**Special Rules:**

- Cannot modify your own account status (will be added to errors)

**Audit Log:** Creates an audit log entry for each deactivated user with action `user_bulk_deactivated`.

---

### Bulk Delete Users

**Endpoint:** `POST /admin/users/bulk/delete`

**Description:** Delete multiple users at once (soft delete by setting `is_active` to `false`).

**Request Example:**

```json
{
  "ids": ["550e8400-e29b-41d4-a716-446655440010"]
}
```

**Response Example:**

```json
{
  "success": 1,
  "failed": 0,
  "errors": []
}
```

**Special Rules:**

- Cannot delete your own account (will be added to errors)

**Audit Log:** Creates an audit log entry for each deleted user with action `user_bulk_deleted`.

---

## Matches Endpoints

### Bulk Approve Matches

**Endpoint:** `POST /admin/matches/bulk/approve`

**Description:** Approve multiple matches at once, changing their status to `PROMOTED`.

**Request Example:**

```json
{
  "ids": [
    "550e8400-e29b-41d4-a716-446655440020",
    "550e8400-e29b-41d4-a716-446655440021"
  ]
}
```

**Response Example:**

```json
{
  "success": 2,
  "failed": 0,
  "errors": []
}
```

**Audit Log:** Creates an audit log entry for each approved match with action `match_bulk_approved`.

---

### Bulk Reject Matches

**Endpoint:** `POST /admin/matches/bulk/reject`

**Description:** Reject multiple matches at once, changing their status to `SUPPRESSED`.

**Request Example:**

```json
{
  "ids": ["550e8400-e29b-41d4-a716-446655440020"]
}
```

**Response Example:**

```json
{
  "success": 1,
  "failed": 0,
  "errors": []
}
```

**Audit Log:** Creates an audit log entry for each rejected match with action `match_bulk_rejected`.

---

### Bulk Notify Matches

**Endpoint:** `POST /admin/matches/bulk/notify`

**Description:** Send notifications to users for multiple matches. Creates notifications for both report owners.

**Request Example:**

```json
{
  "ids": [
    "550e8400-e29b-41d4-a716-446655440020",
    "550e8400-e29b-41d4-a716-446655440021"
  ]
}
```

**Response Example:**

```json
{
  "success": 2,
  "failed": 0,
  "errors": []
}
```

**Behavior:**

- Creates a notification for the source report owner
- Creates a notification for the target report owner (if different)
- Notifications include match details and report information

**Audit Log:** Creates an audit log entry for each match with notifications sent, action `match_bulk_notified`.

---

## Error Handling

### Common Errors

#### Not Found Errors

```json
{
  "success": 1,
  "failed": 1,
  "errors": [
    {
      "id": "invalid-id",
      "error": "Report not found"
    }
  ]
}
```

#### Permission Errors

```json
{
  "success": 0,
  "failed": 1,
  "errors": [
    {
      "id": "current-user-id",
      "error": "Cannot modify your own account status"
    }
  ]
}
```

#### Validation Errors

```json
{
  "detail": [
    {
      "type": "too_short",
      "loc": ["body", "ids"],
      "msg": "List should have at least 1 item after validation"
    }
  ]
}
```

---

## Usage Examples

### cURL Examples

#### Approve Reports

```bash
curl -X POST "https://api.example.com/admin/reports/bulk/approve" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ids": ["550e8400-e29b-41d4-a716-446655440000"]}'
```

#### Deactivate Users

```bash
curl -X POST "https://api.example.com/admin/users/bulk/deactivate" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ids": ["550e8400-e29b-41d4-a716-446655440010"]}'
```

#### Notify Matches

```bash
curl -X POST "https://api.example.com/admin/matches/bulk/notify" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ids": ["550e8400-e29b-41d4-a716-446655440020"]}'
```

### JavaScript/TypeScript Example

```typescript
// Using the service method from the frontend
const result = await reportsService.bulkApprove(["id1", "id2", "id3"]);

console.log(`Successfully approved ${result.success} reports`);

if (result.failed > 0) {
  console.error("Failed to approve:", result.errors);
}
```

---

## Performance Considerations

1. **Batch Size Limit:** Maximum 100 IDs per request to prevent timeouts
2. **Transaction Support:** All operations within a single request are committed in one transaction
3. **Audit Logging:** Each item creates an audit log entry
4. **Database Locks:** Consider potential lock contention for very large batches

---

## Best Practices

1. **Check Results:** Always check both `success` and `failed` counts in the response
2. **Handle Partial Failures:** Implement retry logic for failed items
3. **Batch Size:** Use smaller batches (20-50 items) for better responsiveness
4. **User Feedback:** Show progress indicators for bulk operations
5. **Confirmation:** Always confirm destructive operations (delete) with users

---

## Integration with Frontend

The frontend services (in `apps/admin/src/services/`) are already configured to call these endpoints:

### Reports Service

```typescript
bulkApprove(ids: string[]): Promise<BulkOperationResult>
bulkReject(ids: string[]): Promise<BulkOperationResult>
bulkDelete(ids: string[]): Promise<BulkOperationResult>
```

### Users Service

```typescript
bulkActivate(ids: string[]): Promise<BulkOperationResult>
bulkDeactivate(ids: string[]): Promise<BulkOperationResult>
bulkDelete(ids: string[]): Promise<BulkOperationResult>
```

### Matches Service

```typescript
bulkApprove(ids: string[]): Promise<BulkOperationResult>
bulkReject(ids: string[]): Promise<BulkOperationResult>
bulkNotify(ids: string[]): Promise<BulkOperationResult>
```

All services include proper error handling and type safety.

---

## Testing

Run the test suite:

```bash
# Run all admin bulk operations tests
pytest services/api/tests/test_admin_bulk_operations.py -v

# Run specific test
pytest services/api/tests/test_admin_bulk_operations.py::test_bulk_approve_reports_success -v

# Run with coverage
pytest services/api/tests/test_admin_bulk_operations.py --cov=app.routers.admin.bulk_operations
```

---

## Security Considerations

1. **Admin Only:** All endpoints require admin role
2. **Audit Trail:** All operations are logged with admin user email
3. **Self-Protection:** Users cannot modify/delete their own account
4. **Soft Deletes:** Most delete operations are soft deletes (status changes)
5. **Transaction Safety:** All database changes are committed atomically

---

**Last Updated:** December 2024  
**API Version:** 1.0  
**Maintainer:** Lost & Found Development Team
