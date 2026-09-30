import 'package:flutter/material.dart';
import 'app_data.dart';

class ProfitScreen extends StatefulWidget {
  const ProfitScreen({super.key});

  @override
  _ProfitScreenState createState() => _ProfitScreenState();
}

class _ProfitScreenState extends State<ProfitScreen> {
  final TextEditingController clientController = TextEditingController();

  String? selectedClient;
  String? selectedLocation;
  String? selectedDate;
  String? selectedOrderNum;
  int? selectedRowIndex;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalScrollController.addListener(() {
      if (_headerScrollController.hasClients && _headerScrollController.offset != _horizontalScrollController.offset) {
        _headerScrollController.jumpTo(_horizontalScrollController.offset);
      }
    });
    _headerScrollController.addListener(() {
      if (_horizontalScrollController.hasClients && _horizontalScrollController.offset != _horizontalScrollController.offset) {
        _horizontalScrollController.jumpTo(_horizontalScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    clientController.dispose();
    _horizontalScrollController.dispose();
    _headerScrollController.dispose();
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

  // تصفية بيانات الأرباح بدقة حسب العميل والشروط الفرعية
  List<Map<String, dynamic>> _getFilteredList() {
    if (selectedClient == null || selectedClient!.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> clientFilteredOrders = AppData.savedOrders.where((e) => _getClient(e) == selectedClient).toList();

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
    List<String> allClients = AppData.savedOrders.map((e) => _getClient(e)).where((e) => e.isNotEmpty).toSet().toList();

    List<Map<String, dynamic>> clientFilteredOrders = selectedClient == null || selectedClient!.isEmpty
        ? []
        : AppData.savedOrders.where((e) => _getClient(e) == selectedClient).toList();

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

    const double tableMinWidth = 1350.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("شاشة تقرير الأرباح - المؤسسة التجارية", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          // 📱 تفعيل التمرير العمودي الشامل للصفحة لتناسب الموبايل والشاشات الصغيرة
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  // لوحة الفلاتر العلوية
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)],
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
                                    hintStyle: TextStyle(fontSize: 11, color: Colors.blue),
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
                              initialValue: selectedLocation,
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
                              initialValue: selectedDate,
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
                              initialValue: selectedOrderNum,
                              isExpanded: true,
                              hint: const Text("رقم الطلب", style: TextStyle(fontSize: 11.5)),
                              items: [
                                const DropdownMenuItem(value: "", child: Text("كل الطلبات", style: TextStyle(fontSize: 11.5))),
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
                  // جدول عرض الأرباح مع رأس أعمدة ثابت وتمرير مزدوج
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
                            color: const Color(0xFF0F172A),
                            child: SingleChildScrollView(
                              controller: _headerScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: tableMinWidth),
                                child: Row(
                                  children: const [
                                    SizedBox(width: 50, child: Padding(padding: EdgeInsets.all(10.0), child: Text("م", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 85, child: Padding(padding: EdgeInsets.all(10.0), child: Text("رقم الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 140, child: Padding(padding: EdgeInsets.all(10.0), child: Text("اسم العميل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(10.0), child: Text("مكان العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 120, child: Padding(padding: EdgeInsets.all(10.0), child: Text("نوع العمل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 150, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الخامة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(10.0), child: Text("العدد/المساحة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(10.0), child: Text("إجمالي البيع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(10.0), child: Text("إجمالي التكلفة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 95, child: Padding(padding: EdgeInsets.all(10.0), child: Text("الربح الصافي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    SizedBox(width: 90, child: Padding(padding: EdgeInsets.all(10.0), child: Text("التاريخ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
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

                                        String qtyOrAreaStr = area > 0 ? "${_formatMoney(area)}م" : _formatMoney(qty);

                                        return InkWell(
                                          onTap: () => setState(() => selectedRowIndex = index),
                                          child: Container(
                                            color: isSelected ? Colors.blue.shade100 : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${index + 1}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 85, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_getOrder(item), style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 140, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_getClient(item), style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_getLocation(item), style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 120, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['workType'] ?? item['work_type'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 150, child: Padding(padding: const EdgeInsets.all(8.0), child: Text("${item['material'] ?? item['material_type'] ?? ''}", style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(qtyOrAreaStr, style: const TextStyle(fontSize: 11)))),
                                                SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(itemSell), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)))),
                                                SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(itemCost), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 11)))),
                                                SizedBox(width: 95, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatMoney(rowProfit), style: TextStyle(fontWeight: FontWeight.bold, color: rowProfit >= 0 ? Colors.green.shade700 : Colors.red, fontSize: 11)))),
                                                SizedBox(width: 90, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_getDate(item), style: const TextStyle(fontSize: 11)))),
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
                  const SizedBox(height: 10),
                  // بطاقات الملخص السفلي للإجماليات
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
        ),
      ),
    );
  }
}