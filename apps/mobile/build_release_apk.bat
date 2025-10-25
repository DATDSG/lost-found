@echo off
echo Building release APK for Lost & Found Mobile App...
echo.

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building release APK...
flutter build apk --release

echo.
echo Build completed! The APK is located at:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo You can now install this APK on your device to test the network connectivity.
echo.
pause
