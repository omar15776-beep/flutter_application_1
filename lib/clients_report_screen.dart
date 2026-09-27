import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_data.dart';

class ClientsReportScreen extends StatefulWidget {
  const ClientsReportScreen({super.key});

  @override
  _ClientsReportScreenState createState() => _ClientsReportScreenState();
}

class _ClientsReportScreenState extends State<ClientsReportScreen> {
  String? selectedClient;
  String? selectedLocation;
  String? selectedDateFrom;
  String? selectedDateTo;
  String? selectedOrderNum;
  int? selectedRowIndex;

  final ScrollController _horizontalScrollController = ScrollController();

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

  // دالة عرض الصور المتوافقة مع المتصفح والـ Base64
  void _showImageDialog(Map<String, dynamic> item) {
    List images = item['images'] ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text("صور البند (رقم الطلب: ${item['order'] ?? item['order_num'] ?? ''})"),
                content: SizedBox(
                  width: 500,
                  height: 400,
                  child: images.isEmpty
                      ? const Center(child: Text("لا توجد صور مرفقة لهذا البند"))
                      : ListView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            String imgData = images[index].toString();

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.image, color: Colors.blue, size: 30),
                                title: Text("صورة رقم ${index + 1}", style: const TextStyle(fontSize: 13)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.green),
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
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        setDialogState(() {
                                          images.removeAt(index);
                                        });
                                        item['images'] = images;
                                        await AppData.saveData();
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("تم حذف الصورة بنجاح من أرشيف البند"))
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("إغلاق")),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteSelectedRow() async {
    if (selectedRowIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد صف من الجدول للحذف")));
      return;
    }
    setState(() {
      AppData.savedOrders.removeAt(selectedRowIndex!);
      selectedRowIndex = null;
    });
    await AppData.saveData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف البند بنجاح")));
  }

  void _exportToPdf() async {
    List<Map<String, dynamic>> filteredList = _getFilteredList();
    if (filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات لتصديرها إلى PDF")));
      return;
    }

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.cairoRegular();
      final fontBold = await PdfGoogleFonts.cairoBold();

      double totalAcc = 0;
      double totalPaidAcc = 0;
      for (var item in filteredList) {
        totalAcc += double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
        totalPaidAcc += double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
      }
      double totalRemAcc = totalAcc - totalPaidAcc;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pw.PdfPageFormat.a4.landscape,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("تقرير حساب العملاء التفصيلي", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text("التاريخ: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pw.PdfColors.white, fontSize: 6.5),
                headerDecoration: const pw.BoxDecoration(color: pw.PdfColor.fromInt(0xFF1E3A8A)),
                cellStyle: const pw.TextStyle(fontSize: 6),
                cellAlignment: pw.Alignment.center,
                headers: [
                  'الباقي', 
                  'إجمالي الحساب', 
                  'التاريخ', 
                  'نوع الدفع', 
                  'المدفوعات', 
                  'سعر البيع', 
                  'المساحة', 
                  'العرض', 
                  'الطول', 
                  'العدد', 
                  'الخامة', 
                  'نوع العمل', 
                  'مكان العمل', 
                  'اسم العميل', 
                  'الكود', 
                  'رقم الطلب'
                ],
                data: filteredList.map((item) {
                  double itmTot = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
                  double itmPaid = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
                  double itmRem = itmTot - itmPaid;
                  String payType = item['method'] ?? item['paymentType'] ?? item['payment_type'] ?? '-';

                  return [
                    _formatMoney(itmRem),
                    _formatMoney(itmTot),
                    "${item['date'] ?? item['created_date'] ?? ''}",
                    payType,
                    _formatMoney(item['paid'] ?? item['paid_amount'] ?? '0'),
                    _formatMoney(item['sell'] ?? item['price'] ?? '0'),
                    "${item['area'] ?? '0.00'}",
                    "${item['width'] ?? ''}",
                    "${item['height'] ?? ''}",
                    "${item['qty'] ?? item['unit_count'] ?? '1'}",
                    "${item['material'] ?? item['material_type'] ?? ''}",
                    "${item['workType'] ?? item['work_type'] ?? ''}",
                    "${item['location'] ?? item['work_location'] ?? ''}",
                    "${item['client'] ?? item['client_name'] ?? ''}",
                    "${item['code'] ?? item['client_code'] ?? ''}",
                    "${item['order'] ?? item['order_num'] ?? ''}",
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(color: pw.PdfColor.fromInt(0xFF0F172A)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text("عدد البنود: ${filteredList.length}", style: const pw.TextStyle(color: pw.PdfColors.white, fontSize: 10)),
                    pw.Text("إجمالي الحساب: ${_formatMoney(totalAcc)} ج.م", style: const pw.TextStyle(color: pw.PdfColors.cyanAccent, fontSize: 10)),
                    pw.Text("إجمالي المدفوعات: ${_formatMoney(totalPaidAcc)} ج.م", style: const pw.TextStyle(color: pw.PdfColors.greenAccent, fontSize: 10)),
                    pw.Text("صافي الباقي: ${_formatMoney(totalRemAcc)} ج.م", style: const pw.TextStyle(color: pw.PdfColors.redAccent, fontSize: 10)),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text("معاينة تقرير الـ PDF", style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF1E3A8A),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: PdfPreview(
              build: (pw.PdfPageFormat format) async => pdf.save(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: true,
              allowSharing: true,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء تصدير PDF: $e")));
    }
  }

  void _showAddDialog() {
    _showItemDialog(isEdit: false);
  }

  void _editSelectedRow() {
    if (selectedRowIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تحديد صف من الجدول لتعديله")));
      return;
    }
    List<Map<String, dynamic>> filteredList = _getFilteredList();
    final itemToEdit = filteredList[selectedRowIndex!];
    int realIndex = AppData.savedOrders.indexOf(itemToEdit);
    _showItemDialog(isEdit: true, editIndex: realIndex, initialData: itemToEdit);
  }

  void _showItemDialog({required bool isEdit, int? editIndex, Map<String, dynamic>? initialData}) {
    final TextEditingController clientController = TextEditingController(text: initialData?['client'] ?? initialData?['client_name'] ?? '');
    final TextEditingController locationController = TextEditingController(text: initialData?['location'] ?? initialData?['work_location'] ?? '');
    final TextEditingController codeController = TextEditingController(text: initialData?['code'] ?? initialData?['client_code'] ?? '');
    final TextEditingController orderController = TextEditingController(text: initialData?['order'] ?? initialData?['order_num'] ?? '1');
    final TextEditingController phoneController = TextEditingController(text: initialData?['phone'] ?? '');
    final TextEditingController workTypeController = TextEditingController(text: initialData?['workType'] ?? initialData?['work_type'] ?? '');
    final TextEditingController materialController = TextEditingController(text: initialData?['material'] ?? initialData?['material_type'] ?? '');
    final TextEditingController qtyController = TextEditingController(text: initialData?['qty'] ?? initialData?['unit_count'] ?? '1');
    final TextEditingController heightController = TextEditingController(text: initialData?['height'] ?? '0');
    final TextEditingController widthController = TextEditingController(text: initialData?['width'] ?? '0');
    final TextEditingController areaController = TextEditingController(text: initialData?['area'] ?? '0.00');
    final TextEditingController sellController = TextEditingController(text: initialData?['sell'] ?? initialData?['price'] ?? '0');
    final TextEditingController costController = TextEditingController(text: initialData?['cost'] ?? initialData?['cost_price'] ?? '0');
    final TextEditingController paidController = TextEditingController(text: initialData?['paid'] ?? initialData?['paid_amount'] ?? '0');
    
    String initialPaymentType = initialData?['method'] ?? initialData?['paymentType'] ?? initialData?['payment_type'] ?? 'نقدي';
    final TextEditingController paymentTypeController = TextEditingController(text: initialPaymentType);

    final TextEditingController totalController = TextEditingController(text: initialData?['total'] ?? initialData?['total_amount'] ?? '0.00');
    final TextEditingController dateController = TextEditingController(text: initialData?['date'] ?? initialData?['created_date'] ?? '2026-09-14');
    
    List<String> uploadedImages = List<String>.from(initialData?['images'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void calculateValues() {
              double q = double.tryParse(qtyController.text) ?? 0;
              double h = double.tryParse(heightController.text) ?? 0;
              double w = double.tryParse(widthController.text) ?? 0;
              double s = double.tryParse(sellController.text) ?? 0;

              double area = (h > 0 && w > 0) ? (h * w * q) / 10000 : 0;
              double total = area > 0 ? area * s : q * s;

              setDialogState(() {
                areaController.text = area.toStringAsFixed(2);
                totalController.text = total.toStringAsFixed(2);
              });
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(isEdit ? "تعديل بيانات البند" : "إضافة بند جديد إلى السجلات"),
                content: SizedBox(
                  width: 600,
                  height: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Autocomplete<Map<String, String>>(
                          optionsBuilder: (v) {
                            if (v.text.isEmpty) return AppData.clients;
                            return AppData.clients.where((c) => c['name']!.contains(v.text));
                          },
                          displayStringForOption: (o) => o['name']!,
                          onSelected: (s) {
                            setDialogState(() {
                              clientController.text = s['name']!;
                              codeController.text = s['code'] ?? '';
                              phoneController.text = s['phone'] ?? '';
                            });
                          },
                          fieldViewBuilder: (c, controller, node, sub) {
                            if (controller.text.isEmpty && clientController.text.isNotEmpty) {
                              controller.text = clientController.text;
                            }
                            return TextField(
                              controller: controller,
                              focusNode: node,
                              decoration: const InputDecoration(labelText: "اسم العميل", border: OutlineInputBorder()),
                              onChanged: (val) => clientController.text = val,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(controller: locationController, decoration: const InputDecoration(labelText: "مكان العمل", border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: orderController, decoration: const InputDecoration(labelText: "رقم الطلب", border: OutlineInputBorder()))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: codeController, decoration: const InputDecoration(labelText: "الكود", border: OutlineInputBorder()))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: phoneController, decoration: const InputDecoration(labelText: "التليفون", border: OutlineInputBorder()))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(controller: workTypeController, decoration: const InputDecoration(labelText: "نوع العمل", border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                        Autocomplete<Map<String, String>>(
                          optionsBuilder: (v) {
                            if (v.text.isEmpty) return AppData.materials;
                            return AppData.materials.where((m) => m['name']!.contains(v.text));
                          },
                          displayStringForOption: (o) => o['name']!,
                          onSelected: (s) {
                            setDialogState(() {
                              materialController.text = s['name']!;
                              sellController.text = s['sell'] ?? '0';
                              costController.text = s['cost'] ?? '0';
                            });
                            calculateValues();
                          },
                          fieldViewBuilder: (c, controller, node, sub) {
                            if (controller.text.isEmpty && materialController.text.isNotEmpty) {
                              controller.text = materialController.text;
                            }
                            return TextField(
                              controller: controller,
                              focusNode: node,
                              decoration: const InputDecoration(labelText: "نوع الخامة", border: OutlineInputBorder()),
                              onChanged: (val) => materialController.text = val,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: qtyController, decoration: const InputDecoration(labelText: "العدد", border: OutlineInputBorder()), onChanged: (_) => calculateValues())),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: heightController, decoration: const InputDecoration(labelText: "الطول", border: OutlineInputBorder()), onChanged: (_) => calculateValues())),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: widthController, decoration: const InputDecoration(labelText: "العرض", border: OutlineInputBorder()), onChanged: (_) => calculateValues())),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: areaController, readOnly: true, decoration: const InputDecoration(labelText: "المساحة", border: OutlineInputBorder()))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: sellController, decoration: const InputDecoration(labelText: "سعر البيع", border: OutlineInputBorder()), onChanged: (_) => calculateValues())),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: costController, decoration: const InputDecoration(labelText: "التكلفة", border: OutlineInputBorder()))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: paidController, decoration: const InputDecoration(labelText: "المدفوعات", border: OutlineInputBorder()))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: paymentTypeController, decoration: const InputDecoration(labelText: "نوع الدفع", border: OutlineInputBorder()))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: totalController, readOnly: true, decoration: const InputDecoration(labelText: "إجمالي الحساب", border: OutlineInputBorder()))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(controller: dateController, decoration: const InputDecoration(labelText: "التاريخ (YYYY-MM-DD)", border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                        const Align(alignment: Alignment.centerRight, child: Text("الصور المرفقة:", style: TextStyle(fontWeight: FontWeight.bold))),
                        SizedBox(
                          height: 80,
                          child: uploadedImages.isEmpty
                              ? const Text("لا توجد صور مرفقة بعد", style: TextStyle(color: Colors.grey, fontSize: 12))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: uploadedImages.length,
                                  itemBuilder: (context, imgIndex) {
                                    return Container(
                                      margin: const EdgeInsets.all(4),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.image, size: 30, color: Colors.blue),
                                          const SizedBox(width: 5),
                                          Text("صورة ${imgIndex + 1}", style: const TextStyle(fontSize: 10)),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                            onPressed: () {
                                              setDialogState(() {
                                                uploadedImages.removeAt(imgIndex);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: true,
                              withData: true,
                            );
                            if (result != null) {
                              setDialogState(() {
                                for (var f in result.files) {
                                  if (f.bytes != null) {
                                    String base64Image = base64Encode(f.bytes!);
                                    String imageUrl = 'data:image/png;base64,$base64Image';
                                    uploadedImages.add(imageUrl);
                                  }
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const Text("إضافة صور جديدة"),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                  ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic> rowData = {
                        'order': orderController.text,
                        'code': codeController.text,
                        'client': clientController.text,
                        'location': locationController.text,
                        'workType': workTypeController.text,
                        'material': materialController.text,
                        'qty': qtyController.text,
                        'height': heightController.text,
                        'width': widthController.text,
                        'area': areaController.text,
                        'sell': sellController.text,
                        'cost': costController.text,
                        'paid': paidController.text,
                        'method': paymentTypeController.text,
                        'total': totalController.text,
                        'date': dateController.text,
                        'images': uploadedImages,
                      };

                      if (isEdit && editIndex != null) {
                        AppData.savedOrders[editIndex] = rowData;
                      } else {
                        AppData.savedOrders.add(rowData);
                      }

                      await AppData.saveData();
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? "تم تعديل البند بنجاح" : "تم إضافة البند بنجاح"))
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: Text(isEdit ? "حفظ التعديلات" : "حفظ البند"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredList() {
    List<Map<String, dynamic>> clientFilteredOrders = selectedClient == null || selectedClient!.isEmpty
        ? AppData.savedOrders
        : AppData.savedOrders.where((e) => (e['client'] ?? e['client_name'] ?? '').toString() == selectedClient).toList();

    return clientFilteredOrders.where((item) {
      String loc = (item['location'] ?? item['work_location'] ?? '').toString();
      bool matchesLocation = selectedLocation == null || selectedLocation!.isEmpty || loc == selectedLocation;
      
      String ord = (item['order'] ?? item['order_num'] ?? '').toString();
      bool matchesOrder = selectedOrderNum == null || selectedOrderNum!.isEmpty || ord == selectedOrderNum;
      
      String itemDate = (item['date'] ?? item['created_date'] ?? '').toString();
      bool matchesDateFrom = selectedDateFrom == null || selectedDateFrom!.isEmpty || itemDate.compareTo(selectedDateFrom!) >= 0;
      bool matchesDateTo = selectedDateTo == null || selectedDateTo!.isEmpty || itemDate.compareTo(selectedDateTo!) <= 0;

      return matchesLocation && matchesOrder && matchesDateFrom && matchesDateTo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<String> allClients = AppData.savedOrders.map((e) => (e['client'] ?? e['client_name'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> clientFilteredOrders = selectedClient == null || selectedClient!.isEmpty
        ? AppData.savedOrders
        : AppData.savedOrders.where((e) => (e['client'] ?? e['client_name'] ?? '').toString() == selectedClient).toList();

    List<String> locationsList = clientFilteredOrders.map((e) => (e['location'] ?? e['work_location'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> datesList = clientFilteredOrders.map((e) => (e['date'] ?? itemDateField(e)).toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> orderNumbers = clientFilteredOrders.map((e) => (e['order'] ?? e['order_num'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> filteredList = _getFilteredList();

    double totalAccount = 0;
    double totalPaid = 0;
    for (var item in filteredList) {
      totalAccount += double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
      totalPaid += double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
    }
    double totalRemaining = totalAccount - totalPaid;

    const double tableMinWidth = 1400.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text("حساب العملاء التفصيلي - المؤسسة التجارية", style: TextStyle(color: Colors.white, fontSize: 16)),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 240,
                              child: DropdownButtonFormField<String>(
                                value: selectedClient,
                                isExpanded: true,
                                hint: const Text("اسم العميل", style: TextStyle(fontSize: 11)),
                                items: [
                                  const DropdownMenuItem(value: "", child: Text("كل العملاء", style: TextStyle(fontSize: 11))),
                                  ...allClients.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 11)))),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    selectedClient = val;
                                    selectedLocation = null;
                                    selectedOrderNum = null;
                                  });
                                },
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 140,
                              child: DropdownButtonFormField<String>(
                                value: selectedDateFrom,
                                isExpanded: true,
                                hint: const Text("بداية التاريخ", style: TextStyle(fontSize: 11)),
                                items: [
                                  const DropdownMenuItem(value: "", child: Text("الكل", style: TextStyle(fontSize: 11))),
                                  ...datesList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 11)))),
                                ],
                                onChanged: (val) => setState(() => selectedDateFrom = val),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 130,
                              child: DropdownButtonFormField<String>(
                                value: selectedOrderNum,
                                isExpanded: true,
                                hint: const Text("رقم الطلب", style: TextStyle(fontSize: 11)),
                                items: [
                                  const DropdownMenuItem(value: "", child: Text("الكل", style: TextStyle(fontSize: 11))),
                                  ...orderNumbers.map((ord) => DropdownMenuItem(value: ord, child: Text(ord, style: TextStyle(fontSize: 11)))),
                                ],
                                onChanged: (val) => setState(() => selectedOrderNum = val),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 240,
                              child: DropdownButtonFormField<String>(
                                value: selectedLocation,
                                isExpanded: true,
                                hint: const Text("مكان العمل", style: TextStyle(fontSize: 11)),
                                items: [
                                  const DropdownMenuItem(value: "", child: Text("كل الأماكن", style: TextStyle(fontSize: 11))),
                                  ...locationsList.map((l) => DropdownMenuItem(value: l, child: Text(l, style: TextStyle(fontSize: 11)))),
                                ],
                                onChanged: (val) => setState(() => selectedLocation = val),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 140,
                              child: DropdownButtonFormField<String>(
                                value: selectedDateTo,
                                isExpanded: true,
                                hint: const Text("نهاية التاريخ", style: TextStyle(fontSize: 11)),
                                items: [
                                  const DropdownMenuItem(value: "", child: Text("الكل", style: TextStyle(fontSize: 11))),
                                  ...datesList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 11)))),
                                ],
                                onChanged: (val) => setState(() => selectedDateTo = val),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("إضافة بند"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: _editSelectedRow,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("تعديل بند"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: _deleteSelectedRow,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text("حذف بند"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (selectedRowIndex == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("حدد صفاً أولاً لعرض صوره")));
                              return;
                            }
                            _showImageDialog(filteredList[selectedRowIndex!]);
                          },
                          icon: const Icon(Icons.image, size: 16),
                          label: const Text("عرض الصورة"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: _exportToPdf,
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text("PDF"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
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
                        color: const Color(0xFF1E3A8A),
                        child: SingleChildScrollView(
                          controller: ScrollController(),
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: tableMinWidth),
                            child: Row(
                              children: const [
                                SizedBox(width: 60, child: Padding(padding: EdgeInsets.all(10.0), child: Text("رقم الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الكود", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(10.0), child: Text("اسم العميل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(10.0), child: Text("مكان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(10.0), child: Text("نوع العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الخامة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 45, child: Padding(padding: EdgeInsets.all(10.0), child: Text("العدد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 65, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الطول", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 65, child: Padding(padding: EdgeInsets.all(10.0), child: Text("العرض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 65, child: Padding(padding: EdgeInsets.all(10.0), child: Text("المساحة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 80, child: Padding(padding: EdgeInsets.all(10.0), child: Text("سعر البيع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 80, child: Padding(padding: EdgeInsets.all(10.0), child: Text("المدفوعات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 80, child: Padding(padding: EdgeInsets.all(10.0), child: Text("نوع الدفع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(10.0), child: Text("التاريخ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(10.0), child: Text("إجمالي الحساب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 80, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الباقي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 70, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الصورة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
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
                              constraints: const BoxConstraints(minWidth: tableMinWidth),
                              child: SizedBox(
                                width: tableMinWidth,
                                child: ListView.builder(
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredList[index];
                                    bool isSelected = selectedRowIndex == index;
                                    
                                    double itemTotal = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
                                    double itemPaid = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
                                    double itemRem = itemTotal - itemPaid;

                                    String payType = item['method'] ?? item['paymentType'] ?? item['payment_type'] ?? '-';
                                    List imgs = item['images'] ?? [];

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedRowIndex = index;
                                        });
                                      },
                                      child: Container(
                                        color: isSelected ? Colors.blue.shade100 : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 60, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['order'] ?? item['order_num'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['code'] ?? item['client_code'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['client'] ?? item['client_name'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['location'] ?? item['work_location'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['workType'] ?? item['work_type'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['material'] ?? item['material_type'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 45, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['qty'] ?? item['unit_count'] ?? '1'}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 65, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['height'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 65, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['width'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 65, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['area'] ?? '0.00'}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['sell'] ?? item['price'] ?? '0'), style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['paid'] ?? item['paid_amount'] ?? '0'), style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(payType, style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['date'] ?? item['created_date'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(itemTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)))),
                                            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(itemRem), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)))),
                                            SizedBox(
                                              width: 70,
                                              child: IconButton(
                                                icon: Icon(Icons.image, color: imgs.isNotEmpty ? Colors.blue : Colors.grey, size: 20),
                                                onPressed: () => _showImageDialog(item),
                                              ),
                                            ),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("عدد البنود: ${filteredList.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("إجمالي الحساب: ${_formatMoney(totalAccount)} ج.م", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("إجمالي المدفوعات: ${_formatMoney(totalPaid)} ج.م", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("صافي الباقي: ${_formatMoney(totalRemaining)} ج.م", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String itemDateField(Map e) => (e['date'] ?? e['created_date'] ?? '').toString();