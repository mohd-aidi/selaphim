class AppConstants {
  AppConstants._();

  static const String appName = 'Selaphim';
  static const String appTagline = 'Your AI Vision & Voice Companion';

  static const String defaultSystemPrompt =
      'You are Selaphim, a helpful AI assistant for daily life. '
      'Be concise, friendly and supportive. '
      'When helping with vision tasks, describe what you see clearly and helpfully.';

  static const int maxConversationHistory = 20;
  static const int defaultLiveVisionInterval = 10;
  static const int minLiveVisionInterval = 5;
  static const int maxLiveVisionInterval = 60;

  // Secure storage key prefixes
  static const String apiKeyPrefix = 'api_key_';

  // Route names
  static const String routeHome = '/';
  static const String routeVision = '/vision';
  static const String routeVoice = '/voice';
  static const String routeHistory = '/history';
  static const String routeSettings = '/settings';
}
