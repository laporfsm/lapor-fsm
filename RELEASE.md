# Release Guide (Lapor FSM)

This checklist helps prepare a clean release for both backend and mobile apps.

## 1) Pre-Release Checklist
- Remove secrets from the repo and CI logs.
- Ensure `.env.example` is up to date with all required variables.
- Verify no user uploads or build artifacts are committed.
- Confirm dependency locks are present (`mobile/pubspec.lock`, `backend/bun.lock`).
- Run migrations and verify critical flows in staging.

## 2) Mobile Release

### Versioning
Update the version in `mobile/pubspec.yaml` before release.
Example: `version: 1.0.0+3`

### Android (AAB)
```bash
cd mobile
flutter pub get
flutter build appbundle --release
```

### iOS (IPA)
```bash
cd mobile
flutter pub get
flutter build ipa --release
```

### Signing
Ensure Android signing files are present:
- `mobile/android/key.properties`
- `mobile/android/app/<your-keystore>.jks`

Example `key.properties`:
```properties
storeFile=app/your-keystore.jks
storePassword=your-store-password
keyAlias=your-key-alias
keyPassword=your-key-password
```

## 3) Final Verification
- Install release builds on real devices.
- Verify login, report creation, upload, notifications, and exports.
- Confirm API base URL in `mobile/lib/core/services` points to production.
