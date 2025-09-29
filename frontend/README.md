# Frontend Applications

This directory contains all frontend applications for the Lost & Found system.

## Applications

### Web Admin Dashboard (`/web-admin`)

Administrative dashboard for system management built with Next.js.

**Features:**

- System administration
- User management
- Content moderation
- Analytics and reporting
- Real-time monitoring

**Technology Stack:**

- React 18+
- Next.js 14+
- TypeScript
- Tailwind CSS
- Tanstack Query

### Mobile App (`/mobile`)

Cross-platform mobile application built with Flutter.

**Features:**

- Item reporting (lost/found)
- Smart search and filtering
- Match notifications
- In-app messaging
- Geolocation services
- Multilingual support (English, Sinhala, Tamil)

**Technology Stack:**

- Flutter 3.19+
- Dart
- Provider/Riverpod
- HTTP client
- Local notifications

## Getting Started

### Web Admin Dashboard

1. **Install Dependencies**

   ```bash
   cd frontend/web-admin
   npm install
   ```

2. **Environment Configuration**

   ```bash
   cp .env.example .env.local
   # Edit .env.local with your API endpoints
   ```

3. **Start Development Server**

   ```bash
   npm run dev
   ```

4. **Access Dashboard**
   - URL: `http://localhost:3000`
   - Login with admin credentials

### Mobile App

1. **Install Dependencies**

   ```bash
   cd frontend/mobile
   flutter pub get
   ```

2. **Environment Setup**

   ```bash
   # Copy environment config
   cp .env.example .env
   ```

3. **Run on Device/Emulator**

   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android
   ```

## Development Guidelines

### Web Admin

- Use TypeScript for type safety
- Follow React best practices
- Implement responsive design
- Use proper error boundaries
- Write unit tests for components

### Mobile App

- Follow Flutter/Dart conventions
- Implement proper state management
- Handle offline scenarios
- Test on multiple screen sizes
- Support accessibility features

## Build & Deployment

### Web Admin

```bash
# Production build
npm run build

# Export static files
npm run export
```

### Mobile App

```bash
# Android release build
flutter build apk --release

# iOS release build
flutter build ios --release
```

## Testing

### Web Admin

```bash
# Unit tests
npm test

# E2E tests
npm run test:e2e
```

### Mobile App

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```
