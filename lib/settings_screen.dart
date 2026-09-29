import 'package:flutter/material.dart';
import 'app_data.dart';
import 'main_dashboard.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State {
  // إعدادات اسم المؤسسة والخطوط
  late final TextEditingController companyNameController = TextEditingController(text: AppData.companyName);
  double fontSize = AppData.companyFontSize;
  double fontHeight = AppData.companyFontHeight;
  String selectedFontFamily = AppData.companyFontFamily;
  Color fontColor = AppData.companyFontColor;
  
  // حالات الإظهار والإخفاء الجديدة
  bool showCompanyName = AppData.showCompanyName;
  bool showCompanyLogo = AppData.showCompanyLogo;

  // إعدادات اللوجو (الطول والعرض)
  double logoWidth = AppData.companyLogoWidth;
  double logoHeight = AppData.companyLogoHeight;
  String? logoPath = AppData.companyLogoPath;

  // إعدادات المستخدمين والصلاحيات
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = "موظف";
  
  bool allowOrdersEntry = true;
  bool allowClientsReport = true;
  bool allowDatabase = false;
  bool allowStatement = false;
  bool allowProfit = false;
  bool allowLists = false;
  bool allowSettings = false;
  bool allowGeneralSummary = false;
  bool allowSearchOptions = false;
  bool allowArchive = false;
  bool allowQuotationsEntry = false;
  bool allowQuotationsClients = false;
  bool allowQuotationsDatabase = false;
  bool allowQuotationsStatement = false;
  bool allowQuotationsProfit = false;

  Future _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      String base64Image = base64Encode(bytes);
      String imageUrl = 'data:image/png;base64,$base64Image';

      setState(() {
        logoPath = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم اختيار الشعار بنجاح: ${result.files.single.name}")),
      );
    }
  }

  void _addUser() async {
    if (usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      setState(() {
        AppData.users.add({
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
          "role": selectedRole,
          "permissions": {
            "ordersEntry": allowOrdersEntry,
            "clientsReport": allowClientsReport,
            "database": allowDatabase,
            "statement": allowStatement,
            "profit": allowProfit,
            "lists": allowLists,
            "settings": allowSettings,
            "generalSummary": allowGeneralSummary,
            "searchOptions": allowSearchOptions,
            "archive": allowArchive,
            "quotationsEntry": allowQuotationsEntry,
            "quotationsClients": allowQuotationsClients,
            "quotationsDatabase": allowQuotationsDatabase,
            "quotationsStatement": allowQuotationsStatement,
            "quotationsProfit": allowQuotationsProfit,
          }
        });
        usernameController.clear();
        passwordController.clear();
        selectedRole = "موظف";
      });
      await AppData.saveData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إضافة المستخدم وصلاحياته بنجاح")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إدخال اسم المستخدم وكلمة المرور")));
    }
  }

  void _saveAllSettings() async {
    AppData.companyName = companyNameController.text.trim();
    AppData.companyFontSize = fontSize;
    AppData.companyFontHeight = fontHeight;
    AppData.companyFontFamily = selectedFontFamily;
    AppData.companyFontColor = fontColor;
    
    // حفظ حالة الإظهار والإخفاء
    AppData.showCompanyName = showCompanyName;
    AppData.showCompanyLogo = showCompanyLogo;
    
    AppData.companyLogoWidth = logoWidth;
    AppData.companyLogoHeight = logoHeight;

    if (logoPath != null) {
      AppData.companyLogoPath = logoPath;
    }
    
    await AppData.saveData();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ تم حفظ وتفعيل كافة إعدادات النظام والشركة بنجاح"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmInitialization() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("⚠️ تحذير خطير - تهيئة كاملة للبرنامج"),
          content: const Text("سيتم مسح وحذف جميع البيانات نهائياً!\nهل أنت متأكد تماماً؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.savedOrders.clear();
                  AppData.savedQuotations.clear();
                  AppData.clients.clear();
                  AppData.materials.clear();
                  AppData.methods.clear();
                  AppData.searchOptions.clear();
                  AppData.users.clear();
                });
                await AppData.saveData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت تهيئة البرنامج ومسح كافة البيانات بنجاح")));
              },
              child: const Text("نعم، احذف الكل"),
            ),
          ],
        ),
      ),
    );
  }

  void _archiveData() async {
    try {
      await AppData.saveData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم أرشفة وحفظ كافة البيانات بنجاح في الذاكرة الدائمة")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء الأرشفة: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("إعدادات النظام والشركة", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // 1. قسم تخصيص اسم المؤسسة والخطوط بالكامل
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("تخصيص اسم المؤسسة والخطوط", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      // زر إظهار/إخفاء اسم المؤسسة
                      SwitchListTile(
                        title: const Text("إظهار اسم المؤسسة في التقارير والفواتير"),
                        value: showCompanyName,
                        onChanged: (val) => setState(() => showCompanyName = val),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      TextField(
                        controller: companyNameController,
                        decoration: const InputDecoration(labelText: "اسم المؤسسة / الشركة", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("حجم الخط: ${fontSize.toInt()} px"),
                                Slider(
                                  value: fontSize,
                                  min: 10,
                                  max: 35,
                                  divisions: 25,
                                  label: fontSize.toInt().toString(),
                                  onChanged: (val) => setState(() => fontSize = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ارتفاع الخط (التباعد): ${fontHeight.toStringAsFixed(1)}"),
                                Slider(
                                  value: fontHeight,
                                  min: 0.8,
                                  max: 2.5,
                                  divisions: 17,
                                  label: fontHeight.toStringAsFixed(1),
                                  onChanged: (val) => setState(() => fontHeight = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField(
                              initialValue: selectedFontFamily,
                              items: const [
                                DropdownMenuItem(value: "Cairo", child: Text("خط Cairo")),
                                DropdownMenuItem(value: "Roboto", child: Text("خط Roboto")),
                                DropdownMenuItem(value: "Amiri", child: Text("خط Amiri")),
                              ],
                              onChanged: (val) => setState(() => selectedFontFamily = val!),
                              decoration: const InputDecoration(labelText: "نوع الخط", border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: DropdownButtonFormField(
                              initialValue: fontColor,
                              items: const [
                                DropdownMenuItem(value: Color(0xFF0F172A), child: Text("أسود داكن (افتراضي)")),
                                DropdownMenuItem(value: Color(0xFF2563EB), child: Text("أزرق")),
                                DropdownMenuItem(value: Color(0xFFDC2626), child: Text("أحمر")),
                                DropdownMenuItem(value: Color(0xFF059669), child: Text("أخضر")),
                                DropdownMenuItem(value: Color(0xFFD97706), child: Text("برتقالي")),
                              ],
                              onChanged: (val) => setState(() => fontColor = val!),
                              decoration: const InputDecoration(labelText: "لون الخط", border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. قسم تخصيص أبعاد اللوجو (الشعار) وإظهاره/إخفاؤه
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("تخصيص أبعاد اللوجو (الشعار)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const Divider(),
                      const SizedBox(height: 10),

                      // زر إظهار/إخفاء اللوجو
                      SwitchListTile(
                        title: const Text("إظهار شعار الشركة (Logo) في التقارير والفواتير"),
                        value: showCompanyLogo,
                        onChanged: (val) => setState(() => showCompanyLogo = val),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.folder_open),
                              label: Text(logoPath != null ? "تم اختيار الشعار بنجاح" : "اختر شعار الشركة (Logo)"),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("عرض اللوجو (العرض الأفقي): ${logoWidth.toInt()} px"),
                                Slider(
                                  value: logoWidth,
                                  min: 20,
                                  max: 120,
                                  divisions: 20,
                                  label: logoWidth.toInt().toString(),
                                  onChanged: (val) => setState(() => logoWidth = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ارتفاع اللوجو (الارتفاع الرأسي): ${logoHeight.toInt()} px"),
                                Slider(
                                  value: logoHeight,
                                  min: 20,
                                  max: 120,
                                  divisions: 20,
                                  label: logoHeight.toInt().toString(),
                                  onChanged: (val) => setState(() => logoHeight = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. قسم إدارة المستخدمين والصلاحيات
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("إدارة المستخدمين والصلاحيات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(labelText: "اسم المستخدم", border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField(
                              initialValue: selectedRole,
                              items: const [
                                DropdownMenuItem(value: "مدير أساسي", child: Text("مدير أساسي (تحكم كامل)")),
                                DropdownMenuItem(value: "موظف", child: Text("موظف (تخصيص الصلاحيات)")),
                              ],
                              onChanged: (val) => setState(() => selectedRole = val!),
                              decoration: const InputDecoration(labelText: "نوع الحساب", border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (selectedRole == "موظف") ...[
                        const Text("تخصيص الصلاحيات (أزرار لوحة التحكم المسموح بها):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 15,
                          runSpacing: 5,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowOrdersEntry, onChanged: (v) => setState(() => allowOrdersEntry = v!)), const Text("إدخال البيانات")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowClientsReport, onChanged: (v) => setState(() => allowClientsReport = v!)), const Text("تقرير العملاء")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowDatabase, onChanged: (v) => setState(() => allowDatabase = v!)), const Text("قاعدة البيانات")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowStatement, onChanged: (v) => setState(() => allowStatement = v!)), const Text("كشف حساب")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowProfit, onChanged: (v) => setState(() => allowProfit = v!)), const Text("الأرباح")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowLists, onChanged: (v) => setState(() => allowLists = v!)), const Text("القوائم والأسعار")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowSettings, onChanged: (v) => setState(() => allowSettings = v!)), const Text("إعدادات النظام")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowGeneralSummary, onChanged: (v) => setState(() => allowGeneralSummary = v!)), const Text("الملخص العام")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowSearchOptions, onChanged: (v) => setState(() => allowSearchOptions = v!)), const Text("البحث المتعدد")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowArchive, onChanged: (v) => setState(() => allowArchive = v!)), const Text("استعراض الأرشيف")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowQuotationsEntry, onChanged: (v) => setState(() => allowQuotationsEntry = v!)), const Text("إدخال بيانات العرض")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowQuotationsClients, onChanged: (v) => setState(() => allowQuotationsClients = v!)), const Text("تقرير عملاء العرض")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowQuotationsDatabase, onChanged: (v) => setState(() => allowQuotationsDatabase = v!)), const Text("قاعدة بيانات العروض")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowQuotationsStatement, onChanged: (v) => setState(() => allowQuotationsStatement = v!)), const Text("كشف حساب العرض")]),
                            Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: allowQuotationsProfit, onChanged: (v) => setState(() => allowQuotationsProfit = v!)), const Text("أرباح العروض")]),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: _addUser,
                          icon: const Icon(Icons.person_add),
                          label: const Text("إضافة المستخدم"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("المستخدمون المسجلون:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      AppData.users.isNotEmpty
                          ? SizedBox(
                              height: 100,
                              child: ListView.builder(
                                itemCount: AppData.users.length,
                                itemBuilder: (context, index) {
                                  final user = AppData.users[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text("المستخدم: ({user['username']} (){user['role']})"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                      onPressed: () async {
                                        setState(() {
                                          AppData.users.removeAt(index);
                                        });
                                        await AppData.saveData();
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Text("لا يوجد مستخدمون مسجلون حالياً.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. زر حفظ وتفعيل الإعدادات وصيانة النظام
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("حفظ الإعدادات وصيانة النظام", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const Divider(),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveAllSettings,
                          icon: const Icon(Icons.save, size: 20),
                          label: const Text("حفظ وتفعيل الإعدادات بالكامل", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _archiveData,
                              icon: const Icon(Icons.archive),
                              label: const Text("أرشفة جميع البيانات والاحتفاظ بها"),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _confirmInitialization,
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: const Text("تهيئة كاملة للبرنامج (مسح البيانات)"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}