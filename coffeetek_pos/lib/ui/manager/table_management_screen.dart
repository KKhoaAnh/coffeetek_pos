import 'package:flutter/material.dart';

class TableManagementScreen extends StatelessWidget {
  const TableManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý Tài khoản")),
      body: const Center(child: Text("Danh sách nhân viên sẽ hiện ở đây")),
    );
  }
}