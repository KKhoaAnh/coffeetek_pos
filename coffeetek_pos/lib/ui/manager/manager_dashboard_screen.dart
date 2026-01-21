import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/auth/view_model/auth_view_model.dart';
import '../home/widgets/table_screen.dart';
import 'account_management_screen.dart';
import 'menu_management_screen.dart';
import 'table_management_screen.dart';
import '../auth/widgets/login_screen.dart';
import 'report_screen.dart';
// import 'table_management_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final user = authVM.currentUser;

    // Màu chủ đạo
    final Color primaryBrown = Colors.brown[700]!;
    final Color bgCream = const Color(0xFFF5F0E6); // Màu kem nhẹ nhàng

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Lấy kích thước toàn màn hình khả dụng
            final double availableHeight = constraints.maxHeight;
            final double availableWidth = constraints.maxWidth;

            // Dành khoảng 15-20% chiều cao cho Header
            final double headerHeight = 100.0;
            
            // Chiều cao còn lại cho Grid
            final double gridHeight = availableHeight - headerHeight - 40; // trừ padding

            // Tính toán tỷ lệ ô (Rộng / Cao) để vừa khít 3 hàng mà không scroll
            // Grid 3 cột, 3 hàng => 9 ô
            // Chiều rộng 1 ô = (Width - spacing) / 3
            // Chiều cao 1 ô = (Height - spacing) / 3
            final double crossAxisSpacing = 15;
            final double mainAxisSpacing = 15;
            final double itemWidth = (availableWidth - 40 - (crossAxisSpacing * 2)) / 3;
            final double itemHeight = (gridHeight - (mainAxisSpacing * 2)) / 3;
            
            final double dynamicAspectRatio = itemWidth / itemHeight;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER SECTION (Cố định chiều cao) ---
                  SizedBox(
                    height: headerHeight,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryBrown, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.brown[100],
                            child: Text(
                              user?.fullName.substring(0, 1).toUpperCase() ?? "A",
                              style: TextStyle(
                                fontSize: 28, 
                                color: primaryBrown, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Xin chào,",
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              Text(
                                user?.fullName ?? 'Quản lý',
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.brown[900]
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryBrown.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Quản trị viên",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBrown),
                                ),
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_outlined, size: 28, color: primaryBrown),
                          onPressed: () {},
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        )
                      ],
                    ),
                  ),

                  // --- GRID SECTION (Tự co giãn) ---
                  Expanded(
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(), // [QUAN TRỌNG] Không cuộn
                      crossAxisCount: 3,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisSpacing: mainAxisSpacing,
                      childAspectRatio: dynamicAspectRatio, // [QUAN TRỌNG] Tỷ lệ động
                      children: [
                        // HÀNG 1: HOẠT ĐỘNG
                        _buildMenuCard(
                          context, "MỞ CA", Icons.storefront, 
                          Colors.teal, 
                          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển")))
                        ),
                        _buildMenuCard(
                          context, "POS", Icons.point_of_sale, 
                          Colors.orange[800]!, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TableScreen()))
                        ),
                        _buildMenuCard(
                          context, "BÁO CÁO", Icons.bar_chart_rounded, 
                          Colors.indigo, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))
                        ),

                        // HÀNG 2: QUẢN LÝ (TRỌNG TÂM)
                        _buildMenuCard(
                          context, "TÀI KHOẢN", Icons.manage_accounts, 
                          Colors.blue[700]!, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManagementScreen()))
                        ),
                        _buildMenuCard(
                          context, "MENU", Icons.restaurant_menu, 
                          Colors.brown[600]!, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuManagementScreen()))
                        ),
                        _buildMenuCard(
                          context, "BÀN", Icons.table_bar, 
                          Colors.deepPurple, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TableManagementScreen()))
                        ),

                        // HÀNG 3: HỆ THỐNG
                        _buildMenuCard(
                          context, "CHI PHÍ", Icons.attach_money, 
                          Colors.green[700]!, 
                          () {}
                        ),
                        _buildMenuCard(
                          context, "KHO", Icons.inventory_2, 
                          Colors.amber[800]!, 
                          () {}
                        ),
                        _buildMenuCard(
                          context, 
                          "THOÁT", 
                          Icons.logout, 
                          Colors.red[700]!, 
                          () {
                            // Hiện hộp thoại xác nhận trước
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Đăng xuất"),
                                content: const Text("Bạn có chắc chắn muốn thoát khỏi hệ thống?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx), // Đóng dialog
                                    child: const Text("Hủy"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx); // Đóng dialog trước
                                      
                                      // Thực hiện quy trình đăng xuất chuẩn
                                      await Provider.of<AuthViewModel>(context, listen: false).logout();
                                      
                                      if (context.mounted) {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                          (route) => false
                                        );
                                      }
                                    },
                                    child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer Version
                  // Center(
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(top: 10),
                  //     child: Text(
                  //       "CoffeeTek Manager v1.0 - Developed by Khoa Manager", 
                  //       style: TextStyle(color: Colors.brown.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic)
                  //     ),
                  //   ),
                  // )
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color accentColor, 
    VoidCallback onTap,
    {bool isDestructive = false}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
        border: Border.all(color: Colors.white, width: 2), // Border trắng tạo độ nổi
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withOpacity(0.1),
          highlightColor: accentColor.withOpacity(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                // Giảm padding từ 12 xuống 5 hoặc 0 để tiết kiệm diện tích cho Icon
                padding: const EdgeInsets.all(10), 
                
                decoration: BoxDecoration(
                  color: isDestructive ? Colors.red[50] : accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  size: 80, // Kích thước to mong muốn
                  color: isDestructive ? Colors.red : accentColor
                ),
              ),
              const SizedBox(height: 10),
              // Text Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: isDestructive ? Colors.red[800] : Colors.grey[800],
                    letterSpacing: 0.5
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}