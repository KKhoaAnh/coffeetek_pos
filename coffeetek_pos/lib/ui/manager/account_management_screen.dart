import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/user.dart';
import '../../utils/user_service.dart'; // Đảm bảo đường dẫn đúng

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final UserService _userService = UserService();
  List<User> _users = [];
  bool _isLoading = true;

  final Color _primaryColor = Colors.brown;
  final Color _accentColor = const Color(0xFFD7CCC8);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _userService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("QUẢN LÝ NHÂN SỰ", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.brown[500],
        elevation: 0,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
            tooltip: "Tải lại",
          )
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: _primaryColor)) 
          : _users.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("Chưa có nhân viên nào", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _users.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    return _buildModernEmployeeCard(_users[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: _primaryColor,
        elevation: 4,
        icon: const Icon(Icons.person_add, color: Colors.white, size: 28),
        label: const Text("THÊM NHÂN VIÊN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildModernEmployeeCard(User user) {
    bool isManager = user.role.toLowerCase() == 'manager';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAddEditDialog(user: user),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: isManager ? _primaryColor : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isManager ? Colors.brown[300]! : Colors.transparent,
                      width: 2
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold,
                      color: isManager ? Colors.white : Colors.grey[700]
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[900]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isManager ? Colors.orange[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isManager ? Colors.orange : Colors.blue.withOpacity(0.5), 
                            width: 0.5
                          )
                        ),
                        child: Text(
                          isManager ? "QUẢN LÝ (MANAGER)" : "THU NGÂN (CASHIER)",
                          style: TextStyle(
                            fontSize: 11, 
                            color: isManager ? Colors.orange[800] : Colors.blue[800], 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            "Vào làm: ${DateFormat('dd/MM/yyyy').format(user.createAt)}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: user.isActive,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green[100],
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey[300],
                        onChanged: (val) async {
                          bool success = await _userService.toggleStatus(user.id, val);
                          
                          if (success) {
                            _loadUsers();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val 
                                  ? "Đã kích hoạt lại ${user.fullName} (Đã cập nhật ngày vào làm mới)" 
                                  : "Đã khóa tài khoản ${user.fullName}"
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: val ? Colors.green[700] : Colors.grey[800],
                                duration: const Duration(seconds: 2),
                              )
                            );
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Lỗi kết nối!"), backgroundColor: Colors.red)
                             );
                          }
                        },
                      ),
                    ),
                    Text(
                      user.isActive ? "Hoạt động" : "Đã khóa",
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w600, 
                        color: user.isActive ? Colors.green : Colors.grey
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmToggleStatus(User user, bool newValue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newValue ? "Kích hoạt lại?" : "Khóa tài khoản?"),
        content: Text(newValue 
          ? "Bạn có chắc muốn kích hoạt lại nhân viên ${user.fullName}?\n\nLƯU Ý: Ngày vào làm sẽ được đặt lại thành HÔM NAY." 
          : "Bạn có chắc muốn khóa tài khoản này? Nhân viên sẽ không thể đăng nhập được nữa."
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: newValue ? Colors.green : Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              
              bool success = await _userService.toggleStatus(user.id, newValue);
              
              if (success) {
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newValue 
                      ? "Đã kích hoạt lại và reset ngày làm việc." 
                      : "Đã khóa tài khoản."
                    ),
                    backgroundColor: newValue ? Colors.green[700] : Colors.grey[800],
                  )
                );
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối!")));
              }
            },
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }
  
  void _showAddEditDialog({User? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?.fullName ?? "");
    final pinController = TextEditingController(text: user?.pinCode ?? "");
    
    final List<Map<String, String>> validRoles = [
      {'value': 'cashier', 'label': 'Nhân viên Thu ngân'},
      {'value': 'manager', 'label': 'Quản lý Cửa hàng'},
    ];

    String initialRole = user?.role ?? 'cashier';
    if (!validRoles.any((r) => r['value'] == initialRole)) {
      initialRole = 'cashier'; 
    }
    String selectedRole = initialRole;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(25),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? "CẬP NHẬT THÔNG TIN" : "THÊM NHÂN VIÊN MỚI",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                isEditing ? "Chỉnh sửa thông tin nhân sự" : "Nhập thông tin nhân viên mới vào hệ thống",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              _buildModernTextField(
                controller: nameController,
                label: "Họ và tên",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 15),

              _buildModernTextField(
                controller: pinController,
                label: "Mã PIN đăng nhập (6 số)",
                icon: Icons.lock_outline,
                isNumber: true,
                isPassword: true,
                maxLength: 6,
              ),
              const SizedBox(height: 5),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down_circle, color: _primaryColor),
                    items: validRoles.map((item) {
                      bool isManagerItem = item['value'] == 'manager';
                      return DropdownMenuItem(
                        value: item['value'],
                        child: Row(
                          children: [
                            Icon(
                              isManagerItem ? Icons.security : Icons.point_of_sale,
                              color: isManagerItem ? Colors.orange : Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item['label']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800]
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) selectedRole = val;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text("HỦY BỎ", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty || pinController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin!")));
                          return;
                        }
                        
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                        final newUser = User(
                          id: user?.id ?? '', 
                          username: user?.username ?? nameController.text.toLowerCase().replaceAll(' ', ''),
                          fullName: nameController.text, 
                          role: selectedRole, 
                          pinCode: pinController.text, 
                          createAt: user?.createAt ?? DateTime.now(),
                          isActive: user?.isActive ?? true
                        );

                        bool success;
                        if (isEditing) {
                          success = await _userService.updateUser(newUser);
                        } else {
                          success = await _userService.createUser(newUser);
                        }
                        
                        Navigator.pop(context);
                        Navigator.pop(ctx);

                        if (success) {
                          _loadUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Lưu thông tin thành công!"),
                              backgroundColor: Colors.green[700],
                              behavior: SnackBarBehavior.floating,
                            )
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra!"), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: const Text("LƯU LẠI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    bool isPassword = false,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      obscureText: isPassword,
      maxLength: maxLength,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        filled: true,
        fillColor: Colors.grey[100],
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }
}