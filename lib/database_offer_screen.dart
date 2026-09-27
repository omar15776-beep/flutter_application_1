import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_data.dart';

class DatabaseOfferScreen extends StatefulWidget {
  const DatabaseOfferScreen({super.key});

  @override
  _DatabaseOfferScreenState createState() => _DatabaseOfferScreenState();
}

class _DatabaseOfferScreenState extends State<DatabaseOfferScreen> {
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

  // دالة لتنسيق الأرقام المالية مع علامة الآلاف (مثال: 3,103 و 1,600)
  String _formatMoney(dynamic value) {
    double number = double.tryParse(value?.toString() ?? '0') ?? 0;
    String parts = number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
    List<String> segments = parts.split('.');
    RegExp regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    segments[0] = segments[0].replaceAllMapped(regExp, (Match m) => '${m[1]},');
    return segments.join('.');
  }

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
                title: Text("صور السجل (رقم العرض: ${item['order'] ?? item['order_num'] ?? ''})"),
                content: SizedBox(
                  width: 500,
                  height: 400,
                  child: images.isEmpty
                  ? const Center(child: Text("لا توجد صور مرفقة لهذا السجل"))
                  : ListView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        String imgPath = images[index].toString();
                        bool isFileExists = File(imgPath).existsSync();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.image, color: Colors.purple, size: 30),
                            title: Text(imgPath.split(Platform.pathSeparator).last, style: const TextStyle(fontSize: 13)),
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
                                              Text(imgPath.split(Platform.pathSeparator).last, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: Center(
                                                  child: isFileExists
                                                      ? InteractiveViewer(
                                                          panEnabled: true,
                                                          boundaryMargin: const EdgeInsets.all(20),
                                                          minScale: 0.5,
                                                          maxScale: 4.0,
                                                          child: Image.file(File(imgPath), fit: BoxFit.contain),
                                                        )
                                                      : const Text("مسار الصورة غير متوفر على الجهاز حالياً", style: TextStyle(color: Colors.grey)),
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
                                      const SnackBar(content: Text("تم حذف الصورة بنجاح من السجل"))
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
      AppData.savedQuotations.removeAt(selectedRowIndex!);
      selectedRowIndex = null;
    });
    await AppData.saveData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف السجل بنجاح")));
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
      for (var item in filteredList) {
        totalAcc += double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
      }

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
                    pw.Text("تقرير قاعدة بيانات عروض الأسعار", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text("التاريخ: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pw.PdfColors.white, fontSize: 6.5),
                headerDecoration: const pw.BoxDecoration(color: pw.PdfColor.fromInt(0xFF581C87)),
                cellStyle: const pw.TextStyle(fontSize: 6),
                cellAlignment: pw.Alignment.center,
                headers: [
                  'إجمالي العرض',
                  'التاريخ', 
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
                  'رقم العرض'
                ],
                data: filteredList.map((item) {
                  double itmTot = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;

                  return [
                    _formatMoney(itmTot),
                    "${item['date'] ?? item['created_date'] ?? ''}",
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
                decoration: const pw.BoxDecoration(color: pw.PdfColor.fromInt(0xFF4C1D95)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text("عدد السجلات: ${filteredList.length}", style: const pw.TextStyle(color: pw.PdfColors.white, fontSize: 10)),
                    pw.Text("إجمالي الحساب: ${_formatMoney(totalAcc)} ج.م", style: const pw.TextStyle(color: pw.PdfColors.cyanAccent, fontSize: 10)),
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
              backgroundColor: const Color(0xFF581C87),
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

  List<Map<String, dynamic>> _getFilteredList() {
    List<Map<String, dynamic>> clientFilteredOrders = selectedClient == null || selectedClient!.isEmpty
        ? AppData.savedQuotations
        : AppData.savedQuotations.where((e) => (e['client'] ?? e['client_name'] ?? '').toString().contains(selectedClient!)).toList();

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
    List<String> allClients = AppData.savedQuotations.map((e) => (e['client'] ?? e['client_name'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> clientFilteredOrders = selectedClient == null || selectedClient!.isEmpty
        ? AppData.savedQuotations
        : AppData.savedQuotations.where((e) => (e['client'] ?? e['client_name'] ?? '').toString().contains(selectedClient!)).toList();

    List<String> locationsList = clientFilteredOrders.map((e) => (e['location'] ?? e['work_location'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> datesList = clientFilteredOrders.map((e) => (e['date'] ?? e['created_date'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> orderNumbers = clientFilteredOrders.map((e) => (e['order'] ?? e['order_num'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> filteredList = _getFilteredList();

    double totalAccount = 0;
    for (var item in filteredList) {
      totalAccount += double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF581C87),
        title: const Text("قاعدة بيانات عروض الأسعار - المؤسسة التجارية", style: TextStyle(color: Colors.white, fontSize: 16)),
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
                            // حقل اسم العميل يدعم البحث بالكتابة والفلترة
                            SizedBox(
                              width: 240,
                              child: Autocomplete<String>(
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return allClients;
                                  }
                                  return allClients.where((c) => c.contains(textEditingValue.text));
                                },
                                onSelected: (String selection) {
                                  setState(() {
                                    selectedClient = selection;
                                    selectedLocation = null;
                                    selectedOrderNum = null;
                                  });
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  if (controller.text.isEmpty && selectedClient != null) {
                                    controller.text = selectedClient!;
                                  }
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: "اسم العميل",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedClient = val.isEmpty ? null : val;
                                        selectedLocation = null;
                                        selectedOrderNum = null;
                                      });
                                    },
                                  );
                                },
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
                                hint: const Text("رقم العرض", style: TextStyle(fontSize: 11)),
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
                          onPressed: _deleteSelectedRow,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text("حذف السجل المحدد"),
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
                          label: const Text("عرض الصور"),
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
              // جدول عرض البيانات برأس أعمدة ثابت تماماً
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
                      // رأس الأعمدة الثابت
                      Container(
                        color: const Color(0xFF581C87),
                        child: SingleChildScrollView(
                          controller: ScrollController(),
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1350),
                            child: Row(
                              children: const [
                                SizedBox(width: 70, child: Padding(padding: EdgeInsets.all(10.0), child: Text("رقم العرض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 55, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الكود", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 140, child: Padding(padding: EdgeInsets.all(10.0), child: Text("اسم العميل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 110, child: Padding(padding: EdgeInsets.all(10.0), child: Text("مكان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 135, child: Padding(padding: EdgeInsets.all(10.0), child: Text("نوع العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 170, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الخامة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(10.0), child: Text("العدد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الطول", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 60, child: Padding(padding: EdgeInsets.all(10.0), child: Text("العرض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 70, child: Padding(padding: EdgeInsets.all(10.0), child: Text("المساحة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 85, child: Padding(padding: EdgeInsets.all(10.0), child: Text("سعر البيع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(10.0), child: Text("التاريخ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 100, child: Padding(padding: EdgeInsets.all(10.0), child: Text("إجمالي العرض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 75, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الصورة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // محتوى البيانات القابل للتمرير
                      Expanded(
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 1350),
                              child: SizedBox(
                                width: 1350,
                                child: ListView.builder(
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredList[index];
                                    bool isSelected = selectedRowIndex == index;
                                    
                                    double itemTotal = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
                                    List imgs = item['images'] ?? [];

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedRowIndex = index;
                                        });
                                      },
                                      child: Container(
                                        color: isSelected ? Colors.purple.shade100 : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 70, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['order'] ?? item['order_num'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 55, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['code'] ?? item['client_code'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 140, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['client'] ?? item['client_name'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 110, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['location'] ?? item['work_location'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 135, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['workType'] ?? item['work_type'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 170, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['material'] ?? item['material_type'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['qty'] ?? item['unit_count'] ?? '1'}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['height'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 60, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['width'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 70, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['area'] ?? '0.00'}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 85, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['sell'] ?? item['price'] ?? '0'), style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['date'] ?? item['created_date'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                            SizedBox(width: 100, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(itemTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 11)))),
                                            SizedBox(
                                              width: 75,
                                              child: IconButton(
                                                icon: Icon(Icons.image, color: imgs.isNotEmpty ? Colors.purple : Colors.grey, size: 20),
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
                  color: const Color(0xFF4C1D95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("عدد السجلات: ${filteredList.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("إجمالي الحساب: ${_formatMoney(totalAccount)} ج.م", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
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