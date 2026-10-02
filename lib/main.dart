import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'main_dashboard.dart'; // أو شاشة البداية لديك

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة فايربيس بالبيانات المباشرة لمشروعك
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "ضع_مفتاح_الـ_API_هنا",
      appId: "ضع_معرف_التطبيق_هنا",
      messagingSenderId: "ضع_رقم_المُرسل_هنا",
      projectId: "businessapp-1786e", // معرف مشروعك الظاهر في المتصفح
      storageBucket: "businessapp-1786e.appspot.com",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Business App',
      home: const MainDashboardScreen(), // الشاشة الرئيسية لديك
    );
  }
}
