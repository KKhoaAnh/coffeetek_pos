import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/modifier/modifier.dart';
import '../../../domain/models/modifier/modifier_group.dart';
import '../../../data/repositories/product_repository_impl.dart';

class ModifierSelectionDialog extends StatefulWidget {
  final Product product;
  final List<Modifier> initialSelections;
  final Function(List<Modifier>) onConfirm;
  final bool isEditing;

  const ModifierSelectionDialog({
    Key? key,
    required this.product,
    this.initialSelections = const [],
    required this.onConfirm,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<ModifierSelectionDialog> createState() => _ModifierSelectionDialogState();
}

class _ModifierSelectionDialogState extends State<ModifierSelectionDialog> {
  final List<Modifier> _currentSelections = [];
  List<ModifierGroup> _modifierGroups = [];
  bool _isLoading = true;
  // List<ModifierGroup> _mockGroups = [];

  @override
  void initState() {
    super.initState();
    _currentSelections.addAll(widget.initialSelections);
        _fetchModifiers();
  }

  Future<void> _fetchModifiers() async {
    final repo = ProductRepositoryImpl();
    try {
      final groups = await repo.getProductModifiers(widget.product.id);
      
      setState(() {
        _modifierGroups = groups;
        _isLoading = false;
      });

      if (!widget.isEditing && widget.initialSelections.isEmpty) {
        _applyDefaultSelections(groups);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi load modifier: $e");
    }
  }

  void _applyDefaultSelections(List<ModifierGroup> groups) {
    for (var group in groups) {
      if (group.isRequired && group.modifiers.isNotEmpty) {
        bool hasSelected = _currentSelections.any((m) => m.groupId == group.id);
        if (!hasSelected) {
           _currentSelections.add(group.modifiers[0]);
        }
      }
    }
    setState(() {});
  }

  void _toggleModifier(ModifierGroup group, Modifier modifier) {
    setState(() {
      if (!group.isMultiSelect) {
        final modifierIdsInGroup = group.modifiers.map((m) => m.id).toSet();

        _currentSelections.removeWhere((item) => modifierIdsInGroup.contains(item.id));
        
        _currentSelections.add(modifier);

      } else {
        final isSelected = _currentSelections.any((item) => item.id == modifier.id);
        
        if (isSelected) {
          _currentSelections.removeWhere((item) => item.id == modifier.id);
        } else {
          _currentSelections.add(modifier);
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    double totalExtra = _currentSelections.fold(0, (sum, item) => sum + item.extraPrice);
    double finalPrice = widget.product.price + totalExtra;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.brown,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product.name, // 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator()) // Hiện Loading khi đang tải
                  : _modifierGroups.isEmpty
                      ? const Center(child: Text("Món này không có tùy chọn thêm."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _modifierGroups.length,
                          itemBuilder: (ctx, i) => _buildGroupItem(_modifierGroups[i]),
                        ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  for (var group in _modifierGroups) {
                    if (group.isRequired) {
                      bool hasSelected = _currentSelections.any((m) => m.groupId == group.id);
                      if (!hasSelected) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng chọn ${group.name}')));
                         return;
                      }
                    }
                  }
                  
                  widget.onConfirm(_currentSelections);
                  Navigator.of(context).pop();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                          widget.isEditing ? "CẬP NHẬT - " : "THÊM VÀO ĐƠN - ", 
                          style: const TextStyle(fontSize: 16, color: Colors.white)
                        ),
                    Text(
                      currencyFormat.format(finalPrice),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupItem(ModifierGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            group.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: group.modifiers.map((modifier) {
            final isSelected = _currentSelections.any((item) => item.id == modifier.id);
            return FilterChip(
              label: Text('${modifier.name} ${modifier.extraPrice > 0 ? "+${NumberFormat.currency(locale: 'vi', symbol: '').format(modifier.extraPrice)}" : ""}'),
              selected: isSelected,
              selectedColor: Colors.brown[100],
              checkmarkColor: Colors.brown,
              labelStyle: TextStyle(color: isSelected ? Colors.brown[900] : Colors.black87),
              onSelected: (_) => _toggleModifier(group, modifier),
            );
          }).toList(),
        ),
        const Divider(height: 30),
      ],
    );
  }
}