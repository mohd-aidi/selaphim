enum AIProvider { openai, gemini, claude }

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI (ChatGPT)';
      case AIProvider.gemini:
        return 'Google Gemini';
      case AIProvider.claude:
        return 'Anthropic Claude';
    }
  }

  String get value {
    switch (this) {
      case AIProvider.openai:
        return 'openai';
      case AIProvider.gemini:
        return 'gemini';
      case AIProvider.claude:
        return 'claude';
    }
  }

  List<String> get availableModels {
    switch (this) {
      case AIProvider.openai:
        return [
          'gpt-4o',
          'gpt-4o-mini',
          'gpt-4-turbo',
          'gpt-3.5-turbo',
        ];
      case AIProvider.gemini:
        return [
          'gemini-1.5-pro',
          'gemini-1.5-flash',
          'gemini-pro',
          'gemini-pro-vision',
        ];
      case AIProvider.claude:
        return [
          'claude-3-5-sonnet-20241022',
          'claude-3-opus-20240229',
          'claude-3-haiku-20240307',
        ];
    }
  }

  String get defaultModel => availableModels.first;

  bool get supportsVision {
    switch (this) {
      case AIProvider.openai:
        return true;
      case AIProvider.gemini:
        return true;
      case AIProvider.claude:
        return true;
    }
  }

  static AIProvider fromValue(String value) {
    return AIProvider.values.firstWhere(
      (p) => p.value == value,
      orElse: () => AIProvider.openai,
    );
  }
}
