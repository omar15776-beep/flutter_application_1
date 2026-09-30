import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_data.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  _StatementScreenState createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  String? selectedClient;
  String? selectedLocation;
  String? selectedDateFrom;
  String? selectedDateTo;
  String? selectedOrderNum;
  
  String invoiceType = "مختصرة";
  int? selectedRowIndex;

  // --- إعدادات التحكم المتقدمة للـ PDF ---
  bool pdfShowLogo = true;
  bool pdfShowCompanyName = true;
  double pdfLogoWidth = 45.0;
  double pdfLogoHeight = 45.0;
  
  // نوع الخط المختار
  String selectedFontFamily = "Cairo";

  // 1. اسم المؤسسة
  double pdfCompanyNameFontSize = 16.0;
  Color pdfCompanyNameColor = const Color(0xFF1E293B);

  // 2. الشريط العلوي (بدون مكان العمل)
  String pdfHeaderQuoteText = "كشف حساب العميل:";
  String pdfHeaderDateText = "التاريخ:";
  double pdfHeaderBarFontSize = 10.0;
  Color pdfHeaderBarTextColor = const Color(0xFF0F172A);

  // 3. رؤوس الجدول
  double pdfHeaderTableFontSize = 8.0;
  Color pdfHeaderTableTextColor = Colors.white;
  Color pdfHeaderColor = const Color(0xFF1E3A8A);

  // 4. صفوف البيانات (الخط وارتفاع الصف)
  double pdfRowFontSize = 6.0;
  double pdfRowHeight = 20.0; 
  Color pdfRowTextColor = const Color(0xFF000000);

  // 5. شريط الإجماليات السفلي
  Color pdfTotalsBarColor = const Color(0xFF1E3A8A);
  double pdfTotalsFontSize = 10.0; 
  Color pdfTotalsTextColor = Colors.white;

  // 6. ملاحظات إضافية أسفل تقرير الـ PDF
  String pdfFooterNotes = "ملاحظات: يرجى مراجعة الحسابات في حال وجود أي استفسار.";
  double pdfFooterFontSize = 8.0;

  // 7. مقاسات عرض الأعمدة للـ PDF (11 عموداً بعد استبعاد رقم الطلب)
  List<double> pdfColWidths = [30.0, 85.0, 85.0, 90.0, 45.0, 60.0, 60.0, 70.0, 65.0, 65.0, 110.0];

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController(); // متحكم منفصل لرؤوس الجدول لمنع التعارض

  @override
  void initState() {
    super.initState();
    // مزامنة حركة رؤوس الجدول مع جدول البيانات بسلاسة تامة
    _horizontalScrollController.addListener(() {
      if (_headerScrollController.hasClients && _headerScrollController.offset != _horizontalScrollController.offset) {
        _headerScrollController.jumpTo(_horizontalScrollController.offset);
      }
    });
    _headerScrollController.addListener(() {
      if (_horizontalScrollController.hasClients && _horizontalScrollController.offset != _headerScrollController.offset) {
        _horizontalScrollController.jumpTo(_headerScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
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

  String _formatRoundedMoney(dynamic value) {
    double number = double.tryParse(value?.toString() ?? '0') ?? 0;
    int roundedNumber = (number / 100).round() * 100;
    String parts = roundedNumber.toString();
    RegExp regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    parts = parts.replaceAllMapped(regExp, (Match m) => '${m[1]},');
    return parts;
  }

  void _onClientSelected(String? clientName) {
    setState(() {
      selectedClient = clientName;
      selectedLocation = null;
      selectedOrderNum = null;
      selectedDateFrom = null;
      selectedDateTo = null;
    });
  }

  List<Map<String, dynamic>> _getFilteredData() {
    if (selectedClient == null || selectedClient!.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> clientFiltered = AppData.savedOrders.where((item) {
      String client = (item['client'] ?? item['client_name'] ?? '').toString();
      return client.contains(selectedClient!);
    }).toList();

    return clientFiltered.where((item) {
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

  Map<String, double> _calculateGroupTotals(List<Map<String, dynamic>> rows) {
    Map<String, double> groupTotals = {};
    for (var item in rows) {
      String client = (item['client'] ?? item['client_name'] ?? '').toString().trim();
      String location = (item['location'] ?? item['work_location'] ?? '').toString().trim();
      String workType = (item['workType'] ?? item['work_type'] ?? '').toString().trim();
      String key = "$client|$location|$workType";

      double itemTotal = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
      groupTotals[key] = (groupTotals[key] ?? 0) + itemTotal;
    }
    return groupTotals;
  }

  List<Map<String, dynamic>> _processSummaryRows(List<Map<String, dynamic>> rawRows) {
    if (invoiceType == "تفصيلية") {
      return rawRows;
    }

    List<Map<String, dynamic>> processed = [];
    
    for (int i = 0; i < rawRows.length; i++) {
      var current = Map<String, dynamic>.from(rawRows[i]);
      
      double area = double.tryParse((current['area'] ?? '0').toString()) ?? 0;
      String client = (current['client'] ?? current['client_name'] ?? '').toString().trim();
      String location = (current['location'] ?? current['work_location'] ?? '').toString().trim();
      String workType = (current['workType'] ?? current['work_type'] ?? '').toString().trim();
      String materialFull = (current['material'] ?? current['material_type'] ?? '').toString().trim();

      if (area > 0) {
        double accumulatedArea = area;
        double sellPrice = double.tryParse((current['sell'] ?? current['price'] ?? '0').toString()) ?? 0;

        int j = i + 1;
        while (j < rawRows.length) {
          var next = rawRows[j];
          double nextArea = double.tryParse((next['area'] ?? '0').toString()) ?? 0;
          if (nextArea <= 0) break;

          String nClient = (next['client'] ?? next['client_name'] ?? '').toString().trim();
          String nLocation = (next['location'] ?? next['work_location'] ?? '').toString().trim();
          String nWorkType = (next['workType'] ?? next['work_type'] ?? '').toString().trim();
          String nMaterial = (next['material'] ?? next['material_type'] ?? '').toString().trim();
          double nSellPrice = double.tryParse((next['sell'] ?? next['price'] ?? '0').toString()) ?? 0;

          if (nClient == client && nLocation == location && nWorkType == workType && nMaterial == materialFull && nSellPrice == sellPrice) {
            accumulatedArea += nextArea;
            j++;
          } else {
            break;
          }
        }

        double newTotal = accumulatedArea * sellPrice;

        current['area'] = accumulatedArea.toStringAsFixed(2);
        current['total'] = newTotal.toStringAsFixed(2);
        current['total_amount'] = current['total'];

        processed.add(current);
        i = j - 1;
        continue;
      }

      String firstWord = materialFull.isNotEmpty ? materialFull.split(' ').first : materialFull;
      double accumulatedTotal = double.tryParse((current['total'] ?? current['total_amount'] ?? '0').toString()) ?? 0;
      
      int j = i + 1;
      while (j < rawRows.length) {
        var next = rawRows[j];
        double nextArea = double.tryParse((next['area'] ?? '0').toString()) ?? 0;
        if (nextArea > 0) break;

        String nClient = (next['client'] ?? next['client_name'] ?? '').toString().trim();
        String nLocation = (next['location'] ?? next['work_location'] ?? '').toString().trim();
        String nWorkType = (next['workType'] ?? next['work_type'] ?? '').toString().trim();
        String nMatFull = (next['material'] ?? next['material_type'] ?? '').toString().trim();
        String nFirstWord = nMatFull.isNotEmpty ? nMatFull.split(' ').first : nMatFull;

        if (nClient == client && nLocation == location && nWorkType == workType && nFirstWord == firstWord) {
          accumulatedTotal += double.tryParse((next['total'] ?? next['total_amount'] ?? '0').toString()) ?? 0;
          j++;
        } else {
          break;
        }
      }

      current['material'] = firstWord;
      current['qty'] = "1";
      current['total'] = accumulatedTotal.toStringAsFixed(2);
      current['total_amount'] = current['total'];
      current['sell'] = current['total'];
      current['price'] = current['total'];

      processed.add(current);
      i = j - 1;
    }

    return processed;
  }

  void _showPdfSettingsDialog() {
    final TextEditingController quoteTextController = TextEditingController(text: pdfHeaderQuoteText);
    final TextEditingController dateTextController = TextEditingController(text: pdfHeaderDateText);
    final TextEditingController footerNotesController = TextEditingController(text: pdfFooterNotes);
    final List<TextEditingController> colWidthControllers = pdfColWidths.map((w) => TextEditingController(text: w.toString())).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text("🖨️ إعدادات وتخصيص طباعة الـ PDF الشاملة"),
                content: SizedBox(
                  width: 600,
                  height: 650,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🔤 نوع الخط المستخدم:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        DropdownButtonFormField<String>(
                          initialValue: selectedFontFamily,
                          items: const [
                            DropdownMenuItem(value: "Cairo", child: Text("خط كايرو (Cairo)")),
                            DropdownMenuItem(value: "Tajawal", child: Text("خط تجوال (Tajawal)")),
                            DropdownMenuItem(value: "Amiri", child: Text("خط أميري (Amiri - كلاسيكي)")),
                            DropdownMenuItem(value: "MarkaziText", child: Text("خط مركزي (Markazi)")),
                          ],
                          onChanged: (val) => setDialogState(() => selectedFontFamily = val!),
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                        ),
                        const Divider(),

                        const Text("1️⃣ إعدادات اسم المؤسسة وألوان الخط:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                        SwitchListTile(
                          title: const Text("إظهار اسم المؤسسة في المنتصف"),
                          value: pdfShowCompanyName,
                          onChanged: (val) => setDialogState(() => pdfShowCompanyName = val),
                        ),
                        if (pdfShowCompanyName) ...[
                          Text("حجم خط اسم المؤسسة: ${pdfCompanyNameFontSize.toInt()} px"),
                          Slider(value: pdfCompanyNameFontSize, min: 10, max: 35, divisions: 25, onChanged: (val) => setDialogState(() => pdfCompanyNameFontSize = val)),
                          DropdownButtonFormField<Color>(
                            initialValue: pdfCompanyNameColor,
                            items: const [
                              DropdownMenuItem(value: Color(0xFF1E293B), child: Text("رمادي غامق")),
                              DropdownMenuItem(value: Color(0xFF1E3A8A), child: Text("أزرق غامق")),
                              DropdownMenuItem(value: Color(0xFF581C87), child: Text("بنفسجي")),
                              DropdownMenuItem(value: Color(0xFF991B1B), child: Text("أحمر داكن")),
                            ],
                            onChanged: (val) => setDialogState(() => pdfCompanyNameColor = val!),
                            decoration: const InputDecoration(labelText: "لون خط اسم المؤسسة", border: OutlineInputBorder()),
                          ),
                        ],
                        SwitchListTile(
                          title: const Text("إظهار شعار المؤسسة (اللوجو)"),
                          value: pdfShowLogo,
                          onChanged: (val) => setDialogState(() => pdfShowLogo = val),
                        ),
                        if (pdfShowLogo) ...[
                          Text("عرض اللوجو: ${pdfLogoWidth.toInt()} px"),
                          Slider(value: pdfLogoWidth, min: 20, max: 100, divisions: 16, onChanged: (val) => setDialogState(() => pdfLogoWidth = val)),
                          Text("ارتفاع اللوجو: ${pdfLogoHeight.toInt()} px"),
                          Slider(value: pdfLogoHeight, min: 20, max: 100, divisions: 16, onChanged: (val) => setDialogState(() => pdfLogoHeight = val)),
                        ],
                        const Divider(),

                        const Text("2️⃣ الشريط العلوي (النصوص وألوان الخطوط):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        TextField(controller: quoteTextController, onChanged: (v) => pdfHeaderQuoteText = v, decoration: const InputDecoration(labelText: "نص كشف الحساب")),
                        TextField(controller: dateTextController, onChanged: (v) => pdfHeaderDateText = v, decoration: const InputDecoration(labelText: "نص التاريخ")),
                        const SizedBox(height: 8),
                        Text("حجم خط الشريط العلوي: ${pdfHeaderBarFontSize.toInt()} px"),
                        Slider(value: pdfHeaderBarFontSize, min: 6, max: 16, divisions: 10, onChanged: (val) => setDialogState(() => pdfHeaderBarFontSize = val)),
                        DropdownButtonFormField<Color>(
                          initialValue: pdfHeaderBarTextColor,
                          items: const [
                            DropdownMenuItem(value: Color(0xFF0F172A), child: Text("أسود/رمادي داكن")),
                            DropdownMenuItem(value: Color(0xFF1E3A8A), child: Text("أزرق غامق")),
                            DropdownMenuItem(value: Color(0xFF581C87), child: Text("بنفسجي")),
                            DropdownMenuItem(value: Color(0xFF15803D), child: Text("أخضر داكن")),
                          ],
                          onChanged: (val) => setDialogState(() => pdfHeaderBarTextColor = val!),
                          decoration: const InputDecoration(labelText: "لون خط الشريط العلوي", border: OutlineInputBorder()),
                        ),

                        const Divider(),
                        const Text("3️⃣ رؤوس الجدول والبيانات وألوان الخطوط:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text("حجم خط رؤوس الجدول: ${pdfHeaderTableFontSize.toInt()} px"),
                        Slider(value: pdfHeaderTableFontSize, min: 6, max: 14, divisions: 8, onChanged: (val) => setDialogState(() => pdfHeaderTableFontSize = val)),

                        Text("حجم خط صفوف البيانات: ${pdfRowFontSize.toInt()} px"),
                        Slider(value: pdfRowFontSize, min: 4, max: 12, divisions: 8, onChanged: (val) => setDialogState(() => pdfRowFontSize = val)),

                        Text("ارتفاع صفوف الجدول: ${pdfRowHeight.toInt()} px"),
                        Slider(value: pdfRowHeight, min: 12, max: 50, divisions: 38, onChanged: (val) => setDialogState(() => pdfRowHeight = val)),

                        DropdownButtonFormField<Color>(
                          initialValue: pdfRowTextColor,
                          items: const [
                            DropdownMenuItem(value: Color(0xFF000000), child: Text("أسود صريح")),
                            DropdownMenuItem(value: Color(0xFF334155), child: Text("رمادي داكن")),
                            DropdownMenuItem(value: Color(0xFF1E3A8A), child: Text("أزرق غامق")),
                          ],
                          onChanged: (val) => setDialogState(() => pdfRowTextColor = val!),
                          decoration: const InputDecoration(labelText: "لون خطوط صفوف البيانات", border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Color>(
                          initialValue: pdfHeaderColor,
                          items: const [
                            DropdownMenuItem(value: Color(0xFF1E3A8A), child: Text("أزرق غامق")),
                            DropdownMenuItem(value: Color(0xFF334155), child: Text("رمادي داكن")),
                            DropdownMenuItem(value: Color(0xFF581C87), child: Text("بنفسجي")),
                            DropdownMenuItem(value: Color(0xFF065F46), child: Text("أخضر داكن")),
                          ],
                          onChanged: (val) => setDialogState(() => pdfHeaderColor = val!),
                          decoration: const InputDecoration(labelText: "لون خلفية رؤوس الجدول", border: OutlineInputBorder()),
                        ),

                        const Divider(),
                        const Text("4️⃣ مقاسات وعرض أعمدة الجدول للـ PDF (11 عموداً):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ...List.generate(11, (i) {
                          List<String> colNames = [
                            'م', 'مكان العمل', 'بيان العمل', 'نوع الخامة', 
                            'العدد', 'المساحة', 'السعر', 'الحساب', 'المدفوعات', 'نوع الدفع', 'التاريخ'
                          ];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(colNames[i], style: const TextStyle(fontSize: 12))),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: colWidthControllers[i],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                                    onChanged: (v) {
                                      pdfColWidths[i] = double.tryParse(v) ?? pdfColWidths[i];
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(),
                        const Text("5️⃣ شريط الإجماليات السفلي (الحجم والألوان):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text("حجم خط شريط الإجمالي: ${pdfTotalsFontSize.toInt()} px"),
                        Slider(value: pdfTotalsFontSize, min: 8, max: 24, divisions: 16, onChanged: (val) => setDialogState(() => pdfTotalsFontSize = val)),
                        
                        DropdownButtonFormField<Color>(
                          initialValue: pdfTotalsTextColor,
                          items: const [
                            DropdownMenuItem(value: Colors.white, child: Text("أبيض")),
                            DropdownMenuItem(value: Color(0xFFFEF08A), child: Text("أصفر فاتح")),
                          ],
                          onChanged: (val) => setDialogState(() => pdfTotalsTextColor = val!),
                          decoration: const InputDecoration(labelText: "لون خط شريط الإجمالي", border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Color>(
                          initialValue: pdfTotalsBarColor,
                          items: const [
                            DropdownMenuItem(value: Color(0xFF1E3A8A), child: Text("أزرق غامق")),
                            DropdownMenuItem(value: Color(0xFF334155), child: Text("رمادي داكن")),
                            DropdownMenuItem(value: Color(0xFF581C87), child: Text("بنفسجي")),
                            DropdownMenuItem(value: Color(0xFF065F46), child: Text("أخضر داكن")),
                          ],
                          onChanged: (val) => setDialogState(() => pdfTotalsBarColor = val!),
                          decoration: const InputDecoration(labelText: "لون خلفية شريط الإجمالي", border: OutlineInputBorder()),
                        ),

                        const Divider(),
                        const Text("6️⃣ ملاحظات وشروط إضافية (تحت الإجمالي):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        TextField(
                          controller: footerNotesController,
                          maxLines: 3,
                          onChanged: (v) => pdfFooterNotes = v,
                          decoration: const InputDecoration(
                            labelText: "نص الملاحظات أو الشروط",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("حجم خط الملاحظات: ${pdfFooterFontSize.toInt()} px"),
                        Slider(value: pdfFooterFontSize, min: 6, max: 14, divisions: 8, onChanged: (val) => setDialogState(() => pdfFooterFontSize = val)),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                      _exportStatementPdf();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("حفظ وتصدير PDF"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _exportStatementPdf() async {
    List<Map<String, dynamic>> rawRows = _getFilteredData();
    if (rawRows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات معروضة لتصديرها إلى PDF")));
      return;
    }

    List<Map<String, dynamic>> rows = _processSummaryRows(rawRows);

    try {
      final pdf = pw.Document();
      
      pw.Font font;
      pw.Font fontBold;
      
      if (selectedFontFamily == "Tajawal") {
        font = await PdfGoogleFonts.tajawalRegular();
        fontBold = await PdfGoogleFonts.tajawalBold();
      } else if (selectedFontFamily == "Amiri") {
        font = await PdfGoogleFonts.amiriRegular();
        fontBold = await PdfGoogleFonts.amiriBold();
      } else if (selectedFontFamily == "MarkaziText") {
        font = await PdfGoogleFonts.markaziTextRegular();
        fontBold = await PdfGoogleFonts.markaziTextBold();
      } else {
        font = await PdfGoogleFonts.cairoRegular();
        fontBold = await PdfGoogleFonts.cairoBold();
      }

      double totalAcc = 0;
      double totalPaid = 0;
      for (var item in rows) {
        totalAcc += double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
        totalPaid += double.tryParse((item['paid'] ?? item['paid_amount'] ?? item['payment'] ?? '0').toString()) ?? 0;
      }
      double remaining = totalAcc - totalPaid;

      Map<String, double> groupTotals = _calculateGroupTotals(rows);
      Map<String, bool> groupFirstSeen = {};

      pw.ImageProvider? logoImage;
      if (pdfShowLogo && AppData.companyLogoPath != null && AppData.companyLogoPath!.isNotEmpty) {
        try {
          if (AppData.companyLogoPath!.startsWith('data:image')) {
            final bytes = base64Decode(AppData.companyLogoPath!.split(',').last);
            logoImage = pw.MemoryImage(bytes);
          } else if (File(AppData.companyLogoPath!).existsSync()) {
            final bytes = File(AppData.companyLogoPath!).readAsBytesSync();
            logoImage = pw.MemoryImage(bytes);
          }
        } catch (_) {}
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pw.PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) {
            return [
              if ((pdfShowCompanyName && AppData.companyName.trim().isNotEmpty && !AppData.companyName.contains("المؤسسة التجارية")) || (pdfShowLogo && logoImage != null))
                pw.Center(
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (pdfShowCompanyName && AppData.companyName.trim().isNotEmpty && !AppData.companyName.contains("المؤسسة التجارية"))
                        pw.Text(
                          AppData.companyName,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: pdfCompanyNameFontSize,
                            fontWeight: pw.FontWeight.bold,
                            color: pw.PdfColor.fromInt(pdfCompanyNameColor.toARGB32()),
                          ),
                        ),
                      if (pdfShowCompanyName && AppData.companyName.trim().isNotEmpty && !AppData.companyName.contains("المؤسسة التجارية") && pdfShowLogo && logoImage != null)
                        pw.SizedBox(width: 12),
                      if (pdfShowLogo && logoImage != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          decoration: const pw.BoxDecoration(color: pw.PdfColors.white),
                          child: pw.Image(logoImage, width: pdfLogoWidth, height: pdfLogoHeight, fit: pw.BoxFit.contain),
                        ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 15),

              // الشريط العلوي (بدون مكان العمل)
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("$pdfHeaderQuoteText ${selectedClient ?? ''}", style: pw.TextStyle(font: fontBold, fontSize: pdfHeaderBarFontSize, fontWeight: pw.FontWeight.bold, color: pw.PdfColor.fromInt(pdfHeaderBarTextColor.toARGB32()))),
                    pw.Text("$pdfHeaderDateText ${DateTime.now().toString().split(' ')[0]}", style: pw.TextStyle(font: font, fontSize: pdfHeaderBarFontSize, color: pw.PdfColor.fromInt(pdfHeaderBarTextColor.toARGB32()))),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // جدول الـ PDF (بدون عمود رقم الطلب)
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold, color: pw.PdfColors.white, fontSize: pdfHeaderTableFontSize),
                headerDecoration: pw.BoxDecoration(color: pw.PdfColor.fromInt(pdfHeaderColor.toARGB32())),
                cellStyle: pw.TextStyle(font: font, fontSize: pdfRowFontSize, color: pw.PdfColor.fromInt(pdfRowTextColor.toARGB32())),
                cellAlignment: pw.Alignment.center,
                cellHeight: pdfRowHeight,
                columnWidths: {
                  0: pw.FixedColumnWidth(pdfColWidths[10]),
                  1: pw.FixedColumnWidth(pdfColWidths[9]),
                  2: pw.FixedColumnWidth(pdfColWidths[8]),
                  3: pw.FixedColumnWidth(pdfColWidths[7]),
                  4: pw.FixedColumnWidth(pdfColWidths[6]),
                  5: pw.FixedColumnWidth(pdfColWidths[5]),
                  6: pw.FixedColumnWidth(pdfColWidths[4]),
                  7: pw.FixedColumnWidth(pdfColWidths[3]),
                  8: pw.FixedColumnWidth(pdfColWidths[2]),
                  9: pw.FixedColumnWidth(pdfColWidths[1]),
                  10: pw.FixedColumnWidth(pdfColWidths[0]),
                },
                headers: ['التاريخ', 'نوع الدفع', 'المدفوعات', 'الحساب', 'السعر', 'المساحة', 'العدد', 'نوع الخامة', 'بيان العمل', 'مكان العمل', 'م'],
                data: rows.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var item = entry.value;

                  String client = (item['client'] ?? item['client_name'] ?? '').toString().trim();
                  String location = (item['location'] ?? item['work_location'] ?? '').toString().trim();
                  String workType = (item['workType'] ?? item['work_type'] ?? '').toString().trim();
                  String key = "$client|$location|$workType";

                  String groupWorkTotalStr = "";
                  if (!(groupFirstSeen[key] ?? false)) {
                    groupFirstSeen[key] = true;
                    double sumVal = groupTotals[key] ?? 0;
                    groupWorkTotalStr = "${_formatRoundedMoney(sumVal)}   $workType";
                  }

                  double areaVal = double.tryParse((item['area'] ?? '0').toString()) ?? 0;
                  String areaStr = areaVal > 0 ? "${_formatMoney(areaVal)} متر" : "0.00";

                  String payTypeVal = item['method'] ?? item['payment_type'] ?? item['pay_type'] ?? item['paymentType'] ?? '-';
                  String paidVal = _formatMoney(item['paid'] ?? item['paid_amount'] ?? item['payment'] ?? '0');

                  return [
                    "${item['date'] ?? item['created_date'] ?? ''}",
                    payTypeVal,
                    paidVal,
                    _formatMoney(item['total'] ?? item['total_amount'] ?? '0'),
                    _formatMoney(item['sell'] ?? item['price'] ?? '0'),
                    areaStr,
                    "${item['qty'] ?? item['unit_count'] ?? '1'}",
                    "${item['material'] ?? item['material_type'] ?? ''}",
                    workType,
                    location,
                    "${idx + 1}",
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 15),

              // شريط الإجماليات السفلي
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(color: pw.PdfColor.fromInt(pdfTotalsBarColor.toARGB32())),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text("إجمالي الباقي: ${_formatRoundedMoney(remaining)} ج.م", style: pw.TextStyle(font: fontBold, color: pw.PdfColor.fromInt(pdfTotalsTextColor.toARGB32()), fontSize: pdfTotalsFontSize)),
                    pw.Text("إجمالي المدفوعات: ${_formatMoney(totalPaid)} ج.م", style: pw.TextStyle(font: fontBold, color: pw.PdfColor.fromInt(pdfTotalsTextColor.toARGB32()), fontSize: pdfTotalsFontSize)),
                    pw.Text("إجمالي الحساب: ${_formatRoundedMoney(totalAcc)} ج.م", style: pw.TextStyle(font: fontBold, color: pw.PdfColor.fromInt(pdfTotalsTextColor.toARGB32()), fontSize: pdfTotalsFontSize)),
                  ],
                ),
              ),

              // ملاحظات إضافية أسفل شريط الإجمالي في الـ PDF
              // ملاحظات إضافية أسفل شريط الإجمالي في الـ PDF
              if (pdfFooterNotes.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: pw.PdfColors.grey400, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    pdfFooterNotes,
                    style: pw.TextStyle(font: font, fontSize: pdfFooterFontSize, color: pw.PdfColors.grey800),
                  ),
                ),
              ],
            ];
          },
        ),
      );

      String dynamicFileName = "كشف حساب العميل \({selectedClient ?? 'عام'} -\){DateTime.now().toString().split(' ')[0]}.pdf";

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text("معاينة كشف الحساب PDF", style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF1E3A8A),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: PdfPreview(
              build: (pw.PdfPageFormat format) async => pdf.save(),
              pdfFileName: dynamicFileName,
              canChangeOrientation: false,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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

    List<Map<String, dynamic>> clientRows = selectedClient == null || selectedClient!.isEmpty
        ? []
        : AppData.savedOrders.where((e) => (e['client'] ?? e['client_name'] ?? '').toString().contains(selectedClient!)).toList();

    List<String> locationsList = clientRows.map((e) => (e['location'] ?? e['work_location'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> datesList = clientRows.map((e) => (e['date'] ?? e['created_date'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();
    List<String> orderNumbers = clientRows.map((e) => (e['order'] ?? e['order_num'] ?? '').toString()).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> rawFilteredList = _getFilteredData();
    List<Map<String, dynamic>> filteredList = _processSummaryRows(rawFilteredList);

    Map<String, double> groupTotals = _calculateGroupTotals(filteredList);
    Map<String, bool> groupFirstSeen = {};

    double totalAccount = 0;
    double totalPaid = 0;
    for (var item in rawFilteredList) {
      totalAccount += double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
      totalPaid += double.tryParse((item['paid'] ?? item['paid_amount'] ?? item['payment'] ?? '0').toString()) ?? 0;
    }
    double totalRemaining = totalAccount - totalPaid;

    const double tableMinWidth = 1750.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text("شاشة الفاتورة وكشف الحساب التفصيلي - المؤسسة التجارية", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          // 📱 تفعيل التمرير العمودي الشامل للصفحة لتناسب الموبايل والشاشات الصغيرة
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: Autocomplete<String>(
                                        optionsBuilder: (TextEditingValue textEditingValue) {
                                          if (textEditingValue.text.isEmpty) {
                                            return allClients;
                                          }
                                          return allClients.where((c) => c.contains(textEditingValue.text));
                                        },
                                        onSelected: (String selection) {
                                          _onClientSelected(selection);
                                        },
                                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                          if (controller.text.isEmpty && selectedClient != null) {
                                            controller.text = selectedClient!;
                                          }
                                          return TextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: const InputDecoration(
                                              hintText: "اسم العميل",
                                              hintStyle: TextStyle(fontSize: 11),
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
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedDateFrom,
                                        isExpanded: true,
                                        hint: const Text("تاريخ البداية", style: TextStyle(fontSize: 11)),
                                        items: datesList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) => setState(() => selectedDateFrom = val),
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedOrderNum,
                                        isExpanded: true,
                                        hint: const Text("رقم الطلب", style: TextStyle(fontSize: 11)),
                                        items: orderNumbers.map((ord) => DropdownMenuItem(value: ord, child: Text(ord, style: TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) => setState(() => selectedOrderNum = val),
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedLocation,
                                        isExpanded: true,
                                        hint: const Text("مكان العمل", style: TextStyle(fontSize: 11)),
                                        items: locationsList.map((l) => DropdownMenuItem(value: l, child: Text(l, style: TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) => setState(() => selectedLocation = val),
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedDateTo,
                                        isExpanded: true,
                                        hint: const Text("تاريخ النهاية", style: TextStyle(fontSize: 11)),
                                        items: datesList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) => setState(() => selectedDateTo = val),
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("نوع العرض:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("فاتورة مختصرة", style: TextStyle(fontSize: 11)),
                                  Radio<String>(
                                    value: "مختصرة",
                                    groupValue: invoiceType,
                                    onChanged: (val) => setState(() => invoiceType = val!),
                                  ),
                                  const Text("كشف تفصيلي", style: TextStyle(fontSize: 11)),
                                  Radio<String>(
                                    value: "تفصيلية",
                                    groupValue: invoiceType,
                                    onChanged: (val) => setState(() => invoiceType = val!),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Wrap(
                          spacing: 8,
                          direction: Axis.vertical,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text("جلب البيانات"),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: _showPdfSettingsDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    minimumSize: const Size(36, 36),
                                  ),
                                  child: const Icon(Icons.settings, size: 16),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  onPressed: _exportStatementPdf,
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  label: const Text("طباعة PDF"),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          // رؤوس الجدول مع ربط _headerScrollController المنفصل والمزامن
                          Container(
                            color: const Color(0xFF1E3A8A),
                            child: SingleChildScrollView(
                              controller: _headerScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: tableMinWidth),
                                child: Row(
                                  children: const [
                                    SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(12.0), child: Text("م", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(12.0), child: Text("رقم الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(12.0), child: Text("مكان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(12.0), child: Text("بيان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 130, child: Padding(padding: EdgeInsets.all(12.0), child: Text("نوع الخامة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 70, child: Padding(padding: EdgeInsets.all(12.0), child: Text("العدد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(12.0), child: Text("المساحة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(12.0), child: Text("السعر", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 110, child: Padding(padding: EdgeInsets.all(12.0), child: Text("الحساب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 100, child: Padding(padding: EdgeInsets.all(12.0), child: Text("المدفوعات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 100, child: Padding(padding: EdgeInsets.all(12.0), child: Text("نوع الدفع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 110, child: Padding(padding: EdgeInsets.all(12.0), child: Text("التاريخ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 230, child: Padding(padding: EdgeInsets.all(12.0), child: Text("إجمالي حساب العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
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

                                        String client = (item['client'] ?? item['client_name'] ?? '').toString().trim();
                                        String location = (item['location'] ?? item['work_location'] ?? '').toString().trim();
                                        String workType = (item['workType'] ?? item['work_type'] ?? '').toString().trim();
                                        String key = "$client|$location|$workType";

                                        String groupWorkTotalStr = "";
                                        if (!(groupFirstSeen[key] ?? false)) {
                                          groupFirstSeen[key] = true;
                                          double sumVal = groupTotals[key] ?? 0;
                                          groupWorkTotalStr = "${_formatRoundedMoney(sumVal)}   $workType";
                                        }

                                        double areaVal = double.tryParse((item['area'] ?? '0').toString()) ?? 0;
                                        String areaStr = areaVal > 0 ? "${_formatMoney(areaVal)} متر" : "0.00";

                                        String payTypeVal = item['method'] ?? item['payment_type'] ?? item['pay_type'] ?? item['paymentType'] ?? '-';
                                        String paidVal = _formatMoney(item['paid'] ?? item['paid_amount'] ?? item['payment'] ?? '0');

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
                                                SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${index + 1}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['order'] ?? item['order_num'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(location, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(workType, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 130, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['material'] ?? item['material_type'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 70, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['qty'] ?? item['unit_count'] ?? '1'}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(areaStr, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['sell'] ?? item['price'] ?? '0'), style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 110, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(item['total'] ?? item['total_amount'] ?? '0'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)))),
                                                SizedBox(width: 100, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(paidVal, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 100, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(payTypeVal, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 110, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['date'] ?? item['created_date'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 230, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(groupWorkTotalStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 11)))),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryCard("إجمالي الباقي:", "${_formatRoundedMoney(totalRemaining)} ج.م", Colors.red),
                        _buildSummaryCard("إجمالي المدفوعات:", "${_formatMoney(totalPaid)} ج.م", Colors.green.shade700),
                        _buildSummaryCard("إجمالي الحساب:", "${_formatRoundedMoney(totalAccount)} ج.م", Colors.blue.shade700),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}