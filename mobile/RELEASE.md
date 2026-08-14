# Roshab Tasks Mobile Release

## Included

- Android/iOS Flutter app with Material 3 dark UI
- Local task persistence
- Scheduled notifications and recurring Daily/Weekly reminders
- Calendar-style upcoming reminder list
- GPA calculator
- Attendance calculator
- Exam countdown
- Study notes
- Weekly timetable starter data
- Productivity chart and completion statistics
- Automatic local JSON backups with seven-backup retention
- Manual backup sharing
- JWT account registration/login and task sync API
- App icon source and splash configuration
- GitHub Actions Android APK and iOS builds
- Credential-gated signed Android APK workflow
- Credential-gated iOS signed IPA + TestFlight upload workflow

## Android signing secrets

Set these GitHub Actions repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

The unsigned/public build is still produced without these secrets. With the secrets configured, `mobile-release.yml` additionally produces `RoshabTasks-release.apk` signed by your release keystore.

## iOS signing/TestFlight secrets

Set these secrets for the signed iOS job:

- `IOS_CERTIFICATE_BASE64` — base64 encoded distribution `.p12`
- `IOS_P12_PASSWORD`
- `IOS_PROVISION_PROFILE_BASE64`
- `IOS_PROVISIONING_PROFILE_NAME`
- `IOS_TEAM_ID`
- `APPSTORE_KEY_ID`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_PRIVATE_KEY` — App Store Connect API private key contents

The workflow creates `ios/ExportOptions.plist`, builds the IPA, and uploads it through App Store Connect when these secrets are present.

## Cloud sync

The mobile client is in `mobile/lib/services/sync_service.dart` and the server is in `sync-server/`.

Start the server with:

```bash
cd sync-server
npm install
JWT_SECRET="replace-with-a-long-random-secret" npm start
```

Use HTTPS in production. Configure the resulting server URL and authenticated token in the mobile sync settings before enabling remote sync.

## Local testing

```bash
cd mobile
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze
flutter test
flutter run
```

The GitHub Actions QA workflow performs the same analysis and test commands automatically.
