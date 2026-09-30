import 'package:flutter/material.dart';
import 'app_data.dart';
import 'main_dashboard.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State {
  int? selectedIndex;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _addClient() async {
    if (codeController.text.isNotEmpty && nameController.text.isNotEmpty) {
      setState(() {
        AppData.clients.add({"code": codeController.text, "name": nameController.text, "phone": phoneController.text});
        codeController.clear();
        nameController.clear();
        phoneController.clear();
      });
      await AppData.saveData();
    }
  }

  void _confirmDelete() async {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر للحذف")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من حذف هذا السطر؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.clients.removeAt(selectedIndex!);
                  selectedIndex = null;
                });
                await AppData.saveData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("حذف"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تحذير - مسح الكل"),
          content: const Text("هل أنت متأكد من مسح جميع البيانات نهائياً؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.clients.clear();
                  selectedIndex = null;
                });
                await AppData.saveData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("مسح الكل"),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog() {
    final TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("استيراد بيانات العملاء (نسخ ولصق)"),
            content: SizedBox(
              width: 400,
              height: 200,
              child: TextField(
                controller: importController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: "الصق البيانات هنا (الكود \t الاسم \t التليفون)",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  final lines = importController.text.split('\n');
                  setState(() {
                    for (var line in lines) {
                      if (line.trim().isEmpty) continue;
                      final parts = line.trim().split(RegExp(r'\t+|\s{2,}'));
                      if (parts.length >= 3) {
                        AppData.clients.add({"code": parts[0], "name": parts[1], "phone": parts[2]});
                      } else if (parts.length == 2) {
                        AppData.clients.add({"code": (AppData.clients.length + 1).toString(), "name": parts[0], "phone": parts[1]});
                      } else {
                        AppData.clients.add({"code": (AppData.clients.length + 1).toString(), "name": line.trim(), "phone": ""});
                      }
                    }
                  });
                  await AppData.saveData();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("استيراد وإضافة"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog() {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر من القائمة أولاً للتعديل")));
      return;
    }
    final client = AppData.clients[selectedIndex!];
    final TextEditingController editCode = TextEditingController(text: client['code']);
    final TextEditingController editName = TextEditingController(text: client['name']);
    final TextEditingController editPhone = TextEditingController(text: client['phone']);

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("تعديل بيانات العميل"),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  TextField(controller: editCode, decoration: const InputDecoration(labelText: "كود العميل", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: editName, decoration: const InputDecoration(labelText: "اسم العميل", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: editPhone, decoration: const InputDecoration(labelText: "التليفون", border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    AppData.clients[selectedIndex!] = {"code": editCode.text, "name": editName.text, "phone": editPhone.text};
                  });
                  await AppData.saveData();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("حفظ التعديلات"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double tableMinWidth = 500.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF78350F),
        title: const Text("إدارة القوائم والأسعار ودليل العملاء", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => codeController.text = (AppData.clients.length + 1).toString()),
                icon: const Icon(Icons.add, size: 16),
                label: const Text("إضافة قائمة جديدة"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Center(
              child: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainDashboardScreen()), (route) => false)),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          // 📱 تفعيل التمرير العمودي الشامل للصفحة لتناسب الموبايل
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Row(
                    children: [
                      appDataButton("دليل العملاء والأكواد", Colors.blue, () {}),
                      const SizedBox(width: 8),
                      appDataButtonOutlined("أنواع الخامات والأسعار", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaterialsScreen()))),
                      const SizedBox(width: 8),
                      appDataButtonOutlined("طرق الدفع", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(width: 220, child: Row(children: [const SizedBox(width: 65, child: Text("كود العميل:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: SizedBox(height: 35, child: TextField(controller: codeController, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)))) )])),
                        SizedBox(width: 280, child: Row(children: [const SizedBox(width: 65, child: Text("اسم العميل:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: SizedBox(height: 35, child: TextField(controller: nameController, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)))) )])),
                        SizedBox(width: 250, child: Row(children: [const SizedBox(width: 50, child: Text("التليفون:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: SizedBox(height: 35, child: TextField(controller: phoneController, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)))) )])),
                        ElevatedButton.icon(onPressed: _addClient, icon: const Icon(Icons.add, size: 16), label: const Text("إضافة"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, minimumSize: const Size(90, 35))),
                        OutlinedButton.icon(onPressed: _showImportDialog, icon: const Icon(Icons.table_view, size: 16, color: Colors.green), label: const Text("استيراد", style: TextStyle(color: Colors.green)), style: OutlinedButton.styleFrom(minimumSize: const Size(90, 35))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          Container(
                            color: const Color(0xFF334155),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: tableMinWidth),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 80, child: Text("كود العميل", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    SizedBox(width: 250, child: Text("أسماء العملاء", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    SizedBox(width: 150, child: Text("التليفون", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScrollController,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: tableMinWidth),
                                  child: SizedBox(
                                    width: tableMinWidth,
                                    child: ListView.builder(
                                      itemCount: AppData.clients.length,
                                      itemBuilder: (context, index) {
                                        final client = AppData.clients[index];
                                        bool isSelected = selectedIndex == index;
                                        return GestureDetector(
                                          onTap: () => setState(() => selectedIndex = index),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 80, child: Text(client['code']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                SizedBox(width: 250, child: Text(client['name']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                SizedBox(width: 150, child: Text(client['phone']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(onPressed: _showEditDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("تعديل المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _confirmDelete, icon: const Icon(Icons.delete, size: 16), label: const Text("حذف المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _confirmClearAll, icon: const Icon(Icons.delete_sweep, size: 16), label: const Text("مسح الكل"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State {
  int? selectedIndex;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sellController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _addMaterial() async {
    if (nameController.text.isNotEmpty) {
      setState(() {
        AppData.materials.add({
          "m": (AppData.materials.length + 1).toString(),
          "name": nameController.text,
          "sell": sellController.text,
          "cost": costController.text,
        });
        nameController.clear();
        sellController.clear();
        costController.clear();
      });
      await AppData.saveData();
    }
  }

  void _confirmDelete() async {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر للحذف")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من حذف هذه الخامة؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.materials.removeAt(selectedIndex!);
                  selectedIndex = null;
                });
                await AppData.saveData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("حذف"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تحذير - مسح الكل"),
          content: const Text("هل أنت متأكد من مسح جميع الخامات نهائياً؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.materials.clear();
                  selectedIndex = null;
                });
                await AppData.saveData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("مسح الكل"),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog() {
    final TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("استيراد بيانات الخامات (نسخ ولصق)"),
            content: SizedBox(
              width: 400,
              height: 200,
              child: TextField(
                controller: importController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: "الصق البيانات هنا (نوع الخامة \t سعر البيع \t سعر التكلفة)",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  final lines = importController.text.split('\n');
                  setState(() {
                    for (var line in lines) {
                      if (line.trim().isEmpty) continue;
                      final parts = line.trim().split(RegExp(r'\t+|\s{2,}'));
                      if (parts.length >= 3) {
                        AppData.materials.add({
                          "m": (AppData.materials.length + 1).toString(),
                          "name": parts[0],
                          "sell": parts[1],
                          "cost": parts[2],
                        });
                      }
                    }
                  });
                  await AppData.saveData();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("استيراد وإضافة"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog() {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر من القائمة أولاً للتعديل")));
      return;
    }
    final mat = AppData.materials[selectedIndex!];
    final TextEditingController editName = TextEditingController(text: mat['name']);
    final TextEditingController editSell = TextEditingController(text: mat['sell']);
    final TextEditingController editCost = TextEditingController(text: mat['cost']);

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("تعديل بيانات الخامة"),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  TextField(controller: editName, decoration: const InputDecoration(labelText: "نوع الخامة", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: editSell, decoration: const InputDecoration(labelText: "سعر البيع", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: editCost, decoration: const InputDecoration(labelText: "سعر التكلفة", border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    AppData.materials[selectedIndex!] = {
                      "m": AppData.materials[selectedIndex!]['m']!,
                      "name": editName.text,
                      "sell": editSell.text,
                      "cost": editCost.text,
                    };
                  });
                  await AppData.saveData();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("حفظ التعديلات"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double tableMinWidth = 550.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF78350F),
        title: const Text("إدارة القوائم والأسعار ودليل العملاء", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Center(
              child: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainDashboardScreen()), (route) => false)),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          // 📱 تفعيل التمرير العمودي الشامل للصفحة لتناسب الموبايل
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Row(
                    children: [
                      appDataButtonOutlined("دليل العملاء والأكواد", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()))),
                      const SizedBox(width: 8),
                      appDataButton("أنواع الخامات والأسعار", Colors.blue, () {}),
                      const SizedBox(width: 8),
                      appDataButtonOutlined("طرق الدفع", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(width: 250, child: Row(children: [const SizedBox(width: 65, child: Text("الخامة:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: SizedBox(height: 35, child: TextField(controller: nameController, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)))) )])),
                        SizedBox(width: 180, child: Row(children: [const SizedBox(width: 50, child: Text("البيع:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: SizedBox(height: 35, child: TextField(controller: sellController, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)))) )])),
                        SizedBox(width: 180, child: Row(children: [const SizedBox(width: 50, child: Text("التكلفة:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: SizedBox(height: 35, child: TextField(controller: costController, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)))) )])),
                        ElevatedButton.icon(onPressed: _addMaterial, icon: const Icon(Icons.add, size: 16), label: const Text("إضافة"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, minimumSize: const Size(90, 35))),
                        OutlinedButton.icon(onPressed: _showImportDialog, icon: const Icon(Icons.table_view, size: 16, color: Colors.green), label: const Text("استيراد", style: TextStyle(color: Colors.green)), style: OutlinedButton.styleFrom(minimumSize: const Size(90, 35))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          Container(
                            color: const Color(0xFF334155),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: tableMinWidth),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 50, child: Text("م", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    SizedBox(width: 250, child: Text("أنواع الخامة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    SizedBox(width: 120, child: Text("سعر البيع", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    SizedBox(width: 120, child: Text("سعر التكلفة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScrollController,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: tableMinWidth),
                                  child: SizedBox(
                                    width: tableMinWidth,
                                    child: ListView.builder(
                                      itemCount: AppData.materials.length,
                                      itemBuilder: (context, index) {
                                        final mat = AppData.materials[index];
                                        bool isSelected = selectedIndex == index;
                                        return GestureDetector(
                                          onTap: () => setState(() => selectedIndex = index),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 50, child: Text(mat['m']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                SizedBox(width: 250, child: Text(mat['name']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                SizedBox(width: 120, child: Text(mat['sell']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                SizedBox(width: 120, child: Text(mat['cost']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(onPressed: _showEditDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("تعديل المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _confirmDelete, icon: const Icon(Icons.delete, size: 16), label: const Text("حذف المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _confirmClearAll, icon: const Icon(Icons.delete_sweep, size: 16), label: const Text("مسح الكل"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State {
  int? selectedIndex;
  final TextEditingController methodController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _addMethod() async {
    if (methodController.text.isNotEmpty) {
      setState(() {
        AppData.methods.add({"m": (AppData.methods.length + 1).toString(), "name": methodController.text});
        methodController.clear();
      });
      await AppData.saveData();
    }
  }

  void _confirmDelete() async {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر للحذف")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من حذف هذه الطريقة؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.methods.removeAt(selectedIndex!);
                  selectedIndex = null;
                });
                await AppData.saveData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("حذف"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تحذير - مسح الكل"),
          content: const Text("هل أنت متأكد من مسح جميع طرق الدفع؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.methods.clear();
                  selectedIndex = null;
                });
                await AppData.saveData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("مسح الكل"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر أولاً للتعديل")));
      return;
    }
    final m = AppData.methods[selectedIndex!];
    final TextEditingController editName = TextEditingController(text: m['name']);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تعديل طريقة الدفع"),
          content: TextField(controller: editName, decoration: const InputDecoration(labelText: "طريقة الدفع", border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  AppData.methods[selectedIndex!] = {"m": AppData.methods[selectedIndex!]['m']!, "name": editName.text};
                });
                await AppData.saveData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double tableMinWidth = 300.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF78350F),
        title: const Text("طرق الدفع", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          // 📱 تفعيل التمرير العمودي الشامل للصفحة لتناسب الموبايل
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Row(
                    children: [
                      appDataButtonOutlined("دليل العملاء", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()))),
                      const SizedBox(width: 8),
                      appDataButtonOutlined("الخامات والأسعار", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaterialsScreen()))),
                      const SizedBox(width: 8),
                      appDataButton("طرق الدفع", Colors.blue, () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(width: 300, child: TextField(controller: methodController, decoration: const InputDecoration(labelText: "طريقة الدفع", border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: _addMethod, child: const Text("إضافة")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          Container(
                            color: const Color(0xFF334155),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: tableMinWidth),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 250, child: Text("طرق الدفع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScrollController,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: tableMinWidth),
                                  child: SizedBox(
                                    width: tableMinWidth,
                                    child: ListView.builder(
                                      itemCount: AppData.methods.length,
                                      itemBuilder: (context, index) {
                                        final m = AppData.methods[index];
                                        bool isSelected = selectedIndex == index;
                                        return GestureDetector(
                                          onTap: () => setState(() => selectedIndex = index),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                            ),
                                            child: Text(m['name']!),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(onPressed: _showEditDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("تعديل المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _confirmDelete, icon: const Icon(Icons.delete, size: 16), label: const Text("حذف المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _confirmClearAll, icon: const Icon(Icons.delete_sweep, size: 16), label: const Text(" مسح الكل"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget appDataButton(String text, Color color, VoidCallback onPressed) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.list, size: 16),
    label: Text(text),
    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
  );
}

Widget appDataButtonOutlined(String text, VoidCallback onPressed) {
  return OutlinedButton(
    onPressed: onPressed,
    child: Text(text),
  );
}