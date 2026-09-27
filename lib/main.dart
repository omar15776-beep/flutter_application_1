import 'package:flutter/material.dart';
import 'app_data.dart';
import 'main_dashboard.dart';
import 'login_screen.dart'; // سننشئها أو نتحقق منها

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.loadData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'المؤسسة التجارية',
      theme: ThemeData(primarySwatch: Colors.blue),
      // إذا كان هناك مستخدمون مسجلون، ابدأ بشاشة تسجيل الدخول، وإلا توجه للوحة التحكم مباشرة
      home: AppData.users.isNotEmpty ? const LoginScreen() : const MainDashboardScreen(),
    );
  }
}