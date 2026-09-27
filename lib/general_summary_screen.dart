import 'package:flutter/material.dart';
import 'app_data.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GeneralSummaryScreen extends StatefulWidget {
  const GeneralSummaryScreen({super.key});

  @override
  _GeneralSummaryScreenState createState() => _GeneralSummaryScreenState();
}

class _GeneralSummaryScreenState extends State<GeneralSummaryScreen> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
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

  // دالة تجميع بيانات العملاء من قاعدة البيانات العامة
  List<Map<String, dynamic>> _getSummarizedClients() {
    Map<String, double> dictTotal = {};
    Map<String, double> dictPaid = {};

    for (var order in AppData.savedOrders) {
      String clientName = (order['client'] ?? order['client_name'] ?? '').toString().trim();
      if (clientName.isEmpty) continue;

      double orderTotal = double.tryParse((order['total'] ?? order['total_amount'] ?? '0').toString()) ?? 0;
      double orderPaid = double.tryParse((order['paid'] ?? order['paid_amount'] ?? '0').toString()) ?? 0;

      dictTotal[clientName] = (dictTotal[clientName] ?? 0) + orderTotal;
      dictPaid[clientName] = (dictPaid[clientName] ?? 0) + orderPaid;
    }

    List<Map<String, dynamic>> summaryList = [];
    dictTotal.forEach((client, total) {
      double paid = dictPaid[client] ?? 0;
      double remaining = total - paid;
      summaryList.add({
        'client': client,
        'total': total,
        'paid': paid,
        'remaining': remaining,
      });
    });

    // فرز البيانات تنازلياً بناءً على عمود "الباقي" من الأكبر إلى الأصغر
    summaryList.sort((a, b) => (b['remaining'] as double).compareTo(a['remaining'] as double));

    return summaryList;
  }

  // دالة تصدير ومعاينة تقرير PDF للملخص العام
  void _exportGeneralSummaryPdf() async {
    List<Map<String, dynamic>> summaryData = _getSummarizedClients();
    if (summaryData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات لتصديرها إلى PDF")));
      return;
    }

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.cairoRegular();
      final fontBold = await PdfGoogleFonts.cairoBold();

      double grandTotal = 0;
      double grandPaid = 0;
      double grandRemaining = 0;

      for (var item in summaryData) {
        grandTotal += item['total'] as double;
        grandPaid += item['paid'] as double;
        grandRemaining += item['remaining'] as double;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pw.PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("تقرير الملخص العام لحسابات العملاء", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text("التاريخ: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pw.PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: pw.PdfColor.fromInt(0xFF0F172A)),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.center,
                headers: ['الباقي', 'المدفوع', 'الحساب', 'اسم العميل', 'الكود'],
                data: summaryData.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var item = entry.value;
                  return [
                    _formatMoney(item['remaining']),
                    _formatMoney(item['paid']),
                    _formatMoney(item['total']),
                    "${item['client']}",
                    "${idx + 1}",
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
                    pw.Text("إجمالي الباقي: ${_formatMoney(grandRemaining)} ج.م", style: const pw.TextStyle(color: pw.PdfColors.redAccent, fontSize: 9)),
                    pw.Text("إجمالي المدفوعات: ${_formatMoney(grandPaid)} ج.م", style: const pw.TextStyle(color: pw.PdfColors.greenAccent, fontSize: 9)),
                    pw.Text("إجمالي الحساب: ${_formatMoney(grandTotal)} ج.م", style: const pw.TextStyle(color: pw.PdfColors.cyanAccent, fontSize: 9)),
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
              title: const Text("معاينة تقرير الملخص العام PDF", style: TextStyle(color: Colors.white)),
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
    List<Map<String, dynamic>> summaryData = _getSummarizedClients();

    double grandTotal = 0;
    double grandPaid = 0;
    double grandRemaining = 0;

    for (var item in summaryData) {
      grandTotal += item['total'] as double;
      grandPaid += item['paid'] as double;
      grandRemaining += item['remaining'] as double;
    }

    const double tableMinWidth = 1000.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("شاشة الملخص العام لحسابات العملاء - المؤسسة التجارية", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _exportGeneralSummaryPdf,
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text("طباعة PDF", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
              // بطاقات الإجماليات العلوية بخطوط كبرة وواضحة
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard("إجمالي حساب العملاء:", "${_formatMoney(grandTotal)} ج.م", Colors.blue.shade700),
                    _buildSummaryCard("إجمالي المدفوعات:", "${_formatMoney(grandPaid)} ج.م", Colors.green.shade700),
                    _buildSummaryCard("إجمالي الباقي:", "${_formatMoney(grandRemaining)} ج.م", Colors.red.shade700),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // جدول الملخص العام
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
                      // رأس الأعمدة الثابت بخط كبير وواضح
                      Container(
                        color: const Color(0xFF0F172A),
                        child: SingleChildScrollView(
                          controller: ScrollController(),
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: tableMinWidth),
                            child: Row(
                              children: const [
                                SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(12.0), child: Text("الكود", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
                                SizedBox(width: 300, child: Padding(padding: EdgeInsets.all(12.0), child: Text("اسم العميل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
                                SizedBox(width: 200, child: Padding(padding: EdgeInsets.all(12.0), child: Text("الحساب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
                                SizedBox(width: 200, child: Padding(padding: EdgeInsets.all(12.0), child: Text("المدفوع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
                                SizedBox(width: 200, child: Padding(padding: EdgeInsets.all(12.0), child: Text("الباقي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // محتوى البيانات بخطوط كبيرة وواضحة
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
                                  itemCount: summaryData.length,
                                  itemBuilder: (context, index) {
                                    final item = summaryData[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(10.0), child: Text("${index + 1}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))),
                                          SizedBox(width: 300, child: Padding(padding: const EdgeInsets.all(10.0), child: Text("${item['client']}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)))),
                                          SizedBox(width: 200, child: Padding(padding: const EdgeInsets.all(10.0), child: Text(_formatMoney(item['total']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)))),
                                          SizedBox(width: 200, child: Padding(padding: const EdgeInsets.all(10.0), child: Text(_formatMoney(item['paid']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)))),
                                          SizedBox(width: 200, child: Padding(padding: const EdgeInsets.all(10.0), child: Text(_formatMoney(item['remaining']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)))),
                                        ],
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
              // شريط السفلي لعدد العملاء بخط كبير
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("إجمالي عدد العملاء: ${summaryData.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(width: 14),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}