import 'package:flutter/material.dart';
import 'app_data.dart';
import 'main_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  void _login() {
    String username = userController.text.trim();
    String password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إدخال اسم المستخدم وكلمة المرور")));
      return;
    }

    Map? loggedInUser;
    for (var u in AppData.users) {
      if (u['username'] == username && u['password'] == password) {
        loggedInUser = u;
        break;
      }
    }

    if (loggedInUser != null || AppData.users.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainDashboardScreen(currentUser: loggedInUser?.cast()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("اسم المستخدم أو كلمة المرور غير صحيحة")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Directionality(
        textDirection: TextDirection.rtl,
        // 📱 تفعيل التمرير العمودي لضمان عدم حدوث تداخل أو Overflow على الشاشات الصغيرة للموبايل
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 50, color: Color(0xFF0F172A)),
                    const SizedBox(height: 15),
                    Text(AppData.companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 5),
                    const Text("تسجيل الدخول للنظام", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 25),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(labelText: "اسم المستخدم", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                        child: const Text("دخول", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}