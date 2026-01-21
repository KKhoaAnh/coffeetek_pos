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
    this.modifiers = const []
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    var list = json['modifiers'] as List? ?? [];
    
    List<Modifier> modifierList = list.map((i) {
       return Modifier.fromJson(i);
    }).toList();

    return ModifierGroup(
      id: json['group_id'].toString(),
      name: json['group_name'],
      isMultiSelect: json['is_multi_select'] == 1 || json['is_multi_select'] == true,
      isRequired: json['is_required'] == 1 || json['is_required'] == true,
      modifiers: modifierList,
    );
  }
}