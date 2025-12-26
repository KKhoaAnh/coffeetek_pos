import 'modifier.dart';

class ModifierGroup {
  final String id;
  final String name;
  final bool isMultiSelect;
  final bool isRequired;
  final List<Modifier> modifiers;

  ModifierGroup({
    required this.id,
    required this.name,
    required this.isMultiSelect,
    required this.isRequired,
    required this.modifiers,
  });
}