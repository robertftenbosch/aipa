# AIPA - AI Personal Assistent

Een Flutter-app die ouderen helpt met technologie. De AI draait volledig op het device (geen cloud nodig) en biedt stapsgewijze begeleiding in eenvoudig Nederlands via tekst en spraak.

## Features

- **On-device AI** — Draait lokaal via [flutter_gemma](https://pub.dev/packages/flutter_gemma), geen internet nodig na installatie
- **Spraakgestuurd** — Praat tegen de app, de app praat terug (spraakherkenning + text-to-speech)
- **Gespreksmodus** — Automatisch voorlezen en luisteren voor een hands-free ervaring
- **Vision AI** — Maak een foto van bijv. de achterkant van een TV en de AI helpt kabels herkennen (Gemma 3n E4B model)
- **Internet zoeken** — AI zoekt automatisch op het web via DuckDuckGo voor actuele informatie
- **Gezellig kletsen** — Anti-eenzaamheid: de AI voert een warm, persoonlijk gesprek
- **Senior-friendly UI** — Grote knoppen, grote tekst, hoog contrast, eenvoudige navigatie

## Screenshots

De app heeft twee schermen:

**Hoofdmenu** — Kies een categorie of stel direct een vraag

| Categorie | Beschrijving |
|-----------|-------------|
| TV | Hulp bij het aansluiten of bedienen van een televisie |
| Internet | Hulp bij modem, router of wifi-problemen |
| Telefoon | Hulp bij smartphone of gewone telefoon |
| Andere vraag | Algemene technologievragen |
| Gezellig kletsen | Een gezellig praatje met de AI |

**Chatscherm** — Gesprek met de AI via tekst of spraak

## Installatie

### Vereisten

- [Flutter](https://docs.flutter.dev/get-started/install) 3.41+
- Android Studio of VS Code
- Android device of emulator (6GB+ RAM aanbevolen)

### Starten

```bash
# Clone de repository
git clone https://github.com/robertftenbosch/aipa.git
cd aipa

# Dependencies installeren
flutter pub get

# App starten
flutter run
```

### Met HuggingFace token (voor Gemma modellen)

```bash
flutter run --dart-define=HF_TOKEN=hf_jouw_token_hier
```

Of stel het in via Android Studio: **Run** > **Edit Configurations** > **Additional run args**

## AI Modellen

Bij de eerste start kies je een model dat eenmalig wordt gedownload:

| Model | Grootte | Vision | Token nodig | Beschrijving |
|-------|---------|:------:|:-----------:|-------------|
| **Gemma 3n E4B + Vision** | 4.4 GB | Ja | Ja | Kan foto's analyseren. Aanbevolen! |
| Gemma 3 1B | 529 MB | Nee | Ja | Klein en snel |
| Gemma 3n E2B | 3.1 GB | Nee | Ja | Groter, beter in Nederlands |
| DeepSeek R1 1.5B | 1.6 GB | Nee | Nee | Geen account nodig |

Voor Gemma modellen heb je een gratis [HuggingFace](https://huggingface.co) account nodig. Accepteer de [Gemma licentie](https://huggingface.co/google/gemma-3n-E4B-it-litert-preview) en maak een [token](https://huggingface.co/settings/tokens) aan.

## Projectstructuur

```
lib/
├── main.dart                     # App entry point + model download scherm
├── config/
│   ├── theme.dart                # Senior-friendly thema
│   └── constants.dart            # Systeem prompts, model configuratie
├── models/
│   ├── chat_message.dart         # Chat bericht model
│   └── task_category.dart        # Categorieen (TV, Internet, Kletsen, etc.)
├── services/
│   ├── llm_service.dart          # On-device LLM (flutter_gemma)
│   ├── speech_service.dart       # Spraakherkenning (nl-NL)
│   ├── search_service.dart       # DuckDuckGo web search
│   └── tts_service.dart          # Text-to-speech (Nederlands)
├── providers/
│   └── chat_provider.dart        # Chat state management
├── screens/
│   ├── home_screen.dart          # Hoofdmenu met categorieknoppen
│   └── chat_screen.dart          # Chat interface
└── widgets/
    ├── category_button.dart      # Categorie knop
    ├── chat_bubble.dart          # Chat bericht + typing indicator
    ├── voice_button.dart         # Microfoon knop
    └── message_input.dart        # Tekst invoer + camera + zoeken
```

## Tech Stack

- **Flutter** — Cross-platform (Android, iOS, Web)
- **flutter_gemma** — On-device LLM inference via MediaPipe
- **Provider** — State management
- **speech_to_text** — Spraakherkenning (Nederlands)
- **flutter_tts** — Text-to-speech (Nederlands)
- **image_picker** — Camera en fotobibliotheek
- **duckduckgo_search** — Web search (geen API key nodig)
- **flutter_secure_storage** — Versleutelde opslag voor tokens

## Beveiliging

- HuggingFace tokens worden versleuteld opgeslagen via `flutter_secure_storage` (Android: EncryptedSharedPreferences, iOS: Keychain)
- Tijdens development kan het token via `--dart-define=HF_TOKEN=...` worden meegegeven
- Het AI model draait volledig lokaal — geen data wordt naar externe servers gestuurd

## Licentie

Dit project is bedoeld voor persoonlijk gebruik.
