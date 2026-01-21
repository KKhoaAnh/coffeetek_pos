import 'package:flutter/material.dart';

enum TableShape { square, circle, rectangle }

class TableModel {
  final int id;
  final String name;
  final String status;
  final int? currentOrderId;
  final bool isActive;
  double x;
  double y;
  double width;
  double height;
  TableShape shape;
  Color color; 

  TableModel({
    required this.id, 
    required this.name, 
    required this.status, 
    this.currentOrderId,
    this.isActive = true,
    this.x = 0.0, 
    this.y = 0.0, 
    this.width = 0.15, 
    this.height = 0.15, 
    this.shape = TableShape.square,
    this.color = Colors.white,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    TableShape parseShape(String? s) {
      if (s == 'CIRCLE') return TableShape.circle;
      if (s == 'RECTANGLE') return TableShape.rectangle;
      return TableShape.square;
    }

    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return Colors.white;
      try {
        hex = hex.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex'; 
        return Color(int.parse(hex, radix: 16));
      } catch (e) {
        return Colors.white;
      }
    }

    return TableModel(
      id: json['table_id'],
      name: json['table_name'],
      status: json['status'],
      currentOrderId: json['current_order_id'],
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      x: (json['pos_x'] as num?)?.toDouble() ?? 0.0,
      y: (json['pos_y'] as num?)?.toDouble() ?? 0.0,
      
      width: (json['width'] as num?)?.toDouble() ?? 0.15,
      height: (json['height'] as num?)?.toDouble() ?? 0.15,
      
      shape: parseShape(json['shape']),
      color: parseColor(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    String colorToHex(Color c) {
      return '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
    }

    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'shape': shape.toString().split('.').last.toUpperCase(),
      'color': colorToHex(color),
    };
  }
  
  bool get isAvailable => status == 'AVAILABLE';
  bool get isOccupied => status == 'OCCUPIED';
  bool get isCleaning => status == 'CLEANING';
}