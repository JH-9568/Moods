## Environment Variables And Secrets

| Key | Used In | Purpose | Notes |
| --- | --- | --- | --- |
| `API_BASE_URL` | `lib/common/constants/api_constants.dart:2` | Backend REST endpoint for custom HTTP clients (record, auth, calendar, etc.) | Loaded via `.env` / `flutter_dotenv`. |
| `SUPABASE_URL` | `lib/main.dart:17` | Supabase project URL required during `Supabase.initialize` | Required; app throws if missing. |
| `SUPABASE_ANON_KEY` | `lib/main.dart:18` | Supabase anonymous API key (grants database access) | Required alongside `SUPABASE_URL`. |
| `KAKAO_NATIVE_APP_KEY` | `lib/main.dart:26`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | Kakao OAuth login initialization and deep-link scheme | Dart side loads from `.env`; Android/iOS should read from manifest placeholders or config files that you keep out of git. |
| `MAPS_API_KEY` | `lib/features/record/view/map_view.dart:13` | Google Maps/Places/Geocoding REST calls | Optional per-platform overrides `MAPS_API_KEY_ANDROID`/`MAPS_API_KEY_IOS` for native layers. |
| `GOOGLE_PLACES_API_KEY` (if different from Maps) | `lib/features/record/view/map_view.dart` HTTP calls | Optional separate key limited to Places API scopes | Declare only if you split usage; otherwise reuse `MAPS_API_KEY`. |
| `SECURE_STORAGE_KEY_PREFIX` or other storage salts (future) | `lib/features/auth/service/token_storage.dart` | Harmonize SecureStorage names when environment-specific behavior is needed | Not present yet, but define once you introduce per-environment SecureStorage isolation. |

### Recommended .env Layout

```
# Copy .env.example → .env and fill the blanks
API_BASE_URL=https://api.your-domain.com
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=***
KAKAO_NATIVE_APP_KEY=***
MAPS_API_KEY=***
MAPS_API_KEY_ANDROID=***    # optional override for Android native manifest
MAPS_API_KEY_IOS=***        # optional override for iOS Info.plist
# Any other service specific keys...
```

Flutter automatically loads `.env` at startup via `flutter_dotenv`. In CI you can also supply the same values with `--dart-define` (all lookups fall back to `String.fromEnvironment`). Native platform keys can be templated via Gradle/Xcode build configs; if they differ per platform use `MAPS_API_KEY_ANDROID` / `MAPS_API_KEY_IOS`.

### Platform Sync

- **Android**: `android/app/build.gradle.kts` reads `.env` and injects `MAPS_API_KEY[_ANDROID]` plus the Kakao scheme into the manifest via placeholders (`${MAPS_API_KEY}`, `${KAKAO_SCHEME}`).
- **iOS**: run `scripts/sync_env.sh` whenever `.env` changes to materialize `ios/Flutter/Env.xcconfig` (git-ignored). The xcconfig exports `MAPS_API_KEY_IOS`, `KAKAO_NATIVE_APP_KEY`, and `KAKAO_URL_SCHEME` so that `Info.plist` can reference them.

### Git Ignore Guidance

`.env`, `.env.*`, and any `*.secrets` helper files should remain out of version control (already added in `.gitignore`). When sharing required values with the team, create a sanitized `env.example` that mirrors the table above but replaces secrets with placeholders.
