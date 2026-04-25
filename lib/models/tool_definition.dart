/// Represents a capability (tool / skill) the AI can invoke.
class ToolDefinition {
  final String id;
  final String name;
  final String description;
  final int requiredSkillLevel;
  final bool isEnabled;

  const ToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.requiredSkillLevel = 1,
    this.isEnabled = true,
  });

  ToolDefinition copyWith({bool? isEnabled}) {
    return ToolDefinition(
      id: id,
      name: name,
      description: description,
      requiredSkillLevel: requiredSkillLevel,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
