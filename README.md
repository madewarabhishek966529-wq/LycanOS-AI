# LycanOS AI — Frontend

Flutter client for LycanOS AI. Phase 1 delivers the app skeleton: theming,
routing with auth-aware redirects, dependency injection, the network
client (with token-refresh handling already wired), and a navigable shell
across all eight planned modules — everything later phases fill in with
real data and logic.

## Stack

- Flutter (Material 3) + Riverpod for state management
- GoRouter for navigation, with a `ShellRoute` for the authenticated
  NavigationRail/NavigationBar layout
- Dio for networking, Hive + Drift for offline-first local storage (Drift
  is added when Inventory/POS need relational offline queries)
- `flutter_secure_storage` for tokens
- `responsive_framework` for breakpoint-aware layout
- fl_chart, pdf/printing, mobile_scanner — wired in as their owning phases
  (Dashboard, Reports, POS) land

## Project layout

```
lib/
  main.dart            # bootstrap: Hive init, ProviderScope
  app.dart             # MaterialApp.router, theming, responsive breakpoints
  core/
    config/            # EnvConfig — dart-define driven environment values
    constants/         # AppConstants — box names, storage keys, roles
    theme/             # AppColors, AppTextStyles, AppTheme (light/dark)
    routes/            # RouteNames, AppRouter (auth-aware redirect logic)
    network/           # DioClient (auth header + refresh interceptor), ApiEndpoints
    errors/             # Failure/Exception hierarchy + Result<T>
    di/                 # Riverpod providers for core singletons
  shared/
    widgets/            # AppButton, AppTextField, GlassCard, AppShell, LoadingIndicator
  features/
    auth/ dashboard/ pos/ inventory/ customers/ employees/ reports/
    ai_assistant/ settings/
      domain/{entities,repositories,usecases}
      data/{models,datasources,repositories}
      presentation/{providers,screens,widgets}
```

Each feature follows Clean Architecture: `domain` is pure Dart (no Flutter
imports) defining entities and repository contracts; `data` implements
those contracts against Dio/Hive/Drift; `presentation` holds Riverpod
providers and widgets. Models are hand-written rather than Freezed-first
where a feature is still simple, to avoid a `build_runner` dependency
holding up early phases — Freezed is available in `pubspec.yaml` for
features (like POS invoices) where the generated equality/copyWith
actually earns its build-time cost.

## Local setup

Requires the Flutter SDK (stable channel) — this sandbox doesn't have
network access to pub.dev, so packages haven't been fetched here; run
these on your machine:

```bash
flutter pub get
flutter run -d chrome        # or -d windows / -d linux / -d macos / an Android device
```

Point the app at your local backend (see `../backend/README.md`) via
`--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## Tests

```bash
flutter test
```

Phase 1 ships 2 widget tests: the app boots to the splash screen, and an
unauthenticated session correctly redirects to `/login`.

## What's deliberately not here yet

- Login/register don't call the backend — the form validates and is fully
  wired for Phase 2, but submission just confirms validation for now
- Every non-auth screen (Dashboard, POS, Inventory, ...) is a real, styled
  empty state rather than a blank page, so the nav shell is demoable, but
  no feature logic lives there until its phase
- Drift (SQLite) isn't initialized yet — added in Phase 4 (Inventory) once
  there's an actual schema to define

  
