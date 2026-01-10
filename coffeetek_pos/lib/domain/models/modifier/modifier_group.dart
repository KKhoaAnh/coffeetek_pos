// lib/domain/models/modifier_group.dart

import 'modifier.dart'; // Import đúng file ở Bước 1

class ModifierGroup {
  final String id;
  final String name;
  final bool isMultiSelect;
  final bool isRequired;
  
  // [SỬA LẠI]: Dùng List<Modifier> thay vì ModifierItem
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
    
    // Parse sang Modifier
    List<Modifier> modifierList = list.map((i) => Modifier.fromJson(i)).toList();

    return ModifierGroup(
      id: json['group_id'].toString(),
      name: json['group_name'],
      isMultiSelect: json['is_multi_select'] == 1 || json['is_multi_select'] == true,
      isRequired: json['is_required'] == 1 || json['is_required'] == true,
      modifiers: modifierList,
    );
  }
}