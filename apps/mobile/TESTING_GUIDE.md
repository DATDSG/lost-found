# Testing Guide for Lost & Found Mobile App

## ✅ Feature Testing Checklist

### 1. Item Card Fixed ✅

**File:** `lib/widgets/item_card.dart`

- [x] File corruption resolved
- [x] Uses correct field names (`imageUrls` not `imageUrl`)
- [x] Distance calculation placeholder implemented
- [x] Navigation to item details works
- [ ] Test: Tap "View Details" button → Should navigate to ItemDetailsScreen
- [ ] Test: Tap "Contact" button → Should trigger onContactTap callback

---

### 2. Navigation Flows 🔄

**File:** `lib/config/routes.dart`

#### Routes to Test:

1. **Login → Home**

   - [ ] Test: Launch app → Should show login screen
   - [ ] Test: Login success → Should navigate to home screen

2. **Home → Item Details**

   - [ ] Test: Tap item card → Should navigate to ItemDetailsScreen with item ID
   - [ ] Test: Back button → Should return to home

3. **Home → Notifications**

   - [ ] Test: Tap notification bell icon → Should navigate to NotificationsScreen
   - [ ] Test: Badge count displayed correctly
   - [ ] Test: Back button → Should return to home

4. **Home → Chat**

   - [ ] Test: Tap chat icon → Should navigate to ChatScreen
   - [ ] Test: Badge count displayed correctly
   - [ ] Test: Back button → Should return to home

5. **Chat → Chat Detail**

   - [ ] Test: Tap conversation → Should navigate to ChatDetailScreen with conversation ID
   - [ ] Test: Pass userName correctly
   - [ ] Test: Back button → Should return to chat list

6. **Home → Matches**

   - [ ] Test: Navigate to matches screen
   - [ ] Test: View lost/found matches
   - [ ] Test: Back button → Should return to home

7. **Home → Profile**

   - [ ] Test: Navigate to profile screen
   - [ ] Test: View user information
   - [ ] Test: Back button → Should return to home

8. **Profile → Edit Profile**

   - [ ] Test: Tap edit button → Should navigate to edit profile
   - [ ] Test: Save changes → Should update profile
   - [ ] Test: Back button → Should return to profile

9. **Sign Up Flow**
   - [ ] Test: From login → Tap "Sign Up" → Navigate to SignupScreen
   - [ ] Test: Complete signup → Navigate to home
   - [ ] Test: Back button → Return to login

---

### 3. Language Switching 🌐

**File:** `lib/providers/locale_provider.dart`

#### Supported Languages:

- English (en)
- Spanish (es)
- French (fr)

#### Tests:

1. **Language Dialog**

   - [ ] Test: Tap language icon in app bar → Dialog appears
   - [ ] Test: Dialog shows 3 language options
   - [ ] Test: Current language highlighted

2. **English Selection**

   - [ ] Test: Select English → UI updates to English
   - [ ] Test: Preference saved → Persists after app restart
   - [ ] Test: All screens show English text

3. **Spanish Selection**

   - [ ] Test: Select Spanish → UI updates to Spanish
   - [ ] Test: Preference saved → Persists after app restart
   - [ ] Test: Navigation bar in Spanish
   - [ ] Test: Filter labels in Spanish
   - [ ] Test: Button text in Spanish

4. **French Selection**

   - [ ] Test: Select French → UI updates to French
   - [ ] Test: Preference saved → Persists after app restart
   - [ ] Test: All text translated correctly

5. **Persistence**
   - [ ] Test: Select language → Close app → Reopen → Language persists
   - [ ] Test: Check PreferencesService.getLanguage() returns correct value

---

### 4. Search & Filter Integration 🔍

**Files:**

- `lib/providers/items_provider.dart`
- `lib/screens/home/home_screen.dart`

#### Search Tests:

1. **Debounced Search**

   - [ ] Test: Type in search box → Wait 500ms → API called
   - [ ] Test: Type multiple characters quickly → Only one API call after delay
   - [ ] Test: Clear search → Shows all items

2. **Search Results**
   - [ ] Test: Search "wallet" → Returns matching items
   - [ ] Test: Search "nonexistent" → Shows empty state
   - [ ] Test: Search with special characters → Handles correctly

#### Filter Tests:

1. **Type Filter**

   - [ ] Test: Select "Lost" → Shows only lost items
   - [ ] Test: Select "Found" → Shows only found items
   - [ ] Test: Clear filter → Shows all items

2. **Time Filter**

   - [ ] Test: Select "Last 24h" → Shows recent items
   - [ ] Test: Select "Last week" → Shows items from past week
   - [ ] Test: Select "Last month" → Shows items from past month
   - [ ] Test: Select "All time" → Shows all items

3. **Distance Filter**

   - [ ] Test: Select "Nearby (<1mi)" → Shows nearby items
   - [ ] Test: Select "Within 5mi" → Shows items within 5 miles
   - [ ] Test: Select "Within 10mi" → Shows items within 10 miles
   - [ ] Test: Select "Within 25mi" → Shows items within 25 miles
   - [ ] Test: Select "Any" → Shows all items

4. **Category Filter**

   - [ ] Test: Select "Electronics" → Shows only electronics
   - [ ] Test: Select "Clothing" → Shows only clothing
   - [ ] Test: Select "Keys" → Shows only keys
   - [ ] Test: Each category filters correctly

5. **Location Filter**

   - [ ] Test: Enter location text → Filters by location
   - [ ] Test: Clear location → Shows all locations

6. **Combined Filters**

   - [ ] Test: Apply multiple filters → Results match all criteria
   - [ ] Test: Type + Category → Shows matching results
   - [ ] Test: Distance + Time → Shows matching results

7. **Filter Persistence**
   - [ ] Test: Set filters → Close app → Reopen → Filters persist
   - [ ] Test: Check PreferencesService stores all filters
   - [ ] Test: Clear filters → All preferences cleared

---

### 5. Location Permissions 📍

**File:** `lib/services/location_service.dart`

#### Permission Tests:

1. **Initial Request**

   - [ ] Test: First launch → Location permission dialog appears
   - [ ] Test: Grant permission → Location obtained successfully
   - [ ] Test: Deny permission → Graceful fallback (N/A distance)

2. **Permission States**

   - [ ] Test: Permission denied → Show appropriate message
   - [ ] Test: Permission denied forever → Show settings prompt
   - [ ] Test: Location services disabled → Show enable prompt

3. **Distance Calculation**

   - [ ] Test: Permission granted → Distance calculated for items
   - [ ] Test: Permission denied → Distance shows "N/A"
   - [ ] Test: Move location → Distance updates correctly

4. **Location Caching**
   - [ ] Test: Get location → Saves to preferences
   - [ ] Test: App restart → Uses cached location until refresh
   - [ ] Test: RefreshLocation → Gets new coordinates

---

### 6. WebSocket Real-Time Updates 🔴

**Files:**

- `lib/services/websocket_service.dart`
- `lib/providers/websocket_provider.dart`

#### Connection Tests:

1. **Auto-Connect**

   - [ ] Test: Login → WebSocket connects automatically
   - [ ] Test: Token passed correctly in connection
   - [ ] Test: Connection status updates

2. **Reconnection**

   - [ ] Test: Lose connection → Auto-reconnect after 3 seconds
   - [ ] Test: Max 5 reconnect attempts
   - [ ] Test: Exponential backoff works

3. **Heartbeat**
   - [ ] Test: Ping sent every 30 seconds
   - [ ] Test: Pong received from server
   - [ ] Test: Connection stays alive

#### Real-Time Updates:

1. **Notifications**

   - [ ] Test: New notification → Badge updates immediately
   - [ ] Test: Notification list updates without refresh
   - [ ] Test: Sound/vibration for new notification

2. **Messages**

   - [ ] Test: New message → Chat badge updates
   - [ ] Test: Message appears in conversation instantly
   - [ ] Test: Unread count updates

3. **Items**

   - [ ] Test: New item posted → Appears in feed immediately
   - [ ] Test: Item status changed → Updates in list
   - [ ] Test: Item deleted → Removes from list

4. **Fallback to Polling**
   - [ ] Test: WebSocket fails → Polling continues every 30s
   - [ ] Test: WebSocket reconnects → Polling stops
   - [ ] Test: Both methods don't duplicate data

---

### 7. Error Handling 🚨

**File:** `lib/services/error_handler_service.dart`

#### Network Errors:

