import 'package:flutter/material.dart';
import 'app_data.dart';

class ProfitOfferScreen extends StatefulWidget {
  const ProfitOfferScreen({super.key});

  @override
  _ProfitOfferScreenState createState() => _ProfitOfferScreenState();
}

class _ProfitOfferScreenState extends State<ProfitOfferScreen> {
  final TextEditingController clientController = TextEditingController();

  String? selectedClient;
  String? selectedLocation;
  String? selectedDate;
  String? selectedOrderNum;
  int? selectedRowIndex;

  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    clientController.dispose();
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

  String _getClient(Map item) => (item['client'] ?? item['client_name'] ?? '').toString().trim();
  String _getLocation(Map item) => (item['location'] ?? item['work_location'] ?? '').toString().trim();
  String _getDate(Map item) => (item['date'] ?? item['created_date'] ?? '').toString().trim();
  String _getOrder(Map item) => (item['order'] ?? item['order_num'] ?? '').toString().trim();

  // عند اختيار عميل جديد، يتم تفريغ الحقول التابعة تماماً
  void _onClientSelected(String? clientName) {
    setState(() {
      selectedClient = clientName;
      selectedLocation = null;
      selectedDate = null;
      selectedOrderNum = null;
      clientController.text = clientName ?? '';
    });
  }

  // تصفية بيانات عروض الأسعار بدقة حسب العميل والشروط الفرعية
  List<Map<String, dynamic>> _getFilteredList() {
    if (selectedClient == null || selectedClient!.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> clientFilteredOrders = AppData.savedQuotations.where((e) => _getClient(e) == selectedClient).toList();

    return clientFilteredOrders.where((item) {
      String loc = _getLocation(item);
      bool matchesLocation = selectedLocation == null || selectedLocation!.isEmpty || loc == selectedLocation;
      
      String ord = _getOrder(item);
      bool matchesOrder = selectedOrderNum == null || selectedOrderNum!.isEmpty || ord == selectedOrderNum;
      
      String itemDate = _getDate(item);
      bool matchesDate = selectedDate == null || selectedDate!.isEmpty || itemDate == selectedDate;

      return matchesLocation && matchesOrder && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<String> allClients = AppData.savedQuotations.map((e) => _getClient(e)).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> clientFilteredOrders = selectedClient == null || selectedClient!.isEmpty
        ? []
        : AppData.savedQuotations.where((e) => _getClient(e) == selectedClient).toList();

    List<String> locationsList = clientFilteredOrders.map((e) => _getLocation(e)).where((e) => e.isNotEmpty).toSet().toList();
    List<String> datesList = clientFilteredOrders.map((e) => _getDate(e)).where((e) => e.isNotEmpty).toSet().toList();
    List<String> orderNumbers = clientFilteredOrders.map((e) => _getOrder(e)).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> filteredList = _getFilteredList();

    double totalSell = 0;
    double totalCost = 0;
    for (var item in filteredList) {
      double itemSell = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;
      double unitSell = double.tryParse((item['sell'] ?? item['price'] ?? '0').toString()) ?? 0;
      double unitCost = double.tryParse((item['cost'] ?? item['cost_price'] ?? '0').toString()) ?? 0;
      double qty = double.tryParse((item['qty'] ?? item['unit_count'] ?? '1').toString()) ?? 1;
      double area = double.tryParse((item['area'] ?? '0').toString()) ?? 0;

      if (itemSell == 0) {
        itemSell = area > 0 ? (area * unitSell) : (qty * unitSell);
      }

      double itemCostTotal = area > 0 ? (area * unitCost) : (qty * unitCost);

      totalSell += itemSell;
      totalCost += itemCostTotal;
    }
    double totalProfit = totalSell - totalCost;

    // تم تكبير عرض عمود "الخامة" بشكل أكبر لتجنب أي اقتصاص للنص
    final List<Map<String, dynamic>> columnsData = [
      {"title": "م", "width": 50.0},
      {"title": "رقم العرض", "width": 85.0},
      {"title": "اسم العميل", "width": 140.0},
      {"title": "مكان العمل", "width": 160.0},
      {"title": "نوع العمل", "width": 160.0},
      {"title": "الخامة", "width": 240.0},    // تم تكبير عرض عمود الخامة هنا
      {"title": "العدد/المساحة", "width": 100.0},
      {"title": "إجمالي البيع", "width": 110.0},
      {"title": "إجمالي التكلفة", "width": 110.0},
      {"title": "الربح الصافي", "width": 110.0},
      {"title": "التاريخ", "width": 100.0},
    ];

    double totalTableWidth = columnsData.fold(0.0, (sum, col) => sum + (col['width'] as double));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF581C87),
        title: const Text("شاشة تقرير أرباح العروض - المؤسسة التجارية", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // لوحة الفلاتر العلوية
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) return allClients;
                            return allClients.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (selection) {
                            _onClientSelected(selection);
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            if (controller.text != (selectedClient ?? '')) {
                              controller.text = selectedClient ?? '';
                            }
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(fontSize: 11.5),
                              decoration: const InputDecoration(
                                hintText: "اسم العميل (أساسي)",
                                hintStyle: TextStyle(fontSize: 11, color: Colors.purple),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                              onChanged: (val) {
                                clientController.text = val;
                                if (val.isEmpty) {
                                  _onClientSelected(null);
                                }
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
                          value: selectedLocation,
                          isExpanded: true,
                          hint: const Text("مكان العمل", style: TextStyle(fontSize: 11.5)),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("كل الأماكن", style: TextStyle(fontSize: 11.5))),
                            ...locationsList.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 11.5)))),
                          ],
                          onChanged: selectedClient == null || selectedClient!.isEmpty ? null : (val) => setState(() => selectedLocation = val),
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: DropdownButtonFormField<String>(
                          value: selectedDate,
                          isExpanded: true,
                          hint: const Text("التاريخ", style: TextStyle(fontSize: 11.5)),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("كل التواريخ", style: TextStyle(fontSize: 11.5))),
                            ...datesList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11.5)))),
                          ],
                          onChanged: selectedClient == null || selectedClient!.isEmpty ? null : (val) => setState(() => selectedDate = val),
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: DropdownButtonFormField<String>(
                          value: selectedOrderNum,
                          isExpanded: true,
                          hint: const Text("رقم العرض", style: TextStyle(fontSize: 11.5)),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("كل العروض", style: TextStyle(fontSize: 11.5))),
                            ...orderNumbers.map((ord) => DropdownMenuItem(value: ord, child: Text(ord, style: const TextStyle(fontSize: 11.5)))),
                          ],
                          onChanged: selectedClient == null || selectedClient!.isEmpty ? null : (val) => setState(() => selectedOrderNum = val),
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // جدول عرض أرباح العروض برأس ثابت تماماً وتمرير سليم
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // رأس الأعمدة الثابت
                      Container(
                        color: const Color(0xFF581C87),
                        child: SingleChildScrollView(
                          controller: ScrollController(),
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: totalTableWidth),
                            child: Row(
                              children: columnsData.map((col) {
                                return Container(
                                  width: col['width'] as double,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  alignment: Alignment.center,
                                  child: Text(
                                    col['title'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // محتوى الجدول القابل للتمرير أفقياً ورأسياً بشكل آمن تماماً
                      Expanded(
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: totalTableWidth),
                              child: SizedBox(
                                width: totalTableWidth,
                                child: ListView.builder(
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredList[index];
                                    bool isSelected = selectedRowIndex == index;

                                    double unitSell = double.tryParse((item['sell'] ?? item['price'] ?? '0').toString()) ?? 0;
                                    double unitCost = double.tryParse((item['cost'] ?? item['cost_price'] ?? '0').toString()) ?? 0;
                                    double qty = double.tryParse((item['qty'] ?? item['unit_count'] ?? '1').toString()) ?? 1;
                                    double area = double.tryParse((item['area'] ?? '0').toString()) ?? 0;
                                    double itemSell = double.tryParse((item['total'] ?? item['total_amount'] ?? '0').toString()) ?? 0;

                                    if (itemSell == 0) {
                                      itemSell = area > 0 ? (area * unitSell) : (qty * unitSell);
                                    }
                                    double itemCost = area > 0 ? (area * unitCost) : (qty * unitCost);
                                    double rowProfit = itemSell - itemCost;

                                    String qtyOrAreaStr = area > 0 ? "${_formatMoney(area)}م" : "${_formatMoney(qty)}";

                                    List<String> rowValues = [
                                      "${index + 1}",
                                      _getOrder(item),
                                      _getClient(item),
                                      _getLocation(item),
                                      "${item['workType'] ?? item['work_type'] ?? ''}",
                                      "${item['material'] ?? item['material_type'] ?? ''}",
                                      qtyOrAreaStr,
                                      _formatMoney(itemSell),
                                      _formatMoney(itemCost),
                                      _formatMoney(rowProfit),
                                      _getDate(item),
                                    ];

                                    return InkWell(
                                      onTap: () => setState(() => selectedRowIndex = index),
                                      child: Container(
                                        color: isSelected ? Colors.purple.shade100 : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                        child: Row(
                                          children: List.generate(columnsData.length, (colIdx) {
                                            TextStyle cellStyle = const TextStyle(color: Colors.black87, fontSize: 11);
                                            if (colIdx == 7) {
                                              cellStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11);
                                            } else if (colIdx == 8) {
                                              cellStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 11);
                                            } else if (colIdx == 9) {
                                              cellStyle = TextStyle(fontWeight: FontWeight.bold, color: rowProfit >= 0 ? Colors.green.shade700 : Colors.red, fontSize: 11);
                                            }

                                            return Container(
                                              width: columnsData[colIdx]['width'] as double,
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                              alignment: Alignment.center,
                                              child: Text(
                                                rowValues[colIdx],
                                                style: cellStyle,
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }),
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
              // بطاقات الملخص السفلي للإجماليات
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF581C87),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("عدد البنود: ${filteredList.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("إجمالي المبيعات: ${_formatMoney(totalSell)} ج.م", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("إجمالي التكلفة: ${_formatMoney(totalCost)} ج.م", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("صافي الأرباح: ${_formatMoney(totalProfit)} ج.م", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
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