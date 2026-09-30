import 'package:flutter/material.dart';
import 'app_data.dart';
import 'login_screen.dart';
import 'main_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تحميل البيانات المحفوظة للتأكد من وجود مستخدمين أم لا
  await AppData.loadData();
  
  // فحص ما إذا كان هناك مستخدمون بكلمات مرور مسجلة
  bool hasUsers = AppData.users.isNotEmpty;

  runApp(MyApp(hasUsers: hasUsers));
}

class MyApp extends StatelessWidget {
  final bool hasUsers;
  const MyApp({super.key, required this.hasUsers});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق الشركة',
      // إذا كانت قائمة المستخدمين فارغة، افتح اللوحة الرئيسية مباشرة، وإذا وجد مستخدمون اذهب لشاشة تسجيل الدخول
      home: hasUsers ? const LoginScreen() : const MainDashboardScreen(),
    );
  }
}
