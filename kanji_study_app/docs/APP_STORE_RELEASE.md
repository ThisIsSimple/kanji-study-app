# App Store Release Checklist

Last updated: 2026-05-21

## Release Blockers

- Create or update the Firebase iOS app with bundle ID `space.cordelia273.konnakanji`, then replace `ios/Runner/GoogleService-Info.plist` from Firebase Console. The checked-in plist bundle ID has been aligned, but the Google app record should still be verified in the console.
- Deploy `supabase/functions/delete-user-account` before submitting a build that exposes Sign in with Apple. The app calls this function from Settings > Account Management > Delete Account.
- Publish a public privacy policy URL and enter it in App Store Connect. Apple marks Privacy Policy URL as required for iOS apps.
- Confirm Supabase RLS policies only allow users to read/write/delete their own rows in user-scoped tables.
- Run a TestFlight build on a physical iPhone and complete OAuth callbacks for Apple, Google, and Kakao.

## App Store Connect Privacy Label Draft

Use Apple App Privacy as the source of truth and adjust if backend behavior changes.

| Data type | Collected | Linked to user | Tracking | Purpose |
| --- | --- | --- | --- | --- |
| Email Address | Yes, for social login users | Yes | No | App Functionality |
| User ID | Yes, Supabase auth ID | Yes | No | App Functionality |
| Product Interaction | Yes, study records, favorites, quiz attempts | Yes | No | App Functionality |
| Other User Content | Yes, user-generated or AI-generated examples saved to the account | Yes | No | App Functionality |
| Diagnostics | No known custom collection | No | No | N/A |
| Location | No | No | No | N/A |
| Contacts | No | No | No | N/A |
| Identifiers for tracking | No | No | No | N/A |

Notes:

- The app does not include advertising SDKs or App Tracking Transparency usage.
- Gemini API keys are stored on-device through shared preferences and are not sent to this app's backend.
- Supabase, Google, Apple, Kakao, and Google ML Kit SDK privacy practices must be reviewed against their current SDK documentation before final submission.

## iOS Native Configuration

- Bundle ID: `space.cordelia273.konnakanji`
- Display name: `콘나칸지`
- Supported orientations currently include portrait and landscape for iPhone/iPad. Keep this only if QA confirms layout quality in landscape.
- `UIBackgroundModes` was removed because the app currently uses local scheduled notifications and no push/background fetch workflow was found.
- `PrivacyInfo.xcprivacy` declares:
  - No tracking.
  - Email address, user ID, product interaction, and other user content for app functionality.
  - `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` for app-only preferences.

## Account Deletion Backend

Deploy from the project root after linking the Supabase project:

```bash
supabase functions deploy delete-user-account
```

Required function secrets:

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...
```

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are normally available in the Edge Function environment. If they are not, set them explicitly.

The function verifies the caller's JWT, deletes user-scoped rows, deletes the profile row from `users`, and then deletes the Supabase Auth user through the admin API.

## Validation Commands

Run these before archive:

```bash
flutter pub get
flutter analyze
flutter test
cd ios && pod install
cd .. && flutter build ios --release
```

This workspace currently does not have `flutter` on `PATH`, so validation must run on a machine/session where Flutter is installed.

## Flutter 3.44 Build Notes

- `google_fonts` must be at least `6.3.3`; `6.3.0` fails with a `FontWeight` constant evaluation error on newer Flutter/Dart toolchains.
- `phosphor_flutter` on pub.dev is still `2.1.0` and extends `IconData`, which fails after Flutter marked `IconData` as final. This repo uses `third_party/phosphor_flutter` as a narrow compatibility shim for the icons currently referenced by the app.
- After pulling these changes, run `flutter pub get` so `pubspec.lock` records the local `phosphor_flutter` override and the newer `google_fonts` version.

## Manual QA

- First launch, guest login, logout.
- Apple, Google, and Kakao login on physical device.
- OAuth deep link callback into `space.cordelia273.konnakanji://login-callback`.
- Offline app start with cached kanji/word data.
- Study record creation, favorites, flashcard history, AI quiz flow.
- Gemini API key add/remove and AI unavailable state.
- Notification opt-in, daily reminder scheduling, permission denied state.
- Settings > Privacy data disclosure screen.
- Settings > Account Management > Delete Study Data.
- Settings > Account Management > Delete Account after Edge Function deployment.

## Official References

- App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- App Store Connect App Privacy: https://developer.apple.com/help/app-store-connect/reference/app-privacy/
- Privacy Manifests: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Required Reason API: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
