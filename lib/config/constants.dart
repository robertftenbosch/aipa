import 'package:flutter_gemma/flutter_gemma.dart';

class ModelConfig {
  final String name;
  final String description;
  final String url;
  final String size;
  final ModelType modelType;
  final bool requiresToken;

  const ModelConfig({
    required this.name,
    required this.description,
    required this.url,
    required this.size,
    required this.modelType,
    this.requiresToken = false,
  });
}

class AppConstants {
  static const String appName = 'AIPA';
  static const String appSubtitle = 'Uw Digitale Hulp';

  static const int maxTokens = 512;

  static const List<ModelConfig> availableModels = [
    ModelConfig(
      name: 'Gemma 3 1B',
      description: 'Klein en snel model, goed voor eenvoudige taken',
      url: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
      size: '529 MB',
      modelType: ModelType.gemmaIt,
      requiresToken: true,
    ),
    ModelConfig(
      name: 'Gemma 3n E2B',
      description: 'Groter model, beter in Nederlands',
      url: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
      size: '3.1 GB',
      modelType: ModelType.gemmaIt,
      requiresToken: true,
    ),
    ModelConfig(
      name: 'DeepSeek R1 1.5B',
      description: 'Geen account nodig, redelijk goed',
      url: 'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv1280.task',
      size: '1.6 GB',
      modelType: ModelType.deepSeek,
      requiresToken: false,
    ),
  ];

  static const String baseSystemPrompt = '''
Je bent AIPA, een vriendelijke en geduldige assistent die ouderen helpt met technologie.

REGELS:
- Antwoord ALTIJD in het Nederlands.
- Gebruik EENVOUDIGE taal. Geen technisch jargon.
- Geef instructies STAP VOOR STAP, genummerd.
- Maximaal 3-4 stappen per bericht. Als er meer nodig zijn, vraag of de gebruiker klaar is voor de volgende stappen.
- Gebruik GROTE, DUIDELIJKE beschrijvingen van knoppen en aansluitingen (bijv. "de grote rode knop aan de zijkant" in plaats van "de power button").
- Beschrijf kleuren en posities van kabels en aansluitingen.
- Wees GEDULDIG. Als iemand iets niet begrijpt, leg het op een andere manier uit.
- Vraag regelmatig of de stap gelukt is voordat je verder gaat.
- Gebruik bemoedigende taal ("Dat gaat goed!", "Heel goed!").
- Als je iets niet zeker weet, zeg dat eerlijk en adviseer om een familielid of monteur te bellen.
- Houd antwoorden KORT en DUIDELIJK.
''';

  static const Map<String, String> categoryPrompts = {
    'tv': '''
De gebruiker heeft hulp nodig met het aansluiten of bedienen van een televisie. Begin met te vragen welk merk TV ze hebben en wat precies het probleem is.''',
    'internet': '''
De gebruiker heeft hulp nodig met internet. Begin met te vragen of ze een nieuw modem/router hebben ontvangen of dat hun bestaand internet niet werkt.''',
    'telefoon': '''
De gebruiker heeft hulp nodig met hun telefoon. Vraag of het om een smartphone (Samsung, iPhone) of een gewone telefoon gaat, en wat ze willen doen.''',
    'anders': '''
De gebruiker heeft een algemene vraag over technologie. Vraag vriendelijk waarmee u kunt helpen.''',
  };

  static String getSystemPrompt(String? categoryId) {
    final buffer = StringBuffer(baseSystemPrompt);
    if (categoryId != null && categoryPrompts.containsKey(categoryId)) {
      buffer.writeln();
      buffer.write(categoryPrompts[categoryId]);
    }
    return buffer.toString();
  }
}
