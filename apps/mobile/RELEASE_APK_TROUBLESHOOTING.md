# Release APK Network Troubleshooting Guide

## Problem

The debug APK works fine with the server, but the release APK shows network errors and cannot connect to the server.

## Root Cause

Android release builds have stricter network security policies compared to debug builds. The main issues were:

1. **Cleartext Traffic**: Release builds block HTTP traffic by default
2. **Network Security Config**: Missing explicit configuration for HTTP domains
3. **Permissions**: INTERNET permission was only in debug/profile manifests

## Solutions Implemented

### 1. Network Security Configuration

Created `android/app/src/main/res/xml/network_security_config.xml`:

- Allows cleartext traffic for development server IPs
- Configures specific domains for HTTP access
- Maintains security for other domains

### 2. AndroidManifest.xml Updates

- Added explicit `INTERNET` permission in main manifest
- Added `android:networkSecurityConfig` reference
- Maintained `android:usesCleartextTraffic="true"`

### 3. Environment Configuration

- Updated `environment_config.dart` to handle release builds properly
- Added `kReleaseMode` detection for consistent behavior

## Testing Steps

1. **Build Release APK**:

   ```bash
   cd apps/mobile
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Install and Test**:
   - Install the APK on your device
   - Test network connectivity
   - Check if server communication works

3. **Verify Configuration**:
   - Check that the app uses the correct server URL
   - Ensure network requests are successful
   - Monitor for any remaining network errors

## Additional Notes

- The server URL `http://172.104.40.189:8000` is now properly configured for release builds
- Debug logging is disabled in release builds for better performance
- For production deployment, consider migrating to HTTPS for better security

## If Issues Persist

1. Check device network connectivity
2. Verify server is accessible from the device
3. Check Android logs: `adb logcat | grep -i network`
4. Ensure the device has proper internet access
5. Test with a different network if possible
