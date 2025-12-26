import '../../domain/models/modifier/modifier.dart';
import '../../domain/models/modifier/modifier_group.dart';

class ModifierGroupApiModel {
  final String groupId;
  final String groupName;
  final bool isMultiSelect;
  final bool isRequired;
  final List<ModifierApiModel> modifiers;

  ModifierGroupApiModel({
    required this.groupId,
    required this.groupName,
    required this.isMultiSelect,
    required this.isRequired,
    required this.modifiers,
  });

  factory ModifierGroupApiModel.fromJson(Map<String, dynamic> json) {
    return ModifierGroupApiModel(
      groupId: json['group_id'].toString(),
      groupName: json['group_name'] ?? '',
      isMultiSelect: json['is_multi_select'] == true,
      isRequired: json['is_required'] == true,
      modifiers: (json['modifiers'] as List)
          .map((m) => ModifierApiModel.fromJson(m))
          .toList(),
    );
  }

  ModifierGroup toDomain() {
    return ModifierGroup(
      id: groupId,
      name: groupName,
      isMultiSelect: isMultiSelect,
      isRequired: isRequired,
      modifiers: modifiers.map((m) => m.toDomain(groupId)).toList(),
    );
  }
}

class ModifierApiModel {
  final String modifierId;
  final String modifierName;
  final double extraPrice;

  ModifierApiModel({
    required this.modifierId,
    required this.modifierName,
    required this.extraPrice,
  });

  factory ModifierApiModel.fromJson(Map<String, dynamic> json) {
    return ModifierApiModel(
      modifierId: json['modifier_id'].toString(),
      modifierName: json['modifier_name'] ?? '',
      extraPrice: double.tryParse(json['extra_price'].toString()) ?? 0.0,
    );
  }

  Modifier toDomain(String groupId) {
    return Modifier(
      id: modifierId,
      name: modifierName,
      extraPrice: extraPrice,
      groupId: groupId,
    );
  }
}