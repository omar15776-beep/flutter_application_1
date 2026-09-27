import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class AppData {
  static List<Map<String, String>> clients = [];
  static List<Map<String, String>> materials = [];
  static List<Map<String, String>> methods = [];
  static List<Map<String, String>> searchOptions = [];
  static List<Map<String, dynamic>> savedOrders = [];

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final clientsStr = prefs.getString('saved_clients');
    if (clientsStr != null) {
      clients = List<Map<String, String>>.from(json.decode(clientsStr).map((x) => Map<String, String>.from(x)));
    }

    final materialsStr = prefs.getString('saved_materials');
    if (materialsStr != null) {
      materials = List<Map<String, String>>.from(json.decode(materialsStr).map((x) => Map<String, String>.from(x)));
    }

    final methodsStr = prefs.getString('saved_methods');
    if (methodsStr != null) {
      methods = List<Map<String, String>>.from(json.decode(methodsStr).map((x) => Map<String, String>.from(x)));
    }

    final searchStr = prefs.getString('saved_search');
    if (searchStr != null) {
      searchOptions = List<Map<String, String>>.from(json.decode(searchStr).map((x) => Map<String, String>.from(x)));
    }

    final ordersStr = prefs.getString('saved_orders');
    if (ordersStr != null) {
      savedOrders = List<Map<String, dynamic>>.from(json.decode(ordersStr).map((x) => Map<String, dynamic>.from(x)));
    }
  }

  static Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_clients', json.encode(clients));
    await prefs.setString('saved_materials', json.encode(materials));
    await prefs.setString('saved_methods', json.encode(methods));
    await prefs.setString('saved_search', json.encode(searchOptions));
    await prefs.setString('saved_orders', json.encode(savedOrders));
  }
}

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
      title: 'المؤسسة التجارية - لوحة التحكم الرئيسية',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("المؤسسة التجارية - لوحة التحكم الرئيسية", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 28, color: Color(0xFF0F172A)),
                    SizedBox(width: 10),
                    Column(
                      children: [
                        Text("المؤسسة التجارية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text("لوحة التحكم والتشغيل السريع", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDashboardCard(
                        title: "البيانات الجديدة",
                        headerColor: const Color(0xFF2563EB),
                        buttons: [
                          _buildMenuButton("إدخال البيانات", Icons.edit_note, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersEntryScreen()));
                          }),
                          _buildMenuButton("تقرير العملاء", Icons.people, () {}),
                          _buildMenuButton("قاعدة البيانات", Icons.table_chart, () {}),
                          _buildMenuButton("كشف حساب", Icons.receipt_long, () {}),
                          _buildMenuButton("الأرباح", Icons.account_balance_wallet, () {}),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDashboardCard(
                        title: "القوائم والبحث",
                        headerColor: const Color(0xFFD97706),
                        buttons: [
                          _buildMenuButton("القوائم والأسعار", Icons.list_alt, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
                          }),
                          _buildMenuButton("إعدادات النظام والشركة", Icons.settings, () {}),
                          _buildMenuButton("الملخص العام", Icons.fact_check, () {}),
                          _buildMenuButton("البحث المتعدد", Icons.search, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchOptionsScreen()));
                          }),
                          _buildMenuButton("استعراض الأرشيف", Icons.archive, () {}),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDashboardCard(
                        title: "عروض الأسعار",
                        headerColor: const Color(0xFF334155),
                        buttons: [
                          _buildMenuButton("إدخال بيانات (العرض)", Icons.local_offer, () {}),
                          _buildMenuButton("تقرير العملاء (العرض)", Icons.people_outline, () {}),
                          _buildMenuButton("قاعدة بيانات (العروض)", Icons.storage, () {}),
                          _buildMenuButton("كشف حساب (العرض)", Icons.receipt, () {}),
                          _buildMenuButton("الارباح (العرض)", Icons.trending_up, () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("2026-09-11", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Row(
                      children: [
                        Text("جاهز للعمل", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(width: 5),
                        Icon(Icons.circle, size: 10, color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({required String title, required Color headerColor, required List<Widget> buttons}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: headerColor, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: headerColor),
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: buttons),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
        label: Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerRight,
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

class OrdersEntryScreen extends StatefulWidget {
  const OrdersEntryScreen({super.key});

  @override
  _OrdersEntryScreenState createState() => _OrdersEntryScreenState();
}

class _OrdersEntryScreenState extends State<OrdersEntryScreen> {
  final TextEditingController clientController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController paidController = TextEditingController(text: "0");
  
  String? paymentType;
  String orderNum = "1";
  String currentDate = "2026-09-11";

  String? lastClient;
  String? lastLocation;
  String? lastWorkType;

  @override
  void initState() {
    super.initState();
    if (AppData.methods.isNotEmpty) {
      paymentType = AppData.methods.first['name'];
    }
  }

  final List<Map<String, dynamic>> measurementRows = [
    {
      'workType': TextEditingController(),
      'material': TextEditingController(),
      'qty': TextEditingController(text: "1"),
      'height': TextEditingController(text: "0"),
      'width': TextEditingController(text: "0"),
      'area': TextEditingController(text: "0.00"),
      'sellPrice': TextEditingController(text: "0"),
      'costPrice': TextEditingController(text: "0"),
      'total': TextEditingController(text: "0.00"),
      'images': <String>[],
    }
  ];

  void _checkOrderNum(String currentWorkType) {
    String currentClient = clientController.text;
    String currentLocation = locationController.text;

    if (lastClient != null && lastLocation != null && lastWorkType != null) {
      if (lastClient != currentClient || lastLocation != currentLocation || lastWorkType != currentWorkType) {
        setState(() {
          orderNum = (int.parse(orderNum) + 1).toString();
        });
      }
    }
    lastClient = currentClient;
    lastLocation = currentLocation;
    lastWorkType = currentWorkType;
  }

  void _addRow() {
    setState(() {
      measurementRows.add({
        'workType': TextEditingController(),
        'material': TextEditingController(),
        'qty': TextEditingController(text: "1"),
        'height': TextEditingController(text: "0"),
        'width': TextEditingController(text: "0"),
        'area': TextEditingController(text: "0.00"),
        'sellPrice': TextEditingController(text: "0"),
        'costPrice': TextEditingController(text: "0"),
        'total': TextEditingController(text: "0.00"),
        'images': <String>[],
      });
    });
  }

  void _calculateRow(int index) {
    final row = measurementRows[index];
    double qty = double.tryParse(row['qty'].text) ?? 0;
    double height = double.tryParse(row['height'].text) ?? 0;
    double width = double.tryParse(row['width'].text) ?? 0;
    double sell = double.tryParse(row['sellPrice'].text) ?? 0;

    double area = (height * width * qty) / 10000;
    double total = area > 0 ? area * sell : qty * sell;

    setState(() {
      row['area'].text = area.toStringAsFixed(2);
      row['total'].text = total.toStringAsFixed(2);
    });
  }

  double get totalOrderAmount {
    double sum = 0;
    for (var row in measurementRows) {
      sum += double.tryParse(row['total'].text) ?? 0;
    }
    return sum;
  }

  void _showImagesDialog(int index) {
    final row = measurementRows[index];
    List<String> images = List<String>.from(row['images']);
    final TextEditingController imgController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text("إدارة الصور المتعددة للبند"),
                content: SizedBox(
                  width: 450,
                  height: 380,
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: true,
                          );
                          if (result != null) {
                            setDialogState(() {
                              for (var file in result.files) {
                                if (file.name.isNotEmpty) {
                                  images.add(file.name);
                                }
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text("تصفح واختيار صورة من جهاز الكمبيوتر"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 38)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imgController,
                              decoration: const InputDecoration(
                                hintText: "أو اكتب اسم الصورة يدوياً",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (imgController.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  images.add(imgController.text.trim());
                                  imgController.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text("إضافة"),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, imgIdx) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.image, color: Colors.blue, size: 18),
                              title: Text(images[imgIdx], style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                onPressed: () {
                                  setDialogState(() {
                                    images.removeAt(imgIdx);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        row['images'] = images;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("حفظ الصور"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double paid = double.tryParse(paidController.text) ?? 0;
    double total = totalOrderAmount;
    double remaining = total - paid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("شاشة إدخال البيانات ومقاسات الطلبات", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
                ),
                child: Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    SizedBox(
                      width: 280,
                      child: Row(
                        children: [
                          const SizedBox(width: 70, child: Text("اسم العميل:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: Autocomplete<Map<String, String>>(
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) return AppData.clients;
                                  return AppData.clients.where((c) => c['name']!.contains(textEditingValue.text));
                                },
                                displayStringForOption: (option) => option['name']!,
                                onSelected: (selection) {
                                  setState(() {
                                    clientController.text = selection['name']!;
                                    codeController.text = selection['code']!;
                                    phoneController.text = selection['phone']!;
                                  });
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  if (controller.text.isEmpty && clientController.text.isNotEmpty) {
                                    controller.text = clientController.text;
                                  }
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                                    style: const TextStyle(fontSize: 12),
                                    onChanged: (val) => setState(() => clientController.text = val),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 250, child: Row(children: [const SizedBox(width: 70, child: Text("مكان العمل:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: SizedBox(height: 32, child: TextField(controller: locationController, onChanged: (v) => setState(() {}), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)))) )])),
                    SizedBox(width: 180, child: Row(children: [const SizedBox(width: 50, child: Text("الكود:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: SizedBox(height: 32, child: TextField(controller: codeController, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)))) )])),
                    SizedBox(width: 180, child: Row(children: [const SizedBox(width: 50, child: Text("المدفوع:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: SizedBox(height: 32, child: TextField(controller: paidController, textAlign: TextAlign.center, onChanged: (v) => setState(() {}), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)))) )])),
                    SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          const SizedBox(width: 65, child: Text("نوع الدفع:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: DropdownButtonFormField<String>(
                                value: paymentType,
                                isExpanded: true,
                                items: AppData.methods.isEmpty
                                    ? [const DropdownMenuItem(value: "نقدي", child: Text("نقدي", style: TextStyle(fontSize: 12)))]
                                    : AppData.methods.map((m) => DropdownMenuItem(value: m['name'], child: Text(m['name']!, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) => setState(() => paymentType = val),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 180, child: Row(children: [const SizedBox(width: 65, child: Text("رقم الطلب:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: Container(height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: Text(orderNum, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))))])),
                    SizedBox(width: 220, child: Row(children: [const SizedBox(width: 50, child: Text("التليفون:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: SizedBox(height: 32, child: TextField(controller: phoneController, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)))) )])),
                    SizedBox(width: 200, child: Row(children: [const SizedBox(width: 50, child: Text("التاريخ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: Container(height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: Text(currentDate, style: const TextStyle(fontSize: 12))))])),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("جدول المقاسات والأصناف", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ElevatedButton.icon(
                            onPressed: _addRow,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text("إضافة صنف"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: const BoxDecoration(color: Color(0xFF334155)),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text("نوع العمل", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text("نوع الخامة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("العدد", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("الطول", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("العرض", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("المساحة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("سعر البيع", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("سعر التكلفة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("الإجمالي", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("صورة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 30),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: measurementRows.length,
                      itemBuilder: (context, index) {
                        final row = measurementRows[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 28,
                                  child: TextField(
                                    controller: row['workType'],
                                    onChanged: (val) => _checkOrderNum(val),
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 28,
                                  child: Autocomplete<Map<String, String>>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) return AppData.materials;
                                      return AppData.materials.where((m) => m['name']!.contains(textEditingValue.text));
                                    },
                                    displayStringForOption: (option) => option['name']!,
                                    onSelected: (selection) {
                                      setState(() {
                                        row['material'].text = selection['name']!;
                                        row['sellPrice'].text = selection['sell']!;
                                        row['costPrice'].text = selection['cost']!;
                                        _calculateRow(index);
                                      });
                                    },
                                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                      if (controller.text.isEmpty && row['material'].text.isNotEmpty) {
                                        controller.text = row['material'].text;
                                      }
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
                                        style: const TextStyle(fontSize: 11),
                                        onChanged: (val) => row['material'].text = val,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['qty'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), onChanged: (v) => _calculateRow(index), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
                              const SizedBox(width: 4),
                              Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['height'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), onChanged: (v) => _calculateRow(index), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
                              const SizedBox(width: 4),
                              Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['width'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), onChanged: (v) => _calculateRow(index), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
                              const SizedBox(width: 4),
                              Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['area'], readOnly: true, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
                              const SizedBox(width: 4),
                              Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['sellPrice'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), onChanged: (v) => _calculateRow(index), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
                              const SizedBox(width: 4),
                              Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['costPrice'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
                              const SizedBox(width: 4),
                              Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['total'], readOnly: true, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 28,
                                  child: OutlinedButton(
                                    onPressed: () => _showImagesDialog(index),
                                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(30, 28)),
                                    child: Text("صور (${(row['images'] as List).length})", style: const TextStyle(fontSize: 8)),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                onPressed: () {
                                  setState(() {
                                    if (measurementRows.length > 1) measurementRows.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("إجمالي الطلب: ${total.toStringAsFixed(2)} ج.م | المدفوع: $paid ج.م | الباقي: ${remaining.toStringAsFixed(2)} ج.م",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (clientController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى اختيار اسم العميل!")));
                        return;
                      }
                      for (var row in measurementRows) {
                        AppData.savedOrders.add({
                          'order': orderNum,
                          'code': codeController.text,
                          'client': clientController.text,
                          'location': locationController.text,
                          'workType': row['workType'].text,
                          'material': row['material'].text,
                          'qty': row['qty'].text,
                          'height': row['height'].text,
                          'width': row['width'].text,
                          'area': row['area'].text,
                          'sell': row['sellPrice'].text,
                          'cost': row['costPrice'].text,
                          'total': row['total'].text,
                          'paid': paidController.text,
                          'method': paymentType ?? 'نقدي',
                          'date': currentDate,
                          'images': List<String>.from(row['images']),
                        });
                      }
                      AppData.saveData();
                      setState(() {
                        orderNum = (int.parse(orderNum) + 1).toString();
                        clientController.clear();
                        locationController.clear();
                        codeController.clear();
                        phoneController.clear();
                        paidController.text = "0";
                        measurementRows.clear();
                        _addRow();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم ترحيل جميع البنود بنجاح")));
                    },
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text("ترحيل جميع البنود للطلب", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  int? selectedIndex;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

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
          child: Column(
            children: [
              Row(
                children: [
                  appDataButton("دليل العملاء والأكواد", Colors.blue, () {}),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("أنواع الخامات والأسعار", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaterialsScreen()))),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("طرق الدفع", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()))),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("خيارات البحث المتعدد", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SearchOptionsScreen()))),
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
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFF334155),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: const Row(
                          children: [
                            Expanded(flex: 1, child: Text("كود العميل", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 4, child: Text("أسماء العملاء", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text("التليفون", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                      Expanded(
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
                                    Expanded(flex: 1, child: Text(client['code']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 4, child: Text(client['name']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 2, child: Text(client['phone']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                  ],
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
    );
  }
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  int? selectedIndex;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sellController = TextEditingController();
  final TextEditingController costController = TextEditingController();

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
                      "m": AppData.materials[selectedIndex!]!['m']!,
                      "name": editName.text,
                      "sell": editSell.text,
                      "cost": editCost.text,
                    };
                  });
                  await AppData.saveData();
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
          child: Column(
            children: [
              Row(
                children: [
                  appDataButtonOutlined("دليل العملاء والأكواد", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()))),
                  const SizedBox(width: 8),
                  appDataButton("أنواع الخامات والأسعار", Colors.blue, () {}),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("طرق الدفع", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()))),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("خيارات البحث المتعدد", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SearchOptionsScreen()))),
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
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFF334155),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: const Row(
                          children: [
                            Expanded(flex: 1, child: Text("م", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 4, child: Text("أنواع الخامة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text("سعر البيع", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text("سعر التكلفة", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                      Expanded(
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
                                    Expanded(flex: 1, child: Text(mat['m']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 4, child: Text(mat['name']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 2, child: Text(mat['sell']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 2, child: Text(mat['cost']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                  ],
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
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int? selectedIndex;
  final TextEditingController methodController = TextEditingController();

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
                  AppData.methods[selectedIndex!] = {"m": AppData.methods[selectedIndex!]!['m']!, "name": editName.text};
                });
                await AppData.saveData();
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
          child: Column(
            children: [
              Row(
                children: [
                  appDataButtonOutlined("دليل العملاء", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()))),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("الخامات والأسعار", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaterialsScreen()))),
                  const SizedBox(width: 8),
                  appDataButton("طرق الدفع", Colors.blue, () {}),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("خيارات البحث", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SearchOptionsScreen()))),
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
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
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
    );
  }
}

class SearchOptionsScreen extends StatefulWidget {
  const SearchOptionsScreen({super.key});

  @override
  State<SearchOptionsScreen> createState() => _SearchOptionsScreenState();
}

class _SearchOptionsScreenState extends State<SearchOptionsScreen> {
  int? selectedIndex;
  final TextEditingController optionController = TextEditingController();

  void _addOption() async {
    if (optionController.text.isNotEmpty) {
      setState(() {
        AppData.searchOptions.add({"m": (AppData.searchOptions.length + 1).toString(), "name": optionController.text});
        optionController.clear();
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
          content: const Text("هل أنت متأكد من حذف هذا الخيار؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.searchOptions.removeAt(selectedIndex!);
                  selectedIndex = null;
                });
                await AppData.saveData();
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
          content: const Text("هل أنت متأكد من مسح جميع الخيارات؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  AppData.searchOptions.clear();
                  selectedIndex = null;
                });
                await AppData.saveData();
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
    final opt = AppData.searchOptions[selectedIndex!];
    final TextEditingController editName = TextEditingController(text: opt['name']);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تعديل خيار البحث"),
          content: TextField(controller: editName, decoration: const InputDecoration(labelText: "خيار البحث", border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  AppData.searchOptions[selectedIndex!] = {"m": AppData.searchOptions.length.toString(), "name": editName.text};
                });
                await AppData.saveData();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF78350F),
        title: const Text("خيارات البحث المتعدد", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  appDataButtonOutlined("دليل العملاء", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()))),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("الخامات والأسعار", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaterialsScreen()))),
                  const SizedBox(width: 8),
                  appDataButtonOutlined("طرق الدفع", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()))),
                  const SizedBox(width: 8),
                  appDataButton("خيارات البحث", Colors.blue, () {}),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(width: 300, child: TextField(controller: optionController, decoration: const InputDecoration(labelText: "خيار البحث", border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: _addOption, child: const Text("إضافة")),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                  child: ListView.builder(
                    itemCount: AppData.searchOptions.length,
                    itemBuilder: (context, index) {
                      final opt = AppData.searchOptions[index];
                      bool isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIndex = index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Text(opt['name']!),
                        ),
                      );
                    },
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