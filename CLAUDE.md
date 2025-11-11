# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based Japanese Kanji study application with a Python data processing backend. The app helps users systematically learn 2136 kanji characters with features like daily notifications, progress tracking, cloud sync via Supabase, and AI-generated examples using Gemini API.

## Development Commands

### Code Validation (IMPORTANT for Claude Code)

**⚠️ CRITICAL**: The user keeps `flutter run` running continuously. **NEVER use `flutter run` for code validation.**

Use these commands instead for validating changes:

1. **Primary Validation** - Static Analysis (fastest):
   ```bash
   cd kanji_study_app
   flutter analyze
   ```
   - Checks for errors, warnings, and lint issues
   - No impact on running app
   - Completes in seconds

2. **Code Formatting Check**:
   ```bash
   dart format --set-exit-if-changed lib/
   ```
   - Verifies code formatting compliance
   - Use `dart format lib/` to auto-format

3. **Build Verification** (if structural changes):
   ```bash
   flutter build ios --debug
   # or
   flutter build apk --debug
   ```
   - Validates compilation without running
   - Use sparingly (slower than analyze)

4. **Run Tests** (when tests exist):
   ```bash
   flutter test
   ```

**Workflow for Code Changes**:
1. Make code changes
2. Run `flutter analyze` to validate
3. Fix any issues reported
4. Let user test in their running app (hot reload handles updates)

### Flutter App Commands
```bash
# Navigate to app directory
cd kanji_study_app

# Install dependencies
flutter pub get

# Run the app (iOS Simulator or Android Emulator)
# ⚠️ NOTE: User typically keeps this running - don't use for validation
flutter run

# Run on specific device
flutter run -d [device_id]

# Build for iOS
flutter build ios

# Build for Android
flutter build apk

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Format code
dart format lib/
```

### Python Data Processing Commands
```bash
# Install Python dependencies
pip install -r data_processing/requirements.txt
pip install -r kanji_study_app/scripts/requirements.txt

# Data migration scripts (in kanji_study_app/scripts/)
python insert_excel_to_supabase.py  # Insert Excel data to Supabase
python cross_validate_data.py       # Validate data integrity
```

## Architecture Overview

### Flutter App Architecture

The app follows a layered architecture with clear separation of concerns:

1. **Presentation Layer** (`lib/screens/`)
   - `main_screen.dart` - Bottom navigation controller
   - Screen types: Home, Kanji, Words, Quiz, Profile, Auth, Study
   - Calendar and detail screens for study tracking

2. **Business Logic Layer** (`lib/services/`)
   - `kanji_service.dart` & `kanji_repository.dart` - Kanji data management
   - `word_service.dart` - Word/vocabulary management  
   - `supabase_service.dart` - Cloud sync and authentication (singleton pattern)
   - `gemini_service.dart` - AI example generation
   - `notification_service.dart` - Daily study reminders

3. **Data Layer** (`lib/models/`)
   - Domain models for Kanji, Words, Quiz, User Progress
   - Study records and daily statistics tracking

4. **UI Components** (`lib/widgets/`)
   - Custom widgets for furigana text rendering
   - Word list items with rich interaction

5. **Configuration** (`lib/config/`)
   - Supabase configuration and environment setup

### State Management
- **SharedPreferences** for local persistence
- **Singleton Services** for app-wide state
- **Supabase** for cloud state synchronization

### Key Design Patterns
- **Repository Pattern**: Data access abstraction (kanji_repository.dart)
- **Service Pattern**: Business logic encapsulation
- **Singleton Pattern**: Service instances (Supabase, Notification, Gemini)

### Database Architecture

**Supabase Tables**:
- `users` - User profiles with nicknames
- `kanji` - Master kanji data (2136 characters)
- `words` - JLPT vocabulary with meanings
- `study_records` - User study history
- `quiz_sets`, `quiz_questions`, `quiz_attempts` - Quiz system

**Local Storage**:
- `assets/data/kanji_data.json` - Offline kanji database
- SharedPreferences for user settings and progress

### Authentication Flow
1. Anonymous authentication on first launch
2. Auto-generated Korean nicknames for users
3. Profile sync with Supabase
4. Session persistence across app restarts

## Important Dependencies

### Flutter Packages
- `forui: ^0.16.0` - UI component library (zinc theme)
- `supabase_flutter: ^2.9.1` - Backend integration
- `flutter_gemini: ^3.0.0` - AI example generation
- `flutter_local_notifications: ^19.4.0` - Study reminders
- `table_calendar: ^3.1.2` - Study calendar view
- `ruby_text: ^3.0.3` - Furigana rendering

### Custom Fonts
- **SUITE**: Korean font family (Light to Heavy weights)
- **KanjiStrokeOrders**: Stroke order display font for kanji characters
  - Located: `assets/fonts/KanjiStrokeOrders_v4.005.ttf`
  - **CRITICAL**: When using this font, follow these requirements:
    - **Minimum font size**: 100pt or larger (stroke order numbers won't show below this)
    - **Font weight**: DO NOT use `FontWeight.bold` - use `FontWeight.normal` only
    - **Reason**: Bold weight obscures the stroke order numbers embedded in the font
    - Each stroke displays a small number indicating the proper writing sequence

### Python Dependencies
- `supabase>=2.0.0` - Database operations
- `pandas` & `openpyxl` - Excel data processing

## Testing Approach

- Unit tests in `test/` directory
- Run with `flutter test`
- Widget testing for UI components
- Integration testing with Supabase test environment

## Deployment Considerations

1. **Environment Variables**: Supabase URL and keys in `supabase_config.dart`
2. **API Keys**: Gemini API key configuration required
3. **iOS**: Notification permissions in Info.plist
4. **Android**: Minimum API level 23 (Android 6.0)

## Data Processing Pipeline

1. **Source**: Excel files with kanji data
2. **Processing**: Python scripts in `data_processing/` and `kanji_study_app/scripts/`
3. **Validation**: Cross-validation scripts ensure data integrity
4. **Storage**: Supabase for cloud, JSON for offline

## UI/UX Conventions

- **Theme**: Forui zinc theme with light/dark support
- **Typography**: SUITE font family for Korean, Noto Serif Japanese for kanji
- **Icons**: Phosphor Flutter icon set
- **Navigation**: Bottom navigation with 5 main sections
- **Colors**: Consistent use of FTheme colors (primary, muted, background)

## Code Style Guidelines

- Follow Flutter lints defined in `analysis_options.yaml`
- Use `dart format` before committing
- Prefer const constructors where possible
- Maintain singleton pattern for services
- Use async/await for all asynchronous operations