# Frontend Applications

This directory contains all frontend applications for the Lost & Found system.

## Applications

### Web Admin Panel (`web-admin/`)

Administrative dashboard built with Next.js 14, featuring:

- User management
- Item moderation
- Match review and approval
- System analytics and reporting
- Configuration management
- Audit log viewing

**Tech Stack**: Next.js 14, React 18, TypeScript, Tailwind CSS, React Query, Leaflet

**Setup**:

```bash
cd web-admin
npm install
npm run dev
```

Access at: http://localhost:3000

### Mobile App (`mobile/`)

User-facing Flutter application supporting:

- Post lost/found items with photos
- View AI-powered match suggestions
- Secure in-app chat
- Real-time notifications
- Multi-language support (Sinhala, Tamil, English)
- Location-based search
- Claim management

**Tech Stack**: Flutter 3.9+, Dart, Riverpod, Firebase Messaging, Easy Localization

**Setup**:

```bash
cd mobile
flutter pub get
flutter run
```

## Development

### Environment Variables

Copy `.env.example` to `.env.local` in each application and configure:

**Web Admin**:

```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

**Mobile**:
Configure in `lib/core/config/env_config.dart`

### Building for Production

**Web Admin**:

```bash
cd web-admin
npm run build
npm start
```

**Mobile**:

```bash
cd mobile
flutter build apk    # Android
flutter build ios    # iOS
```

## Testing

**Web Admin**:

```bash
cd web-admin
npm test
npm run type-check
```

**Mobile**:

```bash
cd mobile
flutter test
```

## Deployment

### Web Admin

Can be deployed to:

- Vercel (recommended)
- Netlify
- AWS Amplify
- Docker container

### Mobile

Distribute via:

- Google Play Store (Android)
- Apple App Store (iOS)
- Direct APK distribution
