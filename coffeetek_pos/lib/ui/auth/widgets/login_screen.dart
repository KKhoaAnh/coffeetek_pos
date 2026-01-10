import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/auth_view_model.dart';
import '../../../ui/home/widgets/table_screen.dart';
import '../../../ui/manager/manager_dashboard_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = "";
  final int _pinLength = 6;

  void _onNumberPress(String number) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
      });
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _handleLogin();
        });
      }
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _handleLogin() async {
    if (_pin.isEmpty) return;
    
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authVM.loginWithPin(_pin);

    if (success) {
      final user = authVM.currentUser;
      if (user != null && (user.role == 'admin' || user.role == 'manager')) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const ManagerDashboardScreen())
        );
      } else {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const TableScreen())
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _pin = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (isLandscape)
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('./background.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.brown.withOpacity(0.15), // overlay
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.coffee,
                        size: size.height * 0.15,
                        color: Colors.brown,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "COFFEETEK POS",
                        style: TextStyle(
                          fontSize: size.height * 0.04,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 228, 171, 151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            flex: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth * 0.1;
                
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding < 20 ? 20 : horizontalPadding, 
                    vertical: 20
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1),
                      
                      Text(
                        "Nhập mã PIN", 
                        style: TextStyle(fontSize: 24, color: Colors.grey[700], fontWeight: FontWeight.w500)
                      ),
                      
                      SizedBox(height: constraints.maxHeight * 0.03),
                      
                      SizedBox(
                        height: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pinLength, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: index < _pin.length ? 16 : 12,
                              height: index < _pin.length ? 16 : 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < _pin.length ? Colors.brown : Colors.grey[300],
                                border: index < _pin.length ? null : Border.all(color: Colors.grey[400]!),
                              ),
                            );
                          }),
                        ),
                      ),

                      SizedBox(height: constraints.maxHeight * 0.05),

                      Expanded(
                        flex: 10, 
                        child: LayoutBuilder(
                          builder: (ctx, gridConstraints) {
                            double itemWidth = gridConstraints.maxWidth / 3;
                            double itemHeight = gridConstraints.maxHeight / 4;
                            double childAspectRatio = (itemWidth / itemHeight);

                            double crossAxisSpacing = 20;
                            double mainAxisSpacing = 15;
                            double adjustedRatio = childAspectRatio * 1.1; 

                            return GridView.count(
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              childAspectRatio: adjustedRatio,
                              mainAxisSpacing: mainAxisSpacing,
                              crossAxisSpacing: crossAxisSpacing,
                              children: [
                                ...List.generate(9, (index) => _buildNumberBtn('${index + 1}')), 
                                const SizedBox(), 
                                _buildNumberBtn('0'), 
                                _buildActionBtn(Icons.backspace_outlined, _onDeletePress, color: Colors.red.shade400), 
                              ],
                            );
                          }
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberBtn(String number) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = constraints.maxHeight * 0.4; 
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onNumberPress(number),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
                boxShadow: [
                   BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              alignment: Alignment.center,
              child: Text(
                number, 
                style: TextStyle(
                  fontSize: fontSize > 36 ? 36 : fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                )
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap, {Color bgColor = Colors.white, Color color = Colors.black54}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double iconSize = constraints.maxHeight * 0.4;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: bgColor == Colors.white ? Border.all(color: Colors.grey.shade300) : null,
                 boxShadow: [
                   BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: iconSize > 32 ? 32 : iconSize, color: color),
            ),
          ),
        );
      }
    );
  }
}