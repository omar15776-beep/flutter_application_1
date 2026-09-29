import 'package:flutter/material.dart';
import 'app_data.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SearchOptionsScreen extends StatefulWidget {
  const SearchOptionsScreen({super.key});

  @override
  _SearchOptionsScreenState createState() => _SearchOptionsScreenState();
}

class _SearchOptionsScreenState extends State<SearchOptionsScreen> {
  String? selectedClient;
  String? selectedOrderNum;
  String? selectedLocation;
  String? selectedJob;
  String? selectedMaterial;
  
  String selectedReportType = "الكل (شامل)";
  final List<String> reportTypes = ["الكل (شامل)", "مقاسات", "مدفوعات", "ماليات", "الخامات"];

  int? selectedRowIndex;
  
  // استخدام اثنين ScrollController مستقلين لعدم حدوث تعارض مع Scrollbar
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // ربط الحركتين معاً برمجياً ليتطابق رأس الجدول مع البيانات بسلاسة تامة
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients && _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  // تنسيق الأرقام بفاصل الآلاف
  String _formatMoney(dynamic value) {
    double number = double.tryParse(value?.toString() ?? '0') ?? 0;
    String parts = number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
    List<String> segments = parts.split('.');
    RegExp regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    segments[0] = segments[0].replaceAllMapped(regExp, (Match m) => '${m[1]},');
    return segments.join('.');
  }

  // دالة جلب البيانات المطابقة بناءً على الشروط المحددة
  List<Map<String, dynamic>> _getFilteredData() {
    if (selectedClient == null || selectedClient!.trim().isEmpty) {
      return [];
    }

    String searchName = selectedClient!.trim();

    List<Map<String, dynamic>> results = [];

    for (var item in AppData.savedOrders) {
      String client = (item['client'] ?? item['client_name'] ?? '').toString().trim();
      if (client != searchName) continue;

      bool mLoc = true;
      bool mJob = true;
      bool mOrder = true;
      bool mMat = true;

      if (selectedOrderNum != null && selectedOrderNum!.isNotEmpty) {
        String ord = (item['order'] ?? item['order_num'] ?? '').toString();
        if (ord != selectedOrderNum) mOrder = false;
      }

      if (selectedLocation != null && selectedLocation!.isNotEmpty) {
        String loc = (item['location'] ?? item['work_location'] ?? '').toString();
        if (loc != selectedLocation) mLoc = false;
      }

      if (selectedJob != null && selectedJob!.isNotEmpty) {
        String job = (item['workType'] ?? item['work_type'] ?? '').toString();
        if (job != selectedJob) mJob = false;
      }

      if (selectedMaterial != null && selectedMaterial!.isNotEmpty) {
        String mat = (item['material'] ?? item['material_type'] ?? '').toString();
        if (mat != selectedMaterial) mMat = false;
      }

      if (mLoc && mJob && mOrder && mMat) {
        results.add(item);
      }
    }

    return results;
  }

  List<Map<String, dynamic>> _getFilteredDataList() {
    List<Map<String, dynamic>> raw = _getFilteredData();
    if (selectedReportType == "مقاسات") {
      return raw.where((item) {
        double l = double.tryParse((item['height'] ?? '0').toString()) ?? 0;
        double w = double.tryParse((item['width'] ?? '0').toString()) ?? 0;
        double a = double.tryParse((item['area'] ?? '0').toString()) ?? 0;
        return l > 0 || w > 0 || a > 0;
      }).toList();
    } else if (selectedReportType == "مدفوعات") {
      return raw.where((item) {
        double p = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
        return p > 0;
      }).toList();
    } else if (selectedReportType == "الخامات") {
      return raw.where((item) {
        String mat = (item['material'] ?? item['material_type'] ?? '').toString().trim();
        return mat.isNotEmpty;
      }).toList();
    }
    return raw;
  }

  // دالة تحديد الأعمدة حسب نوع التقرير
  List<String> _getCurrentHeaders() {
    if (selectedReportType == "مقاسات") {
      return ["رقم الطلب", "مكان العمل", "نوع العمل", "نوع الخامة", "عدد الوحدات", "الطول (سم)", "العرض (سم)", "المساحة (م²)"];
    } else if (selectedReportType == "مدفوعات") {
      return ["رقم الطلب", "مكان العمل", "نوع العمل", "نوع الخامة", "المبلغ المدفوع", "نوع الدفع", "التاريخ"];
    } else if (selectedReportType == "ماليات") {
      return ["رقم الطلب", "مكان العمل", "نوع العمل", "السعر", "إجمالي الحساب", "المدفوعات", "الباقي", "طريقة الدفع", "التاريخ"];
    } else if (selectedReportType == "الخامات") {
      return ["رقم الطلب", "مكان العمل", "نوع العمل", "نوع الخامة", "السعر"];
    } else {
      return ["رقم الطلب", "مكان العمل", "نوع العمل", "نوع الخامة", "العدد", "الطول", "العرض", "المساحة", "السعر", "الإجمالي", "المدفوع", "الباقي", "طريقة الدفع", "التاريخ"];
    }
  }

  double _getColumnWidth(String header) {
    if (header == "نوع الخامة") {
      return 340.0;
    }
    if (header == "مكان العمل" || header == "نوع العمل") {
      return 170.0;
    }
    if (header == "الطول (سم)" || header == "العرض (سم)" || header == "المساحة (م²)" || header == "عدد الوحدات" || header == "رقم الطلب") {
      return 130.0;
    }
    return 125.0;
  }

  // دالة تصدير تقرير الـ PDF (رأسية Portrait)
  void _exportSearchPdf() async {
    List<Map<String, dynamic>> data = _getFilteredDataList();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات مطابقة لتصديرها إلى PDF")));
      return;
    }

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.cairoRegular();
      final fontBold = await PdfGoogleFonts.cairoBold();

      List<String> pdfHeaders = [];
      List<List<String>> pdfRows = [];
      List<String> totalsRow = [];

      double sumTotal = 0;
      double sumPaid = 0;
      double sumArea = 0;
      int sumQty = 0;

      for (var item in data) {
        sumTotal += double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
        sumPaid += double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
        sumArea += double.tryParse((item['area'] ?? '0').toString()) ?? 0;
        sumQty += int.tryParse((item['qty'] ?? '1').toString()) ?? 1;
      }
      double sumRem = sumTotal - sumPaid;

      if (selectedReportType == "مقاسات") {
        pdfHeaders = ['المساحة (م²)', 'العرض', 'الطول', 'عدد الوحدات', 'نوع الخامة', 'نوع العمل', 'مكان العمل', 'رقم الطلب', 'م'];
        pdfRows = data.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return [
            "${item['area'] ?? '0.00'}",
            "${item['width'] ?? '0'}",
            "${item['height'] ?? '0'}",
            "${item['qty'] ?? '1'}",
            "${item['material'] ?? ''}",
            "${item['workType'] ?? ''}",
            "${item['location'] ?? ''}",
            "${item['order'] ?? ''}",
            "${idx + 1}",
          ];
        }).toList();
        totalsRow = ["${sumArea.toStringAsFixed(2)} متر²", "-", "-", "$sumQty", "-", "-", "-", "الإجمالي الكلي", ""];
      } else if (selectedReportType == "مدفوعات") {
        pdfHeaders = ['التاريخ', 'نوع الدفع', 'المبلغ المدفوع', 'نوع الخامة', 'نوع العمل', 'مكان العمل', 'رقم الطلب', 'م'];
        pdfRows = data.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          double paid = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
          String payType = item['method'] ?? item['paymentType'] ?? '-';
          return [
            "${item['date'] ?? item['created_date'] ?? ''}",
            payType,
            _formatMoney(paid),
            "${item['material'] ?? ''}",
            "${item['workType'] ?? ''}",
            "${item['location'] ?? ''}",
            "${item['order'] ?? ''}",
            "${idx + 1}",
          ];
        }).toList();
        totalsRow = ["-", "-", "${_formatMoney(sumPaid)} ج.م", "-", "-", "-", "الإجمالي الكلي", ""];
      } else if (selectedReportType == "ماليات") {
        pdfHeaders = ['التاريخ', 'طريقة الدفع', 'الباقي', 'المدفوعات', 'إجمالي الحساب', 'السعر', 'نوع العمل', 'مكان العمل', 'رقم الطلب', 'م'];
        pdfRows = data.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          double tot = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
          double paid = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
          double rem = tot - paid;
          return [
            "${item['date'] ?? item['created_date'] ?? ''}",
            "${item['method'] ?? item['paymentType'] ?? '-'}",
            _formatMoney(rem),
            _formatMoney(paid),
            _formatMoney(tot),
            _formatMoney(item['sell'] ?? item['price'] ?? '0'),
            "${item['workType'] ?? ''}",
            "${item['location'] ?? ''}",
            "${item['order'] ?? ''}",
            "${idx + 1}",
          ];
        }).toList();
        totalsRow = ["-", "-", "${_formatMoney(sumRem)} ج.م", "${_formatMoney(sumPaid)} ج.م", "${_formatMoney(sumTotal)} ج.م", "-", "-", "-", "الإجمالي الكلي", ""];
      } else if (selectedReportType == "الخامات") {
        pdfHeaders = ['السعر', 'نوع الخامة', 'نوع العمل', 'مكان العمل', 'رقم الطلب', 'م'];
        pdfRows = data.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return [
            _formatMoney(item['sell'] ?? item['price'] ?? '0'),
            "${item['material'] ?? ''}",
            "${item['workType'] ?? ''}",
            "${item['location'] ?? ''}",
            "${item['order'] ?? ''}",
            "${idx + 1}",
          ];
        }).toList();
        totalsRow = ["-", "-", "-", "-", "الإجمالي الكلي", ""];
      } else {
        pdfHeaders = ['التاريخ', 'طريقة الدفع', 'الباقي', 'المدفوع', 'الإجمالي', 'السعر', 'المساحة', 'الخامة', 'نوع العمل', 'مكان العمل', 'رقم الطلب', 'م'];
        pdfRows = data.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          double tot = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
          double paid = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
          double rem = tot - paid;
          return [
            "${item['date'] ?? item['created_date'] ?? ''}",
            "${item['method'] ?? item['paymentType'] ?? '-'}",
            _formatMoney(rem),
            _formatMoney(paid),
            _formatMoney(tot),
            _formatMoney(item['sell'] ?? item['price'] ?? '0'),
            "${item['area'] ?? '0.00'}",
            "${item['material'] ?? ''}",
            "${item['workType'] ?? ''}",
            "${item['location'] ?? ''}",
            "${item['order'] ?? ''}",
            "${idx + 1}",
          ];
        }).toList();
        totalsRow = ["-", "-", "${_formatMoney(sumRem)} ج.م", "${_formatMoney(sumPaid)} ج.م", "${_formatMoney(sumTotal)} ج.م", "-", (sumArea.toStringAsFixed(2)), "-", "-", "الإجمالي الكلي", ""];
      }

      pdfRows.add(totalsRow);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pw.PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(bottom: 15.0),
              padding: const pw.EdgeInsets.all(8.0),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: pw.PdfColors.grey700, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("تقرير البحث المتعدد ($selectedReportType)", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pw.PdfColor.fromInt(0xFF0F172A))),
                  pw.Text("العميل: $selectedClient  |  التاريخ: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 8, color: pw.PdfColors.grey700)),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pw.PdfColors.white, fontSize: 7),
                headerDecoration: const pw.BoxDecoration(color: pw.PdfColor.fromInt(0xFF0F172A)),
                cellStyle: const pw.TextStyle(fontSize: 6),
                cellAlignment: pw.Alignment.center,
                headers: pdfHeaders,
                data: pdfRows,
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
              title: const Text("معاينة تقرير البحث المتعدد PDF", style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF0F172A),
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

  @override
  Widget build(BuildContext context) {
    List<String> allClients = AppData.savedOrders
        .map((e) => (e['client'] ?? e['client_name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    List<Map<String, dynamic>> clientOrders = selectedClient == null || selectedClient!.isEmpty
        ? []
        : AppData.savedOrders.where((e) => (e['client'] ?? e['client_name'] ?? '').toString() == selectedClient).toList();

    List<String> orderNumbers = clientOrders.map((e) => (e['order'] ?? e['order_num'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> locationsList = clientOrders.map((e) => (e['location'] ?? e['work_location'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> jobsList = clientOrders.map((e) => (e['workType'] ?? e['work_type'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> materialsList = clientOrders.map((e) => (e['material'] ?? e['material_type'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> searchResults = _getFilteredDataList();

    double totalSum = 0;
    double paidSum = 0;
    double areaSum = 0;
    int unitsSum = 0;

    for (var item in searchResults) {
      double tot = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
      double paid = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
      double area = double.tryParse((item['area'] ?? '0').toString()) ?? 0;
      int qty = int.tryParse((item['qty'] ?? '1').toString()) ?? 1;

      totalSum += tot;
      paidSum += paid;
      areaSum += area;
      unitsSum += qty;
    }
    double remSum = totalSum - paidSum;

    List<String> currentHeaders = _getCurrentHeaders();
    double tableMinWidth = 0.0;
    for (var h in currentHeaders) {
      tableMinWidth += _getColumnWidth(h);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("البحث المتعدد والتقارير المخصصة", style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _exportSearchPdf,
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text("طباعة PDF"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
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
                                selectedOrderNum = null;
                                selectedLocation = null;
                                selectedJob = null;
                                selectedMaterial = null;
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
                                  labelText: "اسم العميل (إلزامي)",
                                  labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                style: const TextStyle(fontSize: 14),
                                onChanged: (val) {
                                  setState(() {
                                    selectedClient = val.isEmpty ? null : val;
                                    selectedOrderNum = null;
                                    selectedLocation = null;
                                    selectedJob = null;
                                    selectedMaterial = null;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedOrderNum,
                            isExpanded: true,
                            hint: const Text("رقم الطلب", style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem(value: "", child: Text("الكل", style: TextStyle(fontSize: 13))),
                              ...orderNumbers.map((ord) => DropdownMenuItem(value: ord, child: Text(ord, style: TextStyle(fontSize: 13)))),
                            ],
                            onChanged: (val) => setState(() => selectedOrderNum = val),
                            decoration: const InputDecoration(
                              labelText: "رقم الطلب",
                              labelStyle: TextStyle(fontSize: 13),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedLocation,
                            isExpanded: true,
                            hint: const Text("مكان العمل", style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem(value: "", child: Text("الكل", style: TextStyle(fontSize: 13))),
                              ...locationsList.map((loc) => DropdownMenuItem(value: loc, child: Text(loc, style: TextStyle(fontSize: 13)))),
                            ],
                            onChanged: (val) => setState(() => selectedLocation = val),
                            decoration: const InputDecoration(
                              labelText: "مكان العمل",
                              labelStyle: TextStyle(fontSize: 13),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedJob,
                            isExpanded: true,
                            hint: const Text("نوع العمل", style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem(value: "", child: Text("الكل", style: TextStyle(fontSize: 13))),
                              ...jobsList.map((job) => DropdownMenuItem(value: job, child: Text(job, style: TextStyle(fontSize: 13)))),
                            ],
                            onChanged: (val) => setState(() => selectedJob = val),
                            decoration: const InputDecoration(
                              labelText: "نوع العمل",
                              labelStyle: TextStyle(fontSize: 13),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedMaterial,
                            isExpanded: true,
                            hint: const Text("نوع الخامة", style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem(value: "", child: Text("الكل", style: TextStyle(fontSize: 13))),
                              ...materialsList.map((mat) => DropdownMenuItem(value: mat, child: Text(mat, style: TextStyle(fontSize: 13)))),
                            ],
                            onChanged: (val) => setState(() => selectedMaterial = val),
                            decoration: const InputDecoration(
                              labelText: "نوع الخامة",
                              labelStyle: TextStyle(fontSize: 13),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedReportType,
                            isExpanded: true,
                            items: reportTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (val) => setState(() => selectedReportType = val!),
                            decoration: const InputDecoration(
                              labelText: "نوع التقرير الذكي",
                              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.search, size: 20),
                          label: const Text("بحث وتصفية", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // جدول البيانات مع ربط رأس الجدول وجسم الجدول للحركة المتزامنة
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
                      _buildTableHeader(tableMinWidth),
                      Expanded(
                        child: Scrollbar(
                          controller: _bodyScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _bodyScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: tableMinWidth),
                              child: SizedBox(
                                width: tableMinWidth,
                                child: ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final item = searchResults[index];
                                    bool isSelected = selectedRowIndex == index;
                                    return _buildTableRow(item, index, isSelected, tableMinWidth);
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("عدد النتائج: ${searchResults.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (selectedReportType == "مقاسات") ...[
                      Text("إجمالي الوحدات: $unitsSum", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("إجمالي المساحة: ${areaSum.toStringAsFixed(2)} متر²", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ] else if (selectedReportType == "مدفوعات") ...[
                      Text("إجمالي المدفوعات: ${_formatMoney(paidSum)} ج.م", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ] else if (selectedReportType == "ماليات") ...[
                      Text("إجمالي الحساب: ${_formatMoney(totalSum)} ج.م", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("إجمالي المدفوعات: ${_formatMoney(paidSum)} ج.م", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("إجمالي الباقي: ${_formatMoney(remSum)} ج.م", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ] else if (selectedReportType == "الخامات") ...[
                      Text("إجمالي السعر: ${_formatMoney(totalSum)} ج.م", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ] else ...[
                      Text("إجمالي الحساب: ${_formatMoney(totalSum)} ج.م", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("المدفوع: ${_formatMoney(paidSum)} ج.م", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("الباقي: ${_formatMoney(remSum)} ج.م", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(double minWidth) {
    List<String> headers = _getCurrentHeaders();

    return Container(
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        controller: _headerScrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // يتم تحريكه برمجياً مع البيانات لمنع تعارض الـ ScrollController
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: Row(
            children: headers.map((h) => SizedBox(
              width: _getColumnWidth(h),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
                child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, int index, bool isSelected, double minWidth) {
    double tot = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
    double paid = double.tryParse((item['paid'] ?? item['paid_amount'] ?? '0').toString()) ?? 0;
    double rem = tot - paid;
    String payType = item['method'] ?? item['paymentType'] ?? '-';

    List<Widget> cells = [];
    List<String> headers = _getCurrentHeaders();

    if (selectedReportType == "مقاسات") {
      cells = [
        _cell("${item['order'] ?? ''}"),
        _cell("${item['location'] ?? ''}"),
        _cell("${item['workType'] ?? ''}"),
        _cell("${item['material'] ?? ''}"),
        _cell("${item['qty'] ?? '1'}"),
        _cell("${item['height'] ?? '0'}"),
        _cell("${item['width'] ?? '0'}"),
        _cell("${item['area'] ?? '0.00'} متر"),
      ];
    } else if (selectedReportType == "مدفوعات") {
      cells = [
        _cell("${item['order'] ?? ''}"),
        _cell("${item['location'] ?? ''}"),
        _cell("${item['workType'] ?? ''}"),
        _cell("${item['material'] ?? ''}"),
        _cell(_formatMoney(paid)),
        _cell(payType),
        _cell("${item['date'] ?? item['created_date'] ?? ''}"),
      ];
    } else if (selectedReportType == "ماليات") {
      cells = [
        _cell("${item['order'] ?? ''}"),
        _cell("${item['location'] ?? ''}"),
        _cell("${item['workType'] ?? ''}"),
        _cell(_formatMoney(item['sell'] ?? item['price'] ?? '0')),
        _cell(_formatMoney(tot)),
        _cell(_formatMoney(paid)),
        _cell(_formatMoney(rem)),
        _cell(payType),
        _cell("${item['date'] ?? item['created_date'] ?? ''}"),
      ];
    } else if (selectedReportType == "الخامات") {
      cells = [
        _cell("${item['order'] ?? ''}"),
        _cell("${item['location'] ?? ''}"),
        _cell("${item['workType'] ?? ''}"),
        _cell("${item['material'] ?? ''}"),
        _cell(_formatMoney(item['sell'] ?? item['price'] ?? '0')),
      ];
    } else {
      cells = [
        _cell("${item['order'] ?? ''}"),
        _cell("${item['location'] ?? ''}"),
        _cell("${item['workType'] ?? ''}"),
        _cell("${item['material'] ?? ''}"),
        _cell("${item['qty'] ?? '1'}"),
        _cell("${item['height'] ?? '0'}"),
        _cell("${item['width'] ?? '0'}"),
        _cell("${item['area'] ?? '0.00'}"),
        _cell(_formatMoney(item['sell'] ?? item['price'] ?? '0')),
        _cell(_formatMoney(tot)),
        _cell(_formatMoney(paid)),
        _cell(_formatMoney(rem)),
        _cell(payType),
        _cell("${item['date'] ?? item['created_date'] ?? ''}"),
      ];
    }

    return InkWell(
      onTap: () => setState(() => selectedRowIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: List.generate(cells.length, (i) => SizedBox(
            width: _getColumnWidth(headers[i]),
            child: cells[i],
          )),
        ),
      ),
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}