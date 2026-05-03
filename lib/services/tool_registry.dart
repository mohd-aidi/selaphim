import 'package:http/http.dart' as http;

import '../models/tool_definition.dart';

/// Central registry of all MCP tools available to the AI.
class ToolRegistry {
  ToolRegistry._();
  static final ToolRegistry instance = ToolRegistry._();

  /// All registered tools keyed by [ToolDefinition.id].
  final Map<String, ToolDefinition> _tools = {};

  /// Initialize the registry with the built-in tools.
  void init() {
    _register(const ToolDefinition(
      id: 'web_browse',
      name: 'Web Browse',
      description: 'Fetch and read a web page. Required skill level: 7.',
      requiredSkillLevel: 7,
    ));
    _register(const ToolDefinition(
      id: 'set_alarm',
      name: 'Set Alarm',
      description: 'Set an alarm at a specific date and time.',
      requiredSkillLevel: 7,
    ));
    _register(const ToolDefinition(
      id: 'add_calendar_event',
      name: 'Add Calendar Event',
      description: 'Create a calendar reminder for the owner.',
      requiredSkillLevel: 6,
    ));
    _register(const ToolDefinition(
      id: 'send_notification',
      name: 'Send Notification',
      description: 'Send an immediate push notification to the owner.',
      requiredSkillLevel: 3,
    ));
  }

  void _register(ToolDefinition tool) {
    _tools[tool.id] = tool;
  }

  /// All tools available at or below [skillLevel].
  List<ToolDefinition> toolsForLevel(int skillLevel) {
    return _tools.values
        .where((t) => t.isEnabled && t.requiredSkillLevel <= skillLevel)
        .toList();
  }

  /// All registered tools regardless of skill level.
  List<ToolDefinition> get allTools => _tools.values.toList();

  /// Toggle a tool on/off.
  void setEnabled(String toolId, {required bool enabled}) {
    final tool = _tools[toolId];
    if (tool != null) {
      _tools[toolId] = tool.copyWith(isEnabled: enabled);
    }
  }

  bool isEnabled(String toolId) => _tools[toolId]?.isEnabled ?? false;
}

/// Simple web-browse tool: fetches a URL and returns the first 2000 chars
/// of the plain text body.
class WebBrowserTool {
  static Future<String> fetch(String url) async {
    try {
      final uri = Uri.parse(url);
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return 'HTTP ${response.statusCode} for $url';
      }
      // Very light HTML stripping: remove tags
      final text = response.body
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return text.length > 2000 ? '${text.substring(0, 2000)}…' : text;
    } catch (e) {
      return 'Failed to fetch $url: $e';
    }
  }
}
