import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_dashboard.dart';

// ==========================================
// 1. شاشة دليل العملاء والأكواد (أونلاين)
// ==========================================
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State {
  String? selectedDocId;
  Map? selectedClientData;
  
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  final CollectionReference clientsRef = FirebaseFirestore.instance.collection('clients');

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    codeController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _addClient() async {
    if (codeController.text.isNotEmpty && nameController.text.isNotEmpty) {
      await clientsRef.add({
        "code": codeController.text,
        "name": nameController.text,
        "phone": phoneController.text,
        "createdAt": FieldValue.serverTimestamp(),
      });
      codeController.clear();
      nameController.clear();
      phoneController.clear();
    }
  }

  void _confirmDelete() async {
    if (selectedDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر للحذف")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من حذف هذا العميل من السحابة؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await clientsRef.doc(selectedDocId).delete();
                setState(() {
                  selectedDocId = null;
                  selectedClientData = null;
                });
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
          content: const Text("هل أنت متأكد من مسح جميع بيانات العملاء نهائياً؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final snapshot = await clientsRef.get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
                setState(() {
                  selectedDocId = null;
                  selectedClientData = null;
                });
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
    if (selectedDocId == null || selectedClientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر من القائمة أولاً للتعديل")));
      return;
    }
    final TextEditingController editCode = TextEditingController(text: selectedClientData!['code']);
    final TextEditingController editName = TextEditingController(text: selectedClientData!['name']);
    final TextEditingController editPhone = TextEditingController(text: selectedClientData!['phone']);

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
                  await clientsRef.doc(selectedDocId).update({
                    "code": editCode.text,
                    "name": editName.text,
                    "phone": editPhone.text,
                  });
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
        title: const Text("إدارة القوائم والأسعار ودليل العملاء (أونلاين)", style: TextStyle(color: Colors.white, fontSize: 16)),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      appDataButton("دليل العملاء والأكواد", Colors.blue, () {}),
                      appDataButtonOutlined("أنواع الخامات والأسعار", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaterialsScreen()))),
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
                        ElevatedButton.icon(onPressed: _addClient, icon: const Icon(Icons.add, size: 16), label: const Text("إضافة أونلاين"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, minimumSize: const Size(90, 35))),
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
                            child: StreamBuilder(
                              stream: clientsRef.snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Center(child: Text("حدث خطأ في تحميل البيانات"));
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final docs = snapshot.data!.docs;
                                if (docs.isEmpty) {
                                  return const Center(child: Text("لا توجد بيانات مسجلة أونلاين حالياً"));
                                }
                                return Scrollbar(
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
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final doc = docs[index];
                                            final data = doc.data() as Map;
                                            bool isSelected = selectedDocId == doc.id;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedDocId = doc.id;
                                                  selectedClientData = data;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 80, child: Text(data['code'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                    SizedBox(width: 250, child: Text(data['name'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                    SizedBox(width: 150, child: Text(data['phone'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      ElevatedButton.icon(onPressed: _showEditDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("تعديل المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                      ElevatedButton.icon(onPressed: _confirmDelete, icon: const Icon(Icons.delete, size: 16), label: const Text("حذف المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
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

// ==========================================
// 2. شاشة أنواع الخامات والأسعار (أونلاين)
// ==========================================
class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State {
  String? selectedDocId;
  Map? selectedMaterialData;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController sellController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  final CollectionReference materialsRef = FirebaseFirestore.instance.collection('materials');

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    nameController.dispose();
    sellController.dispose();
    costController.dispose();
    super.dispose();
  }

  void _addMaterial() async {
    if (nameController.text.isNotEmpty) {
      await materialsRef.add({
        "name": nameController.text,
        "sell": sellController.text,
        "cost": costController.text,
        "createdAt": FieldValue.serverTimestamp(),
      });
      nameController.clear();
      sellController.clear();
      costController.clear();
    }
  }

  void _confirmDelete() async {
    if (selectedDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر للحذف")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من حذف هذه الخامة من السحابة؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await materialsRef.doc(selectedDocId).delete();
                setState(() {
                  selectedDocId = null;
                  selectedMaterialData = null;
                });
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
                final snapshot = await materialsRef.get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
                setState(() {
                  selectedDocId = null;
                  selectedMaterialData = null;
                });
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
    if (selectedDocId == null || selectedMaterialData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر من القائمة أولاً للتعديل")));
      return;
    }
    final TextEditingController editName = TextEditingController(text: selectedMaterialData!['name']);
    final TextEditingController editSell = TextEditingController(text: selectedMaterialData!['sell']);
    final TextEditingController editCost = TextEditingController(text: selectedMaterialData!['cost']);

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
                  await materialsRef.doc(selectedDocId).update({
                    "name": editName.text,
                    "sell": editSell.text,
                    "cost": editCost.text,
                  });
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
    const double tableMinWidth = 600.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF78350F),
        title: const Text("إدارة القوائم والأسعار (الخامات أونلاين)", style: TextStyle(color: Colors.white, fontSize: 16)),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      appDataButtonOutlined("دليل العملاء والأكواد", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()))),
                      appDataButton("أنواع الخامات والأسعار", Colors.blue, () {}),
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
                        ElevatedButton.icon(onPressed: _addMaterial, icon: const Icon(Icons.add, size: 16), label: const Text("إضافة أونلاين"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, minimumSize: const Size(90, 35))),
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
                                    SizedBox(width: 250, child: Text("أنواع الخامة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    SizedBox(width: 120, child: Text("سعر البيع", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    SizedBox(width: 120, child: Text("سعر التكلفة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: StreamBuilder(
                              stream: materialsRef.snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Center(child: Text("حدث خطأ في تحميل الخامات"));
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final docs = snapshot.data!.docs;
                                if (docs.isEmpty) {
                                  return const Center(child: Text("لا توجد خامات مسجلة أونلاين حالياً"));
                                }
                                return Scrollbar(
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
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final doc = docs[index];
                                            final data = doc.data() as Map;
                                            bool isSelected = selectedDocId == doc.id;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedDocId = doc.id;
                                                  selectedMaterialData = data;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 250, child: Text(data['name'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                    SizedBox(width: 120, child: Text(data['sell'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                    SizedBox(width: 120, child: Text(data['cost'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      ElevatedButton.icon(onPressed: _showEditDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("تعديل المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                      ElevatedButton.icon(onPressed: _confirmDelete, icon: const Icon(Icons.delete, size: 16), label: const Text("حذف المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
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

// ==========================================
// 3. شاشة طرق الدفع (أونلاين)
// ==========================================
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State {
  String? selectedDocId;
  Map? selectedMethodData;

  final TextEditingController methodController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  final CollectionReference methodsRef = FirebaseFirestore.instance.collection('payment_methods');

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    methodController.dispose();
    super.dispose();
  }

  void _addMethod() async {
    if (methodController.text.isNotEmpty) {
      await methodsRef.add({
        "name": methodController.text,
        "createdAt": FieldValue.serverTimestamp(),
      });
      methodController.clear();
    }
  }

  void _confirmDelete() async {
    if (selectedDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر للحذف")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من حذف طريقة الدفع من السحابة؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await methodsRef.doc(selectedDocId).delete();
                setState(() {
                  selectedDocId = null;
                  selectedMethodData = null;
                });
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
                final snapshot = await methodsRef.get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
                setState(() {
                  selectedDocId = null;
                  selectedMethodData = null;
                });
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
    if (selectedDocId == null || selectedMethodData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر أولاً للتعديل")));
      return;
    }
    final TextEditingController editName = TextEditingController(text: selectedMethodData!['name']);

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
                await methodsRef.doc(selectedDocId).update({"name": editName.text});
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
        title: const Text("طرق الدفع (أونلاين)", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      appDataButtonOutlined("دليل العملاء", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()))),
                      appDataButtonOutlined("الخامات والأسعار", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaterialsScreen()))),
                      appDataButton("طرق الدفع", Colors.blue, () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(width: 300, child: TextField(controller: methodController, decoration: const InputDecoration(labelText: "طريقة الدفع", border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: _addMethod, child: const Text("إضافة أونلاين")),
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
                            child: StreamBuilder(
                              stream: methodsRef.snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Center(child: Text("حدث خطأ في تحميل طرق الدفع"));
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final docs = snapshot.data!.docs;
                                if (docs.isEmpty) {
                                  return const Center(child: Text("لا توجد طرق دفع مسجلة أونلاين حالياً"));
                                }
                                return Scrollbar(
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
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final doc = docs[index];
                                            final data = doc.data() as Map;
                                            bool isSelected = selectedDocId == doc.id;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedDocId = doc.id;
                                                  selectedMethodData = data;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                                ),
                                                child: Text(data['name'] ?? ''),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      ElevatedButton.icon(onPressed: _showEditDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("تعديل المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                      ElevatedButton.icon(onPressed: _confirmDelete, icon: const Icon(Icons.delete, size: 16), label: const Text("حذف المحدد"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
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

// ==========================================
// مساعدات الأزرار المشتركة
// ==========================================
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
