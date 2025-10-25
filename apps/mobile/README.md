# Lost & Found Mobile App

A Flutter mobile application for the Lost & Found platform, built following international Flutter development standards and best practices.

## 📁 Project Structure

The project follows a **Feature-Driven Development (FDD)** architecture with **Clean Architecture** principles:

```
lib/
├── app/                          # Main application layer
│   ├── core/                     # Core functionality
│   │   ├── constants/            # App constants and configuration
│   │   │   ├── app_constants.dart
│   │   │   ├── api_config.dart
│   │   │   └── routes.dart
│   │   ├── di/                   # Dependency injection
│   │   │   └── dependency_injection.dart
│   │   ├── errors/               # Error handling
│   │   │   └── app_exceptions.dart
│   │   ├── network/             # Network configuration
│   │   │   └── network_config.dart
│   │   ├── router/               # App routing
│   │   │   └── app_router.dart
│   │   ├── theme/               # App theming
│   │   │   ├── app_theme.dart
│   │   │   └── design_tokens.dart
│   │   ├── utils/               # Core utilities
│   │   │   └── retry_helper.dart
│   │   └── widgets/              # Core widgets
│   │       ├── splash_screen.dart
│   │       ├── onboarding_screen.dart
│   │       └── page_transitions.dart
│   ├── features/                 # Feature modules
│   │   ├── auth/                 # Authentication feature
│   │   │   ├── data/             # Data layer (repositories, data sources)
│   │   │   ├── domain/           # Domain layer (entities, use cases)
│   │   │   └── presentation/     # Presentation layer (screens, widgets)
│   │   ├── home/                 # Home feature
│   │   ├── reports/              # Reports feature
│   │   ├── matches/              # Matches feature
│   │   └── profile/              # Profile feature
│   └── shared/                   # Shared components
│       ├── models/               # Shared data models
│       ├── providers/            # Shared providers
│       ├── services/             # Shared services
│       └── widgets/              # Shared widgets
├── generated/                     # Generated files
│   └── app_localizations.dart
├── l10n/                         # Localization files
│   ├── app_en.arb
│   └── app_es.arb
└── main.dart                     # App entry point
```

## 🏗️ Architecture Principles

### 1. **Feature-Driven Development (FDD)**

- Each feature is self-contained with its own data, domain, and presentation layers
- Features can be developed independently
- Easy to maintain and scale

### 2. **Clean Architecture**

- **Data Layer**: Repositories, data sources, models
- **Domain Layer**: Entities, use cases, repositories interfaces
- **Presentation Layer**: Screens, widgets, providers/controllers

### 3. **Separation of Concerns**

- **Core**: App-wide functionality (routing, theming, DI, etc.)
- **Features**: Business logic organized by feature
- **Shared**: Reusable components across features

## 🛠️ Key Technologies

- **Flutter**: Cross-platform mobile development
- **Riverpod**: State management and dependency injection
- **Go Router**: Declarative routing
- **Dio**: HTTP client for API calls
- **Get It**: Service locator for dependency injection
- **SQLite**: Local database storage
- **Shared Preferences**: Simple key-value storage
- **Flutter Secure Storage**: Secure storage for sensitive data

## 📱 Features

- **Authentication**: Login, signup, password reset
- **Reports**: Create, view, edit lost/found items
- **Matching**: AI-powered matching algorithm
- **Profile**: User profile management
- **Offline Support**: Offline-first architecture
- **Internationalization**: Multi-language support (EN, ES)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd apps/mobile
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**

   ```bash
   flutter run
   ```

## 📋 Development Guidelines

### Code Organization

- Follow the established folder structure
- Keep features independent and self-contained
- Use dependency injection for better testability
- Implement proper error handling

### State Management

- Use Riverpod for state management
- Create providers for each feature
- Keep state as close to where it's used as possible

### API Integration

- Use the centralized API service
- Implement proper error handling
- Use interceptors for common functionality (auth, logging, retry)

### Testing

- Write unit tests for business logic
- Write widget tests for UI components
- Write integration tests for user flows

## 🔧 Configuration

### Environment Variables

- API base URL
- Feature flags

### Build Variants

- Development
- Staging
- Production

## 📚 Documentation

- [API Documentation](../services/api/README.md)
- [Design System](./docs/design-system.md)
- [Testing Guide](./docs/testing.md)
- [Deployment Guide](./docs/deployment.md)

## 🤝 Contributing

1. Follow the established architecture patterns
2. Write tests for new features
3. Update documentation as needed
4. Follow the code style guidelines
5. Submit pull requests for review

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.
