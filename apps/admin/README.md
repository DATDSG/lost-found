# Admin Web Application

The Lost & Found admin web application is a server-rendered interface for content moderation, user management, match oversight, and system administration. It is integrated into the FastAPI service and served under `/admin`.

## Architecture

### Technology Stack

- **Framework**: FastAPI with Jinja2 templates
- **Styling**: Custom CSS (minimal, no external dependencies)
- **Authentication**: Server-side sessions with HttpOnly cookies
- **Security**: CSRF protection on all mutating operations

### Directory Structure

```
services/api/
├── templates/admin/          # Jinja2 templates
│   ├── base.html            # Base layout with navigation
│   ├── login.html           # Authentication page
│   ├── dashboard.html       # Main dashboard with stats
│   ├── reports_list.html    # Reports moderation queue
│   ├── report_detail.html   # Individual report review
│   ├── matches_list.html    # Match candidates listing
│   ├── match_detail.html    # Match detail with component scores
│   ├── users_list.html      # User management
│   ├── user_detail.html     # User detail and actions
│   ├── flags_list.html      # Content flags triage
│   ├── audit_log.html       # Audit trail viewer
│   ├── translations.html    # Translation helper tools
│   └── system.html          # System health and maintenance
│
├── static/admin/             # Static assets
│   ├── css/
│   │   └── admin.css        # Admin UI styles
│   └── js/                  # (Future: optional client-side enhancements)
│
└── app/routers/admin/        # Admin route handlers
    ├── __init__.py          # Router exports
    ├── auth.py              # Authentication & sessions
    ├── dashboard.py         # Dashboard stats
    ├── reports.py           # Report moderation
    ├── matches.py           # Match management
    ├── users.py             # User management
    ├── flags.py             # Flag handling
    ├── audit.py             # Audit log viewing
    ├── translations.py      # Translation tools
    └── system.py            # System maintenance
```

## Features Implemented

### 1. Authentication & Authorization

- **Login Page**: Email/password authentication
- **Session Management**: In-memory sessions (upgrade to Redis for production)
- **Role-Based Access**: Admin and Moderator roles supported
- **CSRF Protection**: All POST requests require valid CSRF tokens
- **Secure Cookies**: HttpOnly, SameSite=Lax, 8-hour expiration

### 2. Dashboard

- **Statistics Cards**: Pending reports, total reports, active users, flags, matches
- **Recent Pending Reports**: Quick access to moderation queue
- **Recent Activity**: Audit log summary

### 3. Reports Moderation

- **List View**: Paginated with filters (status, type, category, search)
- **Detail View**: Full report information with media gallery
- **Actions**: Approve, Reject, Hide/Unhide
- **Recompute**: Trigger embedding/hash recalculation
- **Audit Trail**: All actions logged

### 4. Matches Management

- **List View**: Filter by status and minimum score
- **Component Scores**: Visual chips for Text/Image/Geo/Time
- **Detail View**: Side-by-side report comparison
- **Score Breakdown**: Transparent calculation display
- **Actions**: Promote, Suppress

### 5. User Management

- **List View**: Search and filter by role/status
- **Detail View**: User stats and recent reports
- **Actions**: Enable/Disable accounts, Change roles
- **Statistics**: Report counts, match confirmations

### 6. Flags (Placeholder)

- **Structure**: Ready for Flag model implementation
- **Actions**: Resolve, Dismiss
- **Filters**: By status and resource type

### 7. Audit Log

- **Comprehensive Logging**: All admin actions tracked
- **Filters**: Action type, admin user, date range
- **Immutable Records**: Timestamp, user, action, resource, details

### 8. Translations

- **Bootstrap Tool**: Google Translate API integration (placeholder)
- **Manual Editor**: JSON-based translation management
- **Language Support**: English, Sinhala, Tamil
- **Sample Preview**: Translation comparison table

### 9. System Tools

- **Health Monitoring**: Database, NLP service, Vision service status
- **Database Stats**: Row counts per table
- **Maintenance Tools**:
  - Recompute embeddings (all or specific reports)
  - Recompute image hashes (all or specific media)
  - Reindex vector search
  - Adjust match scoring weights
- **Dev Tools**: Reseed database, clear cache (dev mode only)

## Security Features

### Implemented

- ✅ Server-side session authentication
- ✅ CSRF token validation on all mutations
- ✅ Role-based access control (Admin/Moderator)
- ✅ HttpOnly, SameSite cookies
- ✅ Auto-escaping in Jinja2 templates
- ✅ Audit logging for all sensitive actions

### Recommended for Production

- 🔄 Move sessions to Redis (persistence + distribution)
- 🔄 Add 2FA/TOTP for admin accounts
- 🔄 Implement stricter CSP headers
- 🔄 Add rate limiting on login endpoint
- 🔄 Session regeneration on privilege escalation
- 🔄 IP whitelisting for admin access (optional)

## Integration with API

### Registering Admin Routers

Update `services/api/app/main.py` to include admin routers:

```python
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.routers.admin import (
    auth_router,
    dashboard_router,
    reports_router,
    matches_router,
    users_router,
    flags_router,
    audit_router,
    translations_router,
    system_router,
)

app = FastAPI()

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Include admin routers
app.include_router(auth_router)
app.include_router(dashboard_router)
app.include_router(reports_router)
app.include_router(matches_router)
app.include_router(users_router)
app.include_router(flags_router)
app.include_router(audit_router)
app.include_router(translations_router)
app.include_router(system_router)
```

## Usage

### Accessing Admin Interface

1. Navigate to `http://localhost:8000/admin`
2. Login with admin credentials
3. Redirects to dashboard on success

### Default Test Account

Create an admin user via database seed or registration:

```sql
-- Example admin user (password should be hashed)
INSERT INTO users (email, hashed_password, role, is_active)
VALUES ('admin@example.com', '<bcrypt_hash>', 'admin', true);
```

### Session Management

- Sessions stored in-memory (dev)
- 8-hour expiration
- Automatic cleanup on logout
- CSRF token regenerated per session

## Customization

### Styling

Edit `static/admin/css/admin.css` to customize:

- Color scheme (CSS variables in `:root`)
- Typography
- Component spacing
- Responsive breakpoints

### Adding New Pages

1. Create template in `templates/admin/`
2. Create router in `app/routers/admin/`
3. Register router in `__init__.py` and `main.py`
4. Add navigation link in `base.html`

### Extending Functionality

- Add new stats to dashboard: Query in `dashboard.py`
- Create custom filters: Add form fields + query logic
- Implement batch actions: Add checkbox selection + bulk endpoints

## TODO / Future Enhancements

### High Priority

- [ ] Implement Flag model and complete flags functionality
- [ ] Integrate NLP/Vision service calls for recompute operations
- [ ] Add actual Google Translate API integration
- [ ] Implement file writing for manual translations
- [ ] Calculate actual media storage free space
- [ ] Move sessions to Redis for production

### Medium Priority

- [ ] Add WebSocket live updates for queues
- [ ] Implement bulk moderation actions
- [ ] Add keyboard shortcuts for common actions
- [ ] Create data export functionality (CSV/JSON)
- [ ] Add email notifications for critical events

### Low Priority

- [ ] Image zoom modal on media review
- [ ] Inline editing for report fields
- [ ] Advanced search with query builder
- [ ] Dashboard charts and graphs
- [ ] Dark mode toggle

## Testing

### Manual Testing Checklist

- [ ] Login/logout flow
- [ ] CSRF protection (tamper token)
- [ ] Report approve/reject/hide actions
- [ ] Match promote/suppress actions
- [ ] User enable/disable
- [ ] Role changes
- [ ] Audit log filtering
- [ ] Session expiration
- [ ] Unauthorized access attempts

### Automated Tests (Future)

- Unit tests for router logic
- Integration tests for DB operations
- E2E tests for critical workflows

## Performance Considerations

- **Pagination**: All list views paginated (20-50 items)
- **Query Optimization**: Indexed columns used in filters
- **Session Storage**: Move to Redis for multi-instance deployments
- **Static Assets**: Consider CDN for production
- **Lazy Loading**: Media thumbnails only on demand

## Compliance & Privacy

- **Audit Trail**: All admin actions logged with user, timestamp, details
- **Data Minimization**: Only essential user info displayed
- **Access Control**: Role-based permissions enforced
- **Session Security**: Short expiration, secure cookies

## Support & Documentation

For full specification, refer to:

- `../../docs/blueprint.txt` Section 3 (Admin Web Detailed Blueprint)
- API documentation at `/docs` (FastAPI auto-generated)
- Individual router files for endpoint details

## Contributing

When adding new features:

1. Follow existing patterns (auth, CSRF, audit logging)
2. Update this README
3. Add templates with proper escaping
4. Include audit log entries for sensitive operations
5. Test CSRF protection and role restrictions
