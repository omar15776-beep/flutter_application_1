import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_data.dart';
import 'main_dashboard.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController _clientSearchController = TextEditingController();
  final TextEditingController _orderSearchController = TextEditingController();
  final TextEditingController _locationSearchController = TextEditingController();
  final TextEditingController _dateSearchController = TextEditingController();

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();
  
  String archiveTypeFilter = "الكل";

  @override
  void initState() {
    super.initState();
    _horizontalScrollController.addListener(() {
      if (_headerScrollController.hasClients && _headerScrollController.offset != _horizontalScrollController.offset) {
        _headerScrollController.jumpTo(_horizontalScrollController.offset);
      }
    });
    _headerScrollController.addListener(() {
      if (_horizontalScrollController.hasClients && _horizontalScrollController.offset != _headerScrollController.offset) {
        _horizontalScrollController.jumpTo(_horizontalScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    _orderSearchController.dispose();
    _locationSearchController.dispose();
    _dateSearchController.dispose();
    _horizontalScrollController.dispose();
    _headerScrollController.dispose();
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

  List<Map<String, dynamic>> _getFilteredData() {
    List<Map<String, dynamic>> allArchivedItems = [];
    
    if (archiveTypeFilter == "الكل" || archiveTypeFilter == "الطلبات") {
      for (var item in AppData.savedOrders) {
        var mapItem = Map<String, dynamic>.from(item);
        mapItem['archive_source'] = 'طلب';
        allArchivedItems.add(mapItem);
      }
    }
    
    if (archiveTypeFilter == "الكل" || archiveTypeFilter == "عروض الأسعار") {
      for (var item in AppData.savedQuotations) {
        var mapItem = Map<String, dynamic>.from(item);
        mapItem['archive_source'] = 'عرض سعر';
        allArchivedItems.add(mapItem);
      }
    }

    String clientQuery = _clientSearchController.text.trim().toLowerCase();
    String orderQuery = _orderSearchController.text.trim().toLowerCase();
    String locationQuery = _locationSearchController.text.trim().toLowerCase();
    String dateQuery = _dateSearchController.text.trim().toLowerCase();

    return allArchivedItems.where((item) {
      String client = (item['client'] ?? item['client_name'] ?? '').toString().toLowerCase();
      String location = (item['location'] ?? item['work_location'] ?? '').toString().toLowerCase();
      String orderNum = (item['order'] ?? item['order_num'] ?? '').toString().toLowerCase();
      String dateVal = (item['date'] ?? item['created_date'] ?? '').toString().toLowerCase();
      
      bool matchesClient = clientQuery.isEmpty || client.contains(clientQuery);
      bool matchesOrder = orderQuery.isEmpty || orderNum.contains(orderQuery);
      bool matchesLocation = locationQuery.isEmpty || location.contains(locationQuery);
      bool matchesDate = dateQuery.isEmpty || dateVal.contains(dateQuery);

      return matchesClient && matchesOrder && matchesLocation && matchesDate;
    }).toList();
  }

  // دالة ذكية ومحصنة لعرض الصورة سواء كانت Base64 أو مسار ملف
  Widget _buildSafeImageWidget(String imgData) {
    try {
      if (imgData.contains('base64,')) {
        final base64String = imgData.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.contain);
      } else if (imgData.startsWith('/9j/') || imgData.startsWith('iVBORw0KGgo')) {
        return Image.memory(base64Decode(imgData), fit: BoxFit.contain);
      } else if (File(imgData).existsSync()) {
        return Image.file(File(imgData), fit: BoxFit.contain);
      } else {
        // محاولة أخيرة باعتبار النص بالكامل Base64
        return Image.memory(base64Decode(imgData), fit: BoxFit.contain);
      }
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("تعذر عرض الصورة\nالتفاصيل: $e", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 11)),
        ),
      );
    }
  }

  // دالة لحفظ وتنزيل الصورة بكفاءة عالية
  Future<void> _saveImageToDevice(String imgData, String clientName, int index) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ الصورة',
        fileName: 'صورة_أرشيف_${clientName}_${index + 1}.png',
      );

      if (outputPath != null) {
        Uint8List bytes;
        if (imgData.contains('base64,')) {
          bytes = base64Decode(imgData.split(',').last);
        } else if (imgData.startsWith('/9j/') || imgData.startsWith('iVBORw0KGgo')) {
          bytes = base64Decode(imgData);
        } else if (File(imgData).existsSync()) {
          bytes = await File(imgData).readAsBytes();
        } else {
          bytes = base64Decode(imgData);
        }
        await File(outputPath).writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم حفظ الصورة بنجاح"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء الحفظ: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _exportArchivePdf(List<Map<String, dynamic>> filteredList) async {
    if (filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات مطابقة لتصديرها إلى PDF")));
      return;
    }

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.cairoRegular();
      final fontBold = await PdfGoogleFonts.cairoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pw.PdfPageFormat.a4.landscape,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  "${AppData.companyName} - تقرير الأرشيف الشامل",
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pw.PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: pw.PdfColor.fromInt(0xFF0F172A)),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellAlignment: pw.Alignment.center,
                headers: ['التاريخ', 'نوع الدفع', 'المدفوعات', 'الحساب', 'السعر', 'المساحة', 'العرض', 'الطول', 'العدد', 'نوع الخامة', 'بيان العمل', 'مكان العمل', 'رقم الطلب', 'اسم العميل', 'النوع', 'م'],
                data: filteredList.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var item = entry.value;

                  String widthVal = '${item['width'] ?? item['w'] ?? item['عرض'] ?? '0'}';
                  String heightVal = '${item['height'] ?? item['h'] ?? item['length'] ?? item['len'] ?? item['طول'] ?? '0'}';

                  return [
                    "${item['date'] ?? item['created_date'] ?? '-'}",
                    item['method'] ?? item['payment_type'] ?? item['pay_type'] ?? '-',
                    _formatMoney(item['paid'] ?? item['paid_amount'] ?? item['payment'] ?? '0'),
                    _formatMoney(item['total'] ?? item['total_amount'] ?? '0'),
                    _formatMoney(item['sell'] ?? item['price'] ?? '0'),
                    '${item['area'] ?? '0'}',
                    widthVal,
                    heightVal,
                    '${item['qty'] ?? item['unit_count'] ?? '1'}',
                    item['material'] ?? item['material_type'] ?? '-',
                    item['workType'] ?? item['work_type'] ?? '-',
                    item['location'] ?? item['work_location'] ?? '-',
                    item['order'] ?? item['order_num'] ?? '-',
                    item['client'] ?? item['client_name'] ?? '-',
                    item['archive_source'] ?? '-',
                    "${idx + 1}",
                  ];
                }).toList(),
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
              title: const Text("معاينة طباعة الأرشيف PDF", style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF0F172A),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: PdfPreview(
              build: (pw.PdfPageFormat format) async => pdf.save(),
              pdfFileName: "تقرير الأرشيف الشامل - ${DateTime.now().toString().split(' ')[0]}.pdf",
              canChangeOrientation: false,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء تصدير PDF: $e")));
    }
  }
  Future _exportArchiveDataJson(List filteredList) async {
    if (filteredList.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات لتصديرها")));
      return;
    }

    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ ملف الأرشيف',
        fileName: 'Archive_Backup_${DateTime.now().toString().split(' ')[0]}.json',
      );

      if (outputPath != null) {
        String jsonEncoded = jsonEncode(filteredList);
        await File(outputPath).writeAsString(jsonEncoded);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم تصدير ملف الأرشيف بنجاح"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء التصدير: $e"), backgroundColor: Colors.red),
      );
    }
  }
  // دالة استيراد الأرشيف من ملف JSON وحفظه في التطبيق
  Future _importArchiveDataJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        
        List decodedData = jsonDecode(jsonString);
        
        // تحويل البيانات وإضافتها إلى الذاكرة المؤقتة أو الأرشيف
        setState(() {
          for (var item in decodedData) {
            if (item is Map) {
              // تحويل آمن لـ Map
              
              final convertedItem = Map.from(item).map((k, v) => MapEntry(k.toString(), v));
              if (convertedItem['archive_source'] == 'طلب') {
                AppData.savedOrders.add(convertedItem);
              } else {
                AppData.savedQuotations.add(convertedItem);
              }
            }
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم استيراد بيانات الأرشيف بنجاح"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء الاستيراد: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = _getFilteredData();
    const double tableMinWidth = 1850.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("استعراض الأرشيف كجدول بيانات شامل", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
         IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            tooltip: "استيراد ملف أرشيف (Restore)",
            onPressed: () => _importArchiveDataJson(),
          ), 
          // زر تصدير الأرشيف الجديد
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: "تصدير ملف الأرشيف (Backup)",
            onPressed: () => _exportArchiveDataJson(filteredList),
          ),
          // زر طباعة التقرير PDF الحالي
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: "طباعة التقرير PDF",
            onPressed: () => _exportArchivePdf(filteredList),
          ),
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
          child: Column(
            children: [
              // قسم فلاتر البحث
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _clientSearchController,
                            onChanged: (val) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: "البحث الأساسي: اسم العميل",
                              hintText: "اكتب اسم العميل...",
                              prefixIcon: Icon(Icons.person, color: Colors.blue),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _orderSearchController,
                            onChanged: (val) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: "رقم الطلب (فرعي)",
                              hintText: "رقم الطلب...",
                              prefixIcon: Icon(Icons.receipt, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: archiveTypeFilter,
                            items: const [
                              DropdownMenuItem(value: "الكل", child: Text("كل الأرشيف")),
                              DropdownMenuItem(value: "الطلبات", child: Text("الطلبات فقط")),
                              DropdownMenuItem(value: "عروض الأسعار", child: Text("عروض الأسعار فقط")),
                            ],
                            onChanged: (val) => setState(() => archiveTypeFilter = val!),
                            decoration: const InputDecoration(labelText: "نوع الأرشيف", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _locationSearchController,
                            onChanged: (val) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: "مكان العمل (فرعي)",
                              hintText: "مكان العمل...",
                              prefixIcon: Icon(Icons.location_on, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _dateSearchController,
                            onChanged: (val) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: "التاريخ (فرعي)",
                              hintText: "YYYY-MM-DD...",
                              prefixIcon: Icon(Icons.calendar_today, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton.icon(
                          onPressed: () => _exportArchivePdf(filteredList),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text("طباعة PDF"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // جدول البيانات المؤرشفة
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
                        color: const Color(0xFF0F172A),
                        child: SingleChildScrollView(
                          controller: _headerScrollController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: tableMinWidth),
                            child: Row(
                              children: const [
                                SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(12.0), child: Text("م", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(12.0), child: Text("نوع السجل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 110, child: Padding(padding: EdgeInsets.all(12.0), child: Text("اسم العميل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 100, child: Padding(padding: EdgeInsets.all(12.0), child: Text("رقم الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(12.0), child: Text("مكان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(12.0), child: Text("بيان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 130, child: Padding(padding: EdgeInsets.all(12.0), child: Text("نوع الخامة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 70, child: Padding(padding: EdgeInsets.all(12.0), child: Text("العدد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 80, child: Padding(padding: EdgeInsets.all(12.0), child: Text("الطول", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 80, child: Padding(padding: EdgeInsets.all(12.0), child: Text("العرض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(12.0), child: Text("المساحة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(12.0), child: Text("السعر", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 110, child: Padding(padding: EdgeInsets.all(12.0), child: Text("الحساب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 100, child: Padding(padding: EdgeInsets.all(12.0), child: Text("المدفوعات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 100, child: Padding(padding: EdgeInsets.all(12.0), child: Text("نوع الدفع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 110, child: Padding(padding: EdgeInsets.all(12.0), child: Text("التاريخ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(12.0), child: Text("الصور", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
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
                                child: filteredList.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: filteredList.length,
                                        itemBuilder: (context, index) {
                                          final item = filteredList[index];
                                          bool isOrder = item['archive_source'] == 'طلب';
                                          
                                          String client = item['client'] ?? item['client_name'] ?? '-';
                                          String orderNum = item['order'] ?? item['order_num'] ?? '-';
                                          String location = item['location'] ?? item['work_location'] ?? '-';
                                          String workType = item['workType'] ?? item['work_type'] ?? '-';
                                          String material = item['material'] ?? item['material_type'] ?? '-';
                                          String qty = '${item['qty'] ?? item['unit_count'] ?? '1'}';
                                          
                                          String widthVal = '${item['width'] ?? item['w'] ?? item['عرض'] ?? '0'}';
                                          String heightVal = '${item['height'] ?? item['h'] ?? item['length'] ?? item['len'] ?? item['طول'] ?? '0'}';
                                          
                                          String area = '${item['area'] ?? '0'}';
                                          String price = _formatMoney(item['sell'] ?? item['price'] ?? '0');
                                          String total = _formatMoney(item['total'] ?? item['total_amount'] ?? '0');
                                          String paid = _formatMoney(item['paid'] ?? item['paid_amount'] ?? item['payment'] ?? '0');
                                          String payType = item['method'] ?? item['payment_type'] ?? item['pay_type'] ?? '-';
                                          String date = item['date'] ?? item['created_date'] ?? '-';
                                          
                                          List<dynamic> imagesList = [];
                                          if (item['images'] is List) {
                                            imagesList = item['images'];
                                          } else if (item['img_list'] is List) {
                                            imagesList = item['img_list'];
                                          } else {
                                            String? singleImg = item['image'] ?? item['image_path'] ?? item['img'] ?? item['photo'] ?? item['picture'] ?? item['path'];
                                            if (singleImg != null && singleImg.isNotEmpty) {
                                              imagesList = [singleImg];
                                            }
                                          }

                                          return Container(
                                            color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${index + 1}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(item['archive_source'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOrder ? Colors.blue.shade700 : Colors.purple.shade700)))),
                                                SizedBox(width: 110, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(client, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                                                SizedBox(width: 100, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(orderNum, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(location, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(workType, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 130, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(material, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 70, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(qty, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 80, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(heightVal, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 80, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(widthVal, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(area, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(price, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 110, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(total, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)))),
                                                SizedBox(width: 100, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(paid, style: const TextStyle(fontSize: 11, color: Colors.green)))),
                                                SizedBox(width: 100, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(payType, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 110, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(date, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(
                                                  width: 120,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(4.0),
                                                    child: imagesList.isNotEmpty
                                                        ? ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.blue.shade700,
                                                              foregroundColor: Colors.white,
                                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                                              minimumSize: const Size(100, 28),
                                                            ),
                                                            onPressed: () {
                                                              showDialog(
                                                                context: context,
                                                                builder: (context) => AlertDialog(
                                                                  title: Text("صور البند للعميل: $client (${imagesList.length})"),
                                                                  content: SizedBox(
                                                                    width: 450,
                                                                    height: 400,
                                                                    child: ListView.builder(
                                                                      itemCount: imagesList.length,
                                                                      itemBuilder: (context, imgIdx) {
                                                                        String imgData = imagesList[imgIdx].toString();
                                                                        return Container(
                                                                          margin: const EdgeInsets.only(bottom: 15),
                                                                          padding: const EdgeInsets.all(8),
                                                                          decoration: BoxDecoration(
                                                                            border: Border.all(color: Colors.grey.shade300),
                                                                            borderRadius: BorderRadius.circular(6),
                                                                          ),
                                                                          child: Column(
                                                                            children: [
                                                                              SizedBox(
                                                                                height: 220,
                                                                                child: _buildSafeImageWidget(imgData),
                                                                              ),
                                                                              const SizedBox(height: 8),
                                                                              ElevatedButton.icon(
                                                                                onPressed: () => _saveImageToDevice(imgData, client, imgIdx),
                                                                                icon: const Icon(Icons.save_alt, size: 16),
                                                                                label: const Text("حفظ الصورة"),
                                                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(context),
                                                                      child: const Text("إغلاق"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                            child: Text("صور (${imagesList.length})", style: const TextStyle(fontSize: 11)),
                                                          )
                                                        : const Text("لا توجد", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Text(
                                          "لا توجد بيانات مطابقة في الأرشيف",
                                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                                        ),
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