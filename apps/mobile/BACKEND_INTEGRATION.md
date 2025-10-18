# Backend Integration Implementation

## Overview

This document tracks the comprehensive backend integration and advanced features implementation for the Lost & Found mobile app.

## Completed Features ✅

### 1. Navigation & UI Structure

- ✅ 4-tab bottom navigation (Home, Matches, Reports, Profile)
- ✅ Custom app bar with logo, chat, notification, language switcher
- ✅ Search bar with filter integration
- ✅ Filter modal with Lost/Found toggle, Time, Distance, Category, Location filters
- ✅ Item cards with Contact/View Details buttons

### 2. API Service Extensions

**File:** `lib/services/api_service.dart`

Successfully extended with the following endpoints:

#### Search & Filtering

- `searchItems(query, type, time, distance, category, location, latitude, longitude)` - Search items with filters
- `getItemDetails(itemId)` - Get detailed item information

#### Chat & Conversations

- `createConversation(itemId, recipientId)` - Create new conversation
- `getConversations()` - Get all user conversations
- `getMessages(conversationId)` - Get messages for a conversation
- `sendMessage(conversationId, message, type)` - Send a message
- `getUnreadMessageCount()` - Get count of unread messages

#### Notifications

- `getNotifications()` - Get all notifications
- `markNotificationAsRead(notificationId)` - Mark single notification as read
- `markAllNotificationsAsRead()` - Mark all notifications as read
- `getUnreadNotificationCount()` - Get count of unread notifications

### 3. Models Created

**Files:**

- `lib/models/item.dart` - Item model (already existed with properties: id, title, description, type, category, location, dateReported, dateLost, imageUrls, status, userId)
- `lib/models/match_model.dart` - Match data model
- `lib/models/chat_model.dart` - Chat message and conversation models
- `lib/models/notification_model.dart` - Notification model with type (match/message/update/general)

### 4. State Management Providers

**Files:**

- `lib/providers/items_provider.dart` - Items state management (already existed)
- `lib/providers/matches_provider.dart` - Matches state management
- `lib/providers/chat_provider.dart` - Chat and messaging state
- `lib/providers/notifications_provider.dart` - Notifications with auto-polling (30s intervals)

### 5. Services

**Files:**

- `lib/services/api_service.dart` - HTTP client with Dio, token authentication
- `lib/services/location_service.dart` - Geolocation with:
  - `getCurrentLocation()` - Get user's current position
  - `calculateDistance(lat1, lon1, lat2, lon2)` - Haversine distance formula (Earth radius: 3958.8 miles)
  - `formatDistance(miles)` - Format as "Nearby" or "X mi"
  - Permission handling and error management

### 6. New Screens Created

#### Notifications Screen

**File:** `lib/screens/notifications/notifications_screen.dart`

Features:

- Pull-to-refresh functionality
- Empty state ("No notifications")
- Error handling with retry
- Mark all as read button
- Individual notification tiles with:
  - Icon and color based on type (match=green, message=blue, update=orange)
  - Title and message
  - Timestamp formatting ("Just now", "Xm ago", "Xh ago", "Xd ago", etc.)
  - Unread indicator (blue dot)
  - Tap to mark as read and navigate

#### Item Details Screen

**File:** `lib/screens/item_details/item_details_screen.dart`

Features:

- Image gallery with page indicator
- Item header with title, category, and status badge (LOST/FOUND)
- Info section showing:
  - Date (formatted as "Jan 15, 2025")
  - Time (12-hour format with AM/PM)
  - Distance (placeholder for now)
- Description section
- Location section with map placeholder
- Contact Owner button that:
  - Shows loading state
  - Creates conversation via API
  - Navigates to chat screen
  - Handles errors with snackbar
- Share button (placeholder)
- Error view with retry functionality

### 7. Dependencies Added

**File:** `pubspec.yaml`

- ✅ `geolocator: ^10.1.0` - Geolocation and distance calculation

## In Progress / TODO 🔄

### 1. Internationalization (i18n/l10n)

**Status:** Not Started

**Tasks:**

- [ ] Create `lib/l10n/` directory structure
- [ ] Create translation files (en.json, es.json, fr.json)
- [ ] Create locale provider (`lib/providers/locale_provider.dart`)
- [ ] Update custom app bar language switcher to show modal
- [ ] Wrap all hardcoded strings with translation keys
- [ ] Test language switching

**Affected Files:**

- All screens with hardcoded strings
- `lib/widgets/custom_app_bar.dart` (language switcher)

### 2. Preferences Storage

**Status:** Not Started (shared_preferences already in pubspec.yaml)

**Tasks:**

- [ ] Create `lib/services/preferences_service.dart`
- [ ] Implement filter preferences storage
  - Save: selectedType, timeRange, distance, category, location
  - Load on app start
- [ ] Implement language preference storage
  - Save selected language code
  - Load on app start
- [ ] Integrate with filter modal
- [ ] Integrate with locale provider

### 3. Backend Integration - Search & Filters

**Status:** API methods ready, UI integration pending

**Tasks:**

- [ ] Update `lib/providers/items_provider.dart` to use `searchItems` API
- [ ] Connect search bar to provider
- [ ] Connect filter modal "Apply" button to provider
- [ ] Show loading indicator during search
- [ ] Handle empty results
- [ ] Test search functionality

**Files to Modify:**

- `lib/screens/home/home_screen.dart`
- `lib/providers/items_provider.dart`

### 4. Backend Integration - Notifications

**Status:** Provider ready with auto-polling, UI screen created, app bar integration pending

**Tasks:**

- [ ] Update `lib/widgets/custom_app_bar.dart` to show unread count badge
- [ ] Wire up notification icon tap to navigate to NotificationsScreen
- [ ] Test notification polling (30s intervals)
- [ ] Implement navigation from notification to related item/match/chat

**Files to Modify:**

- `lib/widgets/custom_app_bar.dart`

### 5. Backend Integration - Chat

**Status:** Provider and models ready, unread count integration pending

**Tasks:**

- [ ] Update `lib/widgets/custom_app_bar.dart` to show unread message count badge
- [ ] Wire up chat icon tap to navigate to ChatScreen
- [ ] Test chat functionality
- [ ] Implement real-time message updates (WebSocket or polling)

**Files to Modify:**

- `lib/widgets/custom_app_bar.dart`
- `lib/providers/chat_provider.dart` (add polling or WebSocket)

### 6. Geolocation Integration

**Status:** Service created, package added, actual location usage pending

**Tasks:**

- [ ] Request location permissions on app start
- [ ] Get current location and store in provider
- [ ] Update item details screen to calculate actual distance
- [ ] Update filter modal distance calculation
- [ ] Update item cards to show distance
- [ ] Handle location permission denial

**Files to Modify:**

- `lib/screens/item_details/item_details_screen.dart`
- `lib/widgets/item_card.dart`
- `lib/widgets/filter_bottom_sheet.dart`

### 7. Real-time Updates

**Status:** Not Started

**Options:**

1. WebSocket implementation using `web_socket_channel` (already in pubspec.yaml)
2. Polling with configurable intervals
3. Firebase Cloud Messaging for push notifications

**Tasks:**

- [ ] Decide on approach (WebSocket vs polling)
- [ ] Implement real-time messages
- [ ] Implement real-time notifications
- [ ] Implement real-time match updates

### 8. Navigation Routes

**Status:** Not Started

**Tasks:**

- [ ] Define route names in `lib/config/routes.dart`
- [ ] Set up MaterialApp routes
- [ ] Add navigation to:
  - NotificationsScreen from app bar
  - ChatScreen from app bar
  - ChatDetailScreen from notifications
  - ItemDetailsScreen from item cards
  - ItemDetailsScreen from matches

## File Structure

```
lib/
├── config/
│   ├── api_config.dart ✅
│   └── routes.dart (TODO)
├── models/
│   ├── item.dart ✅
│   ├── match_model.dart ✅
│   ├── chat_model.dart ✅
│   └── notification_model.dart ✅
├── providers/
│   ├── items_provider.dart ✅
│   ├── matches_provider.dart ✅
│   ├── chat_provider.dart ✅
│   ├── notifications_provider.dart ✅
│   └── locale_provider.dart (TODO)
├── services/
│   ├── api_service.dart ✅
│   ├── storage_service.dart ✅
│   ├── location_service.dart ✅ (has compile errors - package added)
│   └── preferences_service.dart (TODO)
├── screens/
│   ├── home/
│   │   └── home_screen.dart ✅
│   ├── matches/
│   │   └── matches_screen.dart ✅
│   ├── chat/
│   │   ├── chat_screen.dart ✅
│   │   └── chat_detail_screen.dart ✅
│   ├── notifications/
│   │   └── notifications_screen.dart ✅
│   ├── item_details/
│   │   └── item_details_screen.dart ✅
│   └── profile/
│       └── profile_screen.dart ✅
├── widgets/
│   ├── bottom_nav_bar.dart ✅
│   ├── custom_app_bar.dart ✅
│   ├── filter_bottom_sheet.dart ✅
│   └── item_card.dart ✅
└── l10n/ (TODO)
    ├── app_en.json
    ├── app_es.json
    └── app_fr.json
```

## API Endpoints Summary

### Base URL

```dart
static const baseUrl = 'http://localhost:3000/api/v1';
```

### Implemented Endpoints

```
GET    /items/search?query=...&type=...&time=...&distance=...&category=...&location=...&latitude=...&longitude=...
GET    /items/:id
POST   /conversations
GET    /conversations
GET    /conversations/:id/messages
POST   /conversations/:id/messages
GET    /conversations/unread-count
GET    /notifications
PUT    /notifications/:id/read
PUT    /notifications/read-all
GET    /notifications/unread-count
```

## Next Steps Priority

1. **Add `flutter pub get`** to install geolocator package
2. **Implement navigation routes** to connect all screens
3. **Wire up notifications badge** in custom app bar
4. **Wire up chat badge** in custom app bar
5. **Connect search and filters** to backend API
6. **Implement i18n/l10n** for language switching
7. **Implement preferences storage** for filters and language
8. **Request and use geolocation** for distance calculation
9. **Add real-time updates** (WebSocket or polling)
10. **Testing and bug fixes**

## Testing Checklist

### Search & Filters

- [ ] Search by query returns filtered results
- [ ] Lost/Found toggle filters correctly
- [ ] Time filter (Last 24h, Last week, etc.) works
- [ ] Distance filter calculates correctly
- [ ] Category filter works
- [ ] Location filter works
- [ ] Clear filters resets all values
- [ ] Filter preferences persist between app restarts

### Notifications

- [ ] Notifications load on screen open
- [ ] Auto-polling updates notifications every 30s
- [ ] Pull-to-refresh works
- [ ] Mark as read updates UI immediately
- [ ] Mark all as read works
- [ ] Unread badge shows correct count
- [ ] Tapping notification navigates to related item

### Chat

- [ ] Can create conversation from item details
- [ ] Chat list shows all conversations
- [ ] Chat detail shows messages
- [ ] Can send messages
- [ ] Unread badge shows correct count
- [ ] Real-time message updates work

### Geolocation

- [ ] Location permission request on first launch
- [ ] Distance calculation is accurate
- [ ] Distance formatting is correct ("Nearby" or "X mi")
- [ ] Graceful handling of permission denial
- [ ] Works offline with cached location

### i18n/l10n

- [ ] Language switcher shows available languages
- [ ] Changing language updates all strings
- [ ] Language preference persists
- [ ] RTL languages work correctly (if supported)

## Notes

- All providers use Riverpod 2.5.0 with StateNotifier pattern
- API service uses Dio with automatic token authentication
- Notifications poll every 30 seconds (configurable)
- Distance calculation uses Haversine formula with Earth radius 3958.8 miles
- Item model properties: id, title, description, type, category, location, dateReported, dateLost, imageUrls, status, userId

## Known Issues

- ✅ Location service has compile errors - **FIXED** by adding geolocator package to pubspec.yaml
- Item details screen needs recipient ID from item owner for conversation creation - using `item.userId`
- No actual map widget integrated yet (placeholder shown)
- No share functionality implemented yet (placeholder button)
- Real-time updates not implemented yet (using polling)
- Navigation routes not set up yet (using placeholder pushNamed)

## Resources

- [Flutter Riverpod Documentation](https://riverpod.dev/)
- [Dio HTTP Client Documentation](https://pub.dev/packages/dio)
- [Geolocator Documentation](https://pub.dev/packages/geolocator)
- [Flutter Internationalization](https://docs.flutter.dev/accessibility-and-internationalization/internationalization)
