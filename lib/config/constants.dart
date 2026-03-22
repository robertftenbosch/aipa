import 'package:flutter_gemma/flutter_gemma.dart';

class ModelConfig {
  final String name;
  final String description;
  final String url;
  final String size;
  final ModelType modelType;
  final bool requiresToken;
  final bool supportsVision;

  const ModelConfig({
    required this.name,
    required this.description,
    required this.url,
    required this.size,
    required this.modelType,
    this.requiresToken = false,
    this.supportsVision = false,
  });
}

class AppConstants {
  static const String appName = 'AIPA';
  static const String appSubtitle = 'Uw Digitale Hulp';

  static const int maxTokens = 512;

  static const List<ModelConfig> availableModels = [
    // --- Geen account nodig ---
    ModelConfig(
      name: 'Qwen 2.5 1.5B',
      description: 'Goed Nederlands, geen account nodig. Aanbevolen!',
      url: 'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
      size: '1.6 GB',
      modelType: ModelType.qwen,
    ),
    ModelConfig(
      name: 'Qwen3 0.6B',
      description: 'Heel klein en snel, basis Nederlands',
      url: 'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
      size: '586 MB',
      modelType: ModelType.qwen,
    ),
    ModelConfig(
      name: 'DeepSeek R1 1.5B',
      description: 'Goed in redeneren, geen account nodig',
      url: 'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv1280.task',
      size: '1.9 GB',
      modelType: ModelType.deepSeek,
    ),
    ModelConfig(
      name: 'Phi-4 Mini 3.9B',
      description: 'Groot en slim, geen account nodig',
      url: 'https://huggingface.co/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct_multi-prefill-seq_q8_ekv1280.task',
      size: '3.9 GB',
      modelType: ModelType.general,
    ),
    // --- HuggingFace account nodig ---
    ModelConfig(
      name: 'Gemma 3 1B',
      description: 'Klein, snel, goed Nederlands',
      url: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
      size: '529 MB',
      modelType: ModelType.gemmaIt,
      requiresToken: true,
    ),
    ModelConfig(
      name: 'Gemma 3n E2B + Vision',
      description: "Foto's analyseren, goed Nederlands",
      url: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
      size: '3.7 GB',
      modelType: ModelType.gemmaIt,
      requiresToken: true,
      supportsVision: true,
    ),
    ModelConfig(
      name: 'Gemma 3n E4B + Vision',
      description: "Beste Nederlands + foto's. Groot maar krachtig",
      url: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
      size: '4.4 GB',
      modelType: ModelType.gemmaIt,
      requiresToken: true,
      supportsVision: true,
    ),
  ];

  static const String baseSystemPrompt =
      'Je bent AIPA, een vriendelijke assistent die ouderen helpt met technologie. '
      'Antwoord in het Nederlands. Gebruik eenvoudige taal, geen jargon. '
      'Geef stap-voor-stap instructies, maximaal 3 stappen per keer. '
      'Wees geduldig en bemoedigend.';

  static const Map<String, String> categoryPrompts = {
    'tv': '''
De gebruiker heeft hulp nodig met het aansluiten of bedienen van een televisie. Begin met te vragen welk merk TV ze hebben en wat precies het probleem is.''',
    'internet': '''
De gebruiker heeft hulp nodig met internet. Begin met te vragen of ze een nieuw modem/router hebben ontvangen of dat hun bestaand internet niet werkt.''',
    'telefoon': '''
De gebruiker heeft hulp nodig met hun telefoon. Vraag of het om een smartphone (Samsung, iPhone) of een gewone telefoon gaat, en wat ze willen doen.''',
    'anders': '''
De gebruiker heeft een algemene vraag over technologie. Vraag vriendelijk waarmee u kunt helpen.''',
    'kletsen': '''
Dit is een gezellig gesprek. Je bent een warme, vriendelijke gesprekspartner.
REGELS:
- Stel vragen over hun dag, hobby's, herinneringen, familie, het weer.
- Luister goed en reageer persoonlijk op wat ze vertellen.
- Deel af en toe een leuk weetje, spreekwoord of mop.
- Houd het luchtig en positief.
- Geef GEEN technische hulp tenzij ze erom vragen.
- Wees oprecht geinteresseerd. Vraag door op details.
- Gebruik een warme, persoonlijke toon alsof je op visite bent.''',
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
