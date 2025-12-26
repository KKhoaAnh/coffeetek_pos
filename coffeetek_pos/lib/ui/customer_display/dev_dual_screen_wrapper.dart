import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import '../../ui/home/widgets/pos_screen.dart'; // Import đúng file POS của bạn
import '../../ui/customer_display/customer_screen.dart'; 

class DevDualScreenWrapper extends StatelessWidget {
  const DevDualScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // CHỈ chia đôi khi đang Debug trên máy tính
    if (kDebugMode) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 1, 
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.black, width: 2))
                ),
                child: const PosScreen(), 
              ),
            ),
            Expanded(
              flex: 1, 
              child: Container(
                color: Colors.grey[200],
                child: const CustomerScreen(),
              ),
            ),
          ],
        ),
      );
    } 
    
    // Khi Build ra file APK thật -> Chỉ hiển thị 1 màn hình POS
    // (CustomerScreen sẽ được PosScreen tự động đẩy ra màn hình phụ nhờ code ở Bước 4)
    else {
      return const PosScreen();
    }
  }
}