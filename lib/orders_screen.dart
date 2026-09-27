import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'app_data.dart';

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
  
  String paymentType = "نقدي";
  String orderNum = "1";
  String currentDate = "2026-09-14";
  int? selectedSavedIndex;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _normalizeAndAssignOrderNumbers();
    _updateOrderNumber();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  String _formatMoney(dynamic value) {
    double number = double.tryParse(value?.toString() ?? '0') ?? 0;
    String parts = number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
    List<String> segments = parts.split('.');
    RegExp regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    segments[0] = segments[0].replaceAllMapped(regExp, (Match m) => '${m[1]},');
    return segments.join('.');
  }

  void _normalizeAndAssignOrderNumbers() {
    Map<String, String> groupOrderMap = {};
    int nextOrderNumber = 1;

    for (var order in AppData.savedOrders) {
      String client = (order['client'] ?? order['client_name'] ?? '').toString().trim();
      String location = (order['location'] ?? order['work_location'] ?? '').toString().trim();
      String workType = (order['workType'] ?? order['work_type'] ?? '').toString().trim();

      if (client.isEmpty && location.isEmpty && workType.isEmpty) continue;

      String uniqueKey = "$client|$location|$workType";

      if (!groupOrderMap.containsKey(uniqueKey)) {
        groupOrderMap[uniqueKey] = nextOrderNumber.toString();
        nextOrderNumber++;
      }
      order['order'] = groupOrderMap[uniqueKey];
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

  void _updateOrderNumber() {
    String currentClient = clientController.text.trim();
    String currentLocation = locationController.text.trim();
    String currentWorkType = measurementRows.isNotEmpty ? measurementRows[0]['workType'].text.trim() : "";

    if (currentClient.isEmpty || currentLocation.isEmpty || currentWorkType.isEmpty) {
      return;
    }

    bool foundMatch = false;
    String matchedOrderNum = "1";

    for (var order in AppData.savedOrders) {
      String savedClient = (order['client'] ?? order['client_name'] ?? '').toString().trim();
      String savedLocation = (order['location'] ?? order['work_location'] ?? '').toString().trim();
      String savedWorkType = (order['workType'] ?? order['work_type'] ?? '').toString().trim();

      if (savedClient == currentClient && savedLocation == currentLocation && savedWorkType == currentWorkType) {
        foundMatch = true;
        matchedOrderNum = (order['order'] ?? order['order_num'] ?? '1').toString();
        break;
      }
    }

    setState(() {
      if (foundMatch) {
        orderNum = matchedOrderNum;
      } else {
        int maxOrd = 0;
        for (var order in AppData.savedOrders) {
          int? ordVal = int.tryParse((order['order'] ?? order['order_num'] ?? '0').toString());
          if (ordVal != null && ordVal > maxOrd) {
            maxOrd = ordVal;
          }
        }
        orderNum = (maxOrd + 1).toString();
      }
    });
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

  void _shiftOrder() async {
    double paid = double.tryParse(paidController.text) ?? 0;
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
        'paid': paid.toString(),
        'method': paymentType,
        'date': currentDate,
        'images': List<String>.from(row['images']),
      });
    }
    _normalizeAndAssignOrderNumbers();
    await AppData.saveData();
    setState(() {
      clientController.clear();
      locationController.clear();
      codeController.clear();
      phoneController.clear();
      paidController.text = "0";
      measurementRows.clear();
      _addRow();
      _updateOrderNumber();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم ترحيل وحفظ الطلب بنجاح")));
  }

  void _deleteSelectedSaved() async {
    if (selectedSavedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد سطر من السجلات المحفوظة أدناه للحذف")));
      return;
    }
    setState(() {
      AppData.savedOrders.removeAt(selectedSavedIndex!);
      selectedSavedIndex = null;
      _normalizeAndAssignOrderNumbers();
    });
    await AppData.saveData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف السطر وتحديث الحفظ الدائم")));
  }

  // دالة إدارة الصور المتوافقة تماماً مع المتصفح والمنصات عبر الـ Base64
  void _showImagesDialog(int index) {
    final row = measurementRows[index];
    List<String> images = List<String>.from(row['images']);

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
                  width: 500,
                  height: 400,
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: true,
                            withData: true, // ضروري جداً لقراءة الـ bytes عبر المتصفح
                          );
                          if (result != null) {
                            setDialogState(() {
                              for (var file in result.files) {
                                if (file.bytes != null) {
                                  String base64Image = base64Encode(file.bytes!);
                                  String imageUrl = 'data:image/png;base64,$base64Image';
                                  images.add(imageUrl);
                                }
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text("تصفح واختيار صور"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 38)),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      Expanded(
                        child: images.isEmpty
                            ? const Center(child: Text("لا توجد صور مرفقة بعد", style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: images.length,
                                itemBuilder: (context, imgIdx) {
                                  String imgData = images[imgIdx];

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.image, color: Colors.blue, size: 24),
                                      title: Text("صورة رقم ${imgIdx + 1}", style: const TextStyle(fontSize: 12)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility, color: Colors.green, size: 18),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => Dialog(
                                                  insetPadding: const EdgeInsets.all(20),
                                                  child: Container(
                                                    width: MediaQuery.of(context).size.width * 0.8,
                                                    height: MediaQuery.of(context).size.height * 0.85,
                                                    padding: const EdgeInsets.all(16.0),
                                                    child: Column(
                                                      children: [
                                                        const Text("معاينة الصورة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                        const SizedBox(height: 12),
                                                        Expanded(
                                                          child: Center(
                                                            child: imgData.startsWith('data:image')
                                                                ? InteractiveViewer(
                                                                    panEnabled: true,
                                                                    boundaryMargin: const EdgeInsets.all(20),
                                                                    minScale: 0.5,
                                                                    maxScale: 4.0,
                                                                    child: Image.memory(
                                                                      base64Decode(imgData.split(',').last),
                                                                      fit: BoxFit.contain,
                                                                    ),
                                                                  )
                                                                : const Text("الصورة غير متوفرة", style: TextStyle(color: Colors.grey)),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 15),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.pop(ctx),
                                                          child: const Text("إغلاق المعاينة"),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                            onPressed: () {
                                              setDialogState(() {
                                                images.removeAt(imgIdx);
                                              });
                                            },
                                          ),
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
    double total = totalOrderAmount;
    double paid = double.tryParse(paidController.text) ?? 0;
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
        child: Padding(
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
                                    _updateOrderNumber();
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
                                    onChanged: (val) {
                                      setState(() {
                                        clientController.text = val;
                                        _updateOrderNumber();
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: Row(
                        children: [
                          const SizedBox(width: 70, child: Text("مكان العمل:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: locationController,
                                onChanged: (v) {
                                  setState(() {
                                    _updateOrderNumber();
                                  });
                                },
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 180, child: Row(children: [const SizedBox(width: 50, child: Text("الكود:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: SizedBox(height: 32, child: TextField(controller: codeController, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)))) )])),
                    SizedBox(
                      width: 220,
                      child: Row(
                        children: [
                          const SizedBox(width: 50, child: Text("المدفوع:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: paidController,
                                textAlign: TextAlign.center,
                                onChanged: (v) => setState(() {}),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: Row(
                        children: [
                          const SizedBox(width: 60, child: Text("نوع الدفع:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: DropdownButtonFormField<String>(
                                value: paymentType,
                                isExpanded: true,
                                items: ["نقدي", "تحويل بنكي", "شيك", "أخرى"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 11)))).toList(),
                                onChanged: (val) => setState(() => paymentType = val!),
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
              const SizedBox(height: 10),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
                        ),
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
                            SizedBox(width: 35, child: Text("م", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
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
                      Expanded(
                        child: ListView.builder(
                          itemCount: measurementRows.length,
                          itemBuilder: (context, index) {
                            final row = measurementRows[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 35,
                                    child: Text(
                                      "${index + 1}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    flex: 3,
                                    child: SizedBox(
                                      height: 28,
                                      child: TextField(
                                        controller: row['workType'],
                                        onChanged: (val) {
                                          setState(() {
                                            _updateOrderNumber();
                                          });
                                        },
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
                                  Expanded(flex: 1, child: SizedBox(height: 28, child: TextField(controller: row['costPrice'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), onChanged: (v) => _calculateRow(index), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero)))),
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("إجمالي الطلب: ${_formatMoney(total)} ج.م | المدفوع: ${_formatMoney(paid)} ج.م | الباقي: ${_formatMoney(remaining)} ج.م",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _shiftOrder,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text("ترحيل جميع البنود للطلب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6)),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _deleteSelectedSaved,
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text("مسح المحددة من المحفوظات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF334155),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(7),
                            topRight: Radius.circular(7),
                          ),
                        ),
                        child: const Text(
                          "📊 السجلات المحفوظة مؤخراً في قاعدة البيانات (تحديد سطر للحذف)",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      Container(
                        color: const Color(0xFF475569),
                        child: SingleChildScrollView(
                          controller: ScrollController(),
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1400),
                            child: Row(
                              children: const [
                                SizedBox(width: 70, child: Padding(padding: EdgeInsets.all(8.0), child: Text("رقم الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 65, child: Padding(padding: EdgeInsets.all(8.0), child: Text("الكود", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 115, child: Padding(padding: EdgeInsets.all(8.0), child: Text("اسم العميل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(8.0), child: Text("مكان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(8.0), child: Text("نوع العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 115, child: Padding(padding: EdgeInsets.all(8.0), child: Text("الخامة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(8.0), child: Text("العدد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(8.0), child: Text("الطول", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(8.0), child: Text("العرض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 70, child: Padding(padding: EdgeInsets.all(8.0), child: Text("المساحة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 80, child: Padding(padding: EdgeInsets.all(8.0), child: Text("سعر البيع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 75, child: Padding(padding: EdgeInsets.all(8.0), child: Text("التكلفة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 85, child: Padding(padding: EdgeInsets.all(8.0), child: Text("الإجمالي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 75, child: Padding(padding: EdgeInsets.all(8.0), child: Text("المدفوع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 85, child: Padding(padding: EdgeInsets.all(8.0), child: Text("نوع الدفع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(8.0), child: Text("التاريخ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 75, child: Padding(padding: EdgeInsets.all(8.0), child: Text("الصورة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
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
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 1400),
                              child: SizedBox(
                                width: 1400,
                                child: ListView.builder(
                                  itemCount: AppData.savedOrders.length,
                                  itemBuilder: (context, index) {
                                    final item = AppData.savedOrders[index];
                                    bool isSelected = selectedSavedIndex == index;
                                    List imagesList = item['images'] ?? [];
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedSavedIndex = index;
                                        });
                                      },
                                      child: Container(
                                        color: isSelected ? Colors.blue.shade100 : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 70, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['order']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 65, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['code']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 115, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['client']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['location']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['workType']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 115, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['material']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['qty']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['height']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['width']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 70, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['area']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['sell']), style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 75, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['cost']), style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 85, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['total']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)))),
                                            SizedBox(width: 75, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['paid'] ?? '0'), style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 85, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['method'] ?? 'نقدي'}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['date']}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 75, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("صور (${imagesList.length})", style: const TextStyle(fontSize: 11)))),
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
            ],
          ),
        ),
      ),
    );
  }
}