# Subly — Subscription Tracker

A simple app to track recurring subscriptions, see total monthly spend,
and get a visual warning as renewals approach. All data stays on the
device (no server, no account, no internet needed).

## What's included

- `lib/main.dart` — app entry point
- `lib/models/subscription.dart` — data model
- `lib/services/storage_service.dart` — local save/load (shared_preferences)
- `lib/screens/home_screen.dart` — main list + total spend
- `lib/screens/add_subscription_screen.dart` — add/edit form

## Running it yourself

You'll need Flutter installed on your own computer (this can't be
compiled or tested from within this chat).

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Open this folder in Android Studio or VS Code (with the Flutter
   extension).
3. In a terminal, inside this folder, run:
   ```
   flutter pub get
   flutter run
   ```
4. This launches the app on a connected device or emulator.

## Making it your own

Easy first changes:
- App name/colors: edit `SublyApp` in `main.dart` (try a different
  `seedColor`).
- Rename the app: change `name:` in `pubspec.yaml`, plus the Android
  app label in `android/app/src/main/AndroidManifest.xml` once you
  generate platform folders (see below).
- Add push notification reminders: the `flutter_local_notifications`
  package is the standard choice for scheduling a local alert a few
  days before `renewalDate`.

Note: this project currently only has the `lib/` (Dart) source. The
first time you run `flutter create .` inside this folder, Flutter will
generate the `android/`, `ios/`, and other platform folders needed to
build and run — do this before your first `flutter run`.

## Publishing to Google Play

1. Create a Google Play Developer account (one-time $25 fee):
   https://play.google.com/console/signup
2. Build a release app bundle:
   ```
   flutter build appbundle
   ```
   The output lands in `build/app/outputs/bundle/release/`.
3. In Play Console: create a new app, fill in the store listing
   (title, description, screenshots, icon), upload the `.aab` file,
   and set your pricing/country availability.
4. You'll also need a privacy policy URL — since this app stores data
   only locally, a short one-paragraph policy stating "this app does
   not collect or transmit any personal data" is enough; host it as a
   simple page (e.g. a free GitHub Pages site).
5. Submit for review. First reviews typically take a few hours to a
   few days.

## New features added

### 1. Renewal reminders (push notifications)
Schedules a local notification 3 days before each subscription renews.
Fully on-device — no server involved.

**Setup after running `flutter create .`:**
- Android: add this permission to `android/app/src/main/AndroidManifest.xml`
  (inside the `<manifest>` tag, above `<application>`):
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  ```
- The app requests notification permission on first launch (Android 13+
  requires this explicitly).

### 2. CSV export
Tap the share icon in the top bar to export all subscriptions as a CSV
file through the native share sheet (email, Drive, Files, etc). No
extra manifest setup needed — `share_plus` handles this automatically.

### 3. Pro upgrade (one-time unlock)
Free tier is capped at 5 subscriptions. The premium icon in the top
bar (or hitting the limit) opens an upgrade dialog for a one-time
"Subly Pro" purchase that unlocks unlimited tracking.

**This needs setup before it works — in-app purchases can't be tested
in a bare debug build:**
1. Add the billing permission — `in_app_purchase` merges this into
   the manifest automatically, but double check
   `android/app/src/main/AndroidManifest.xml` contains:
   ```xml
   <uses-permission android:name="com.android.vending.BILLING"/>
   ```
2. Upload at least one signed build to Play Console (the internal
   testing track is enough to start).
3. In Play Console, go to **Monetize → Products → In-app products**
   and create a **non-consumable** product with the exact ID:
   `subly_pro_unlock`. Set its price.
4. Add a **license tester** account (Play Console → Setup → License
   testing) — regular Google accounts can't test real purchases
   without being charged.
5. Install the app via the internal testing link on a test device
   signed into the license tester account, then try the upgrade flow.

Until this is set up, tapping upgrade shows a friendly placeholder
message instead of crashing.

## Further ideas
- Custom categories/tags
- Home-screen widget showing total spend
- A "restore purchases" button for users who reinstall the app
  (the `PurchaseService.restorePurchases()` method is already there —
  just wire a button to it)
