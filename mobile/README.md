# Roshab Tasks Mobile 📱

Flutter mobile app foundation for **Roshab Tasks**, designed for Android and iOS.

## Included now

- Modern dark Material 3 UI
- Dashboard
- Task list with local persistence
- Student Hub
- Pomodoro focus screen
- GPA / attendance / exam / timetable / notes entry points
- Profile and developer branding
- Offline-first task storage with SharedPreferences

## Run locally

Install Flutter, then from this directory run:

```bash
flutter pub get
flutter create .
flutter run
```

`flutter create .` generates the Android and iOS platform folders while preserving the Dart app code.

## Build Android

```bash
flutter build apk --release
```

The APK will be created under `build/app/outputs/flutter-apk/`.

## Build iOS

On macOS with Xcode:

```bash
flutter build ios --release
```

Phone notifications/alarms will use the platform notification layer in the next mobile milestone.

## Developer

**Roshab Bhandari**
