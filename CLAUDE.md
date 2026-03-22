# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter pub get              # Install dependencies
flutter analyze              # Lint/static analysis (must pass with no issues)
flutter test                 # Run tests
flutter run                  # Run on connected device/emulator
flutter run --release        # Run release build (faster, no debugger)
flutter run --dart-define=HF_TOKEN=hf_xxx  # Run with HuggingFace token
flutter build apk --release  # Build APK
```

## Architecture

Provider-based Flutter app with a service layer. All services are registered as providers in `main.dart` and injected into screens/providers via `context.read<T>()`.

### Startup Flow
`main.dart` → `_AppStartup` initializes `LlmService` → if model installed: `HomeScreen`, if not: `SettingsScreen`. All initialization has timeouts to prevent hangs.

### Service Layer (`lib/services/`)
- **LlmService**: On-device LLM via `flutter_gemma`. Handles model install, GPU/CPU loading with fallback, chat sessions, streaming responses, and vision (image input). Model loading has 90s timeout.
- **SearchService**: DuckDuckGo web + news search. Formats results for LLM context injection.
- **WeatherService**: Open-Meteo API (free, no key). Returns Dutch weather descriptions.
- **TtsService** / **SpeechService**: Dutch TTS (nl-NL, rate 0.45) and STT (nl_NL, dictation mode).

### State Management (`lib/providers/`)
`ChatProvider` (ChangeNotifier) is the core state manager. Created per chat session (scoped to `ChatScreen`). Key behavior:
- **Smart query routing**: Detects query type (weather/news/general) via keyword matching in `_detectQueryType()`, fetches appropriate context, injects it into the LLM prompt.
- **Auto-search**: Every non-chat message triggers a web search for context (skipped for "kletsen" category).
- **Auto-speak**: When enabled, reads responses aloud via TTS, then triggers auto-listen callback for hands-free conversation.

### Model Configuration (`lib/config/constants.dart`)
`AppConstants.availableModels` defines downloadable models with URL, size, `ModelType`, vision support, and token requirements. Models without HuggingFace account are listed first. System prompts are per-category in `categoryPrompts` map.

### Key Design Decisions
- **CPU fallback**: GPU loading can fail with stale cache files after app data clear. `loadModel()` tries GPU first, auto-falls back to CPU and remembers the preference via `shared_preferences`.
- **Token storage**: HuggingFace token stored encrypted via `flutter_secure_storage`. Priority: `--dart-define` env var > secure storage > manual input.
- **System prompt injection**: Prepended to the first user message only (not as a separate chat turn), keeping prompt size small for on-device models.
- **Search result truncation**: Snippets capped at 150 chars, max 2 results, to minimize prompt size for small models.

## Language & UI
All UI text and AI system prompts are in **Dutch**. The app targets elderly users: large text (body 20sp, headings 28sp), large touch targets (min 64x64), high contrast theme defined in `lib/config/theme.dart`. The "Gezellig kletsen" category uses a distinct pink/warm color scheme.