1. **No Internet**

   - [ ] Test: Disable network → Show "No internet connection" message
   - [ ] Test: Re-enable network → Auto-retry

2. **Timeout**

   - [ ] Test: Slow connection → Show timeout message
   - [ ] Test: Retry button works

3. **Server Errors**
   - [ ] Test: 500 error → Show "Server error" message
   - [ ] Test: 503 error → Show "Service unavailable" message
   - [ ] Test: Error persists → Prevent infinite retries

#### Authentication Errors:

1. **Session Expired**

   - [ ] Test: 401 error → Show "Session expired" message
   - [ ] Test: Redirect to login screen
   - [ ] Test: Clear stored credentials

2. **Permission Denied**
   - [ ] Test: 403 error → Show "Access denied" message
   - [ ] Test: Don't retry automatically

#### Validation Errors:

1. **Bad Request**

   - [ ] Test: 400 error → Show validation message from server
   - [ ] Test: Highlight problematic fields
   - [ ] Test: Allow user to correct and retry

2. **Conflict**
   - [ ] Test: 409 error → Show conflict message
   - [ ] Test: Provide resolution options

---

### 8. Loading States ⏳

**All Providers**

#### Loading Indicators:

1. **Items Loading**

   - [ ] Test: Launch app → Show skeleton loaders
   - [ ] Test: Pull to refresh → Show refresh indicator
   - [ ] Test: Search → Show loading spinner

2. **Notifications Loading**

   - [ ] Test: Open notifications → Show loading state
   - [ ] Test: Mark as read → Show processing state
   - [ ] Test: Error → Show error state with retry

3. **Chat Loading**

   - [ ] Test: Open chat → Show loading indicator
   - [ ] Test: Send message → Show sending state
   - [ ] Test: Load more messages → Show pagination loader

4. **Profile Loading**
   - [ ] Test: Load profile → Show skeleton
   - [ ] Test: Update profile → Show saving indicator
   - [ ] Test: Upload image → Show progress bar

#### States to Implement:

```dart
enum LoadingState {
  idle,
  loading,
  success,
  error,
}
```

- [ ] Add loading state to all providers
- [ ] Show shimmer/skeleton loaders during initial load
- [ ] Show progress indicators for actions
- [ ] Show success/error feedback after operations
- [ ] Disable buttons during processing
- [ ] Show retry button on errors

---

## 🎯 Integration Tests

### End-to-End Flows:

1. **Report Lost Item Flow**

   - [ ] Login → Home → Report Item → Fill Form → Upload Photo → Submit → View in Feed

2. **Find Match Flow**

   - [ ] Login → Search Item → Apply Filters → Find Match → Contact Owner → Start Chat

3. **Notification Flow**

   - [ ] Receive Notification → Tap Notification → View Item Details → Contact

4. **Multi-Language Flow**
   - [ ] Change Language → Navigate All Screens → Verify Translations → Save Preference

---

## 🐛 Known Issues to Fix

1. **Item Model Missing Coordinates**

   - [ ] Add latitude/longitude fields to Item model
   - [ ] Update item_card.dart to calculate real distance
   - [ ] Update API to return coordinates

2. **WebSocket URL Configuration**

   - [ ] Add WS_URL to environment variables
   - [ ] Update API config for WebSocket endpoint

3. **Notification Sounds**
   - [ ] Add notification sound assets
   - [ ] Implement sound playback

---

## 📝 Testing Commands

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/providers/items_provider_test.dart

# Run widget tests
flutter test test/widgets/item_card_test.dart
```

---

## ✅ Success Criteria

All features pass when:

- ✅ All navigation routes work bidirectionally
- ✅ Language switching updates all UI text
- ✅ Search debounces correctly (500ms)
- ✅ Filters persist after app restart
- ✅ Location permissions handled gracefully
- ✅ WebSocket connects and receives real-time updates
- ✅ Error messages are user-friendly
- ✅ Loading states show appropriate feedback
- ✅ No crashes or unhandled exceptions
- ✅ Performance is smooth (60fps)

---

## 🚀 Next Steps After Testing

1. Fix any bugs found during testing
2. Add missing features (e.g., coordinates in Item model)
3. Optimize performance bottlenecks
4. Add analytics tracking
5. Implement push notifications
6. Add offline mode support
7. Write automated tests for critical paths
8. Prepare for production release
