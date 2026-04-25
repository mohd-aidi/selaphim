import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/ai_provider.dart';
import '../models/conversation.dart';

/// Thrown when an AI service call fails.
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;

  const AIServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'AIServiceException($statusCode): $message';
}

/// Abstract interface that all AI provider adapters must implement.
abstract class AIService {
  /// Send a text-only chat message and return the assistant reply.
  Future<String> chat({
    required List<Message> history,
    required String userMessage,
    String? systemPrompt,
  });

  /// Send an image (as raw bytes) plus an optional text prompt and return
  /// a text description / answer.
  Future<String> analyseImage({
    required Uint8List imageBytes,
    String prompt = 'Describe what you see in this image.',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// OpenAI adapter
// ─────────────────────────────────────────────────────────────────────────────

class OpenAIService implements AIService {
  OpenAIService({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Map<String, String> get _headers => {
        HttpHeaders.authorizationHeader: 'Bearer $apiKey',
        HttpHeaders.contentTypeHeader: 'application/json',
      };

  @override
  Future<String> chat({
    required List<Message> history,
    required String userMessage,
    String? systemPrompt,
  }) async {
    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final m in history) {
      if (m.role != MessageRole.system) {
        messages.add({'role': m.role.value, 'content': m.content});
      }
    }
    messages.add({'role': 'user', 'content': userMessage});

    final body = jsonEncode({
      'model': model,
      'messages': messages,
    });

    final response = await http
        .post(Uri.parse(_baseUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 30));

    return _extractText(response);
  }

  @override
  Future<String> analyseImage({
    required Uint8List imageBytes,
    String prompt = 'Describe what you see in this image.',
  }) async {
    final base64Image = base64Encode(imageBytes);

    final messages = [
      {
        'role': 'user',
        'content': [
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
          {'type': 'text', 'text': prompt},
        ],
      }
    ];

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'max_tokens': 1024,
    });

    final response = await http
        .post(Uri.parse(_baseUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 45));

    return _extractText(response);
  }

  String _extractText(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      return (choices.first['message']['content'] as String).trim();
    } else if (response.statusCode == 429) {
      throw const AIServiceException(
          'Rate limit reached. Please wait and try again.',
          statusCode: 429);
    } else {
      throw AIServiceException(
          'OpenAI error: ${response.statusCode} ${response.body}',
          statusCode: response.statusCode);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Gemini adapter
// ─────────────────────────────────────────────────────────────────────────────

class GeminiService implements AIService {
  GeminiService({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  String get _baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

  @override
  Future<String> chat({
    required List<Message> history,
    required String userMessage,
    String? systemPrompt,
  }) async {
    final contents = <Map<String, dynamic>>[];

    for (final m in history) {
      if (m.role == MessageRole.system) continue;
      contents.add({
        'role': m.role == MessageRole.assistant ? 'model' : 'user',
        'parts': [
          {'text': m.content}
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final body = jsonEncode({'contents': contents});

    final response = await http
        .post(Uri.parse(_baseUrl),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: body)
        .timeout(const Duration(seconds: 30));

    return _extractText(response);
  }

  @override
  Future<String> analyseImage({
    required Uint8List imageBytes,
    String prompt = 'Describe what you see in this image.',
  }) async {
    final base64Image = base64Encode(imageBytes);

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            },
          ]
        }
      ]
    });

    final response = await http
        .post(Uri.parse(_baseUrl),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: body)
        .timeout(const Duration(seconds: 45));

    return _extractText(response);
  }

  String _extractText(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>;
      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      return (parts.first['text'] as String).trim();
    } else if (response.statusCode == 429) {
      throw const AIServiceException('Rate limit reached.', statusCode: 429);
    } else {
      throw AIServiceException(
          'Gemini error: ${response.statusCode} ${response.body}',
          statusCode: response.statusCode);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Anthropic Claude adapter
// ─────────────────────────────────────────────────────────────────────────────

class ClaudeService implements AIService {
  ClaudeService({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';

  Map<String, String> get _headers => {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        HttpHeaders.contentTypeHeader: 'application/json',
      };

  @override
  Future<String> chat({
    required List<Message> history,
    required String userMessage,
    String? systemPrompt,
  }) async {
    final messages = <Map<String, dynamic>>[];
    for (final m in history) {
      if (m.role == MessageRole.system) continue;
      messages.add({
        'role': m.role == MessageRole.assistant ? 'assistant' : 'user',
        'content': m.content,
      });
    }
    messages.add({'role': 'user', 'content': userMessage});

    final bodyMap = <String, dynamic>{
      'model': model,
      'max_tokens': 1024,
      'messages': messages,
    };
    if (systemPrompt != null) bodyMap['system'] = systemPrompt;

    final response = await http
        .post(Uri.parse(_baseUrl),
            headers: _headers, body: jsonEncode(bodyMap))
        .timeout(const Duration(seconds: 30));

    return _extractText(response);
  }

  @override
  Future<String> analyseImage({
    required Uint8List imageBytes,
    String prompt = 'Describe what you see in this image.',
  }) async {
    final base64Image = base64Encode(imageBytes);

    final body = jsonEncode({
      'model': model,
      'max_tokens': 1024,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              },
            },
            {'type': 'text', 'text': prompt},
          ],
        }
      ],
    });

    final response = await http
        .post(Uri.parse(_baseUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 45));

    return _extractText(response);
  }

  String _extractText(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>;
      return (content.first['text'] as String).trim();
    } else if (response.statusCode == 429) {
      throw const AIServiceException('Rate limit reached.', statusCode: 429);
    } else {
      throw AIServiceException(
          'Claude error: ${response.statusCode} ${response.body}',
          statusCode: response.statusCode);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory
// ─────────────────────────────────────────────────────────────────────────────

AIService buildAIService({
  required AIProvider provider,
  required String apiKey,
  required String model,
}) {
  switch (provider) {
    case AIProvider.openai:
      return OpenAIService(apiKey: apiKey, model: model);
    case AIProvider.gemini:
      return GeminiService(apiKey: apiKey, model: model);
    case AIProvider.claude:
      return ClaudeService(apiKey: apiKey, model: model);
  }
}
