import 'package:flutter/material.dart';
import 'app_data.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'quotations_screen.dart';
import 'clients_report_screen.dart';
import 'clients_offer_report_screen.dart';
import 'database_screen.dart';
import 'database_offer_screen.dart';
import 'statement_screen.dart';
import 'statement_offer_screen.dart';
import 'profit_screen.dart';
import 'profit_offer_screen.dart';
import 'general_summary_screen.dart';
import 'search_options_screen.dart';
import 'lists_and_management_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'dart:convert';

class MainDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  const MainDashboardScreen({super.key, this.currentUser});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  bool _hasPermission(String key) {
    if (widget.currentUser == null || widget.currentUser!['role'] == "مدير أساسي") {
      return true;
    }
    final permissions = widget.currentUser!['permissions'] as Map<String, dynamic>?;
    if (permissions == null) return false;
    return permissions[key] == true;
  }

  @override
  Widget build(BuildContext context) {
    // 📱 فحص عرض الشاشة لمعرفة هل الجهاز موبايل أم شاشة عريضة
    bool isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text("${AppData.companyName} - لوحة التحكم الرئيسية", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // بطاقة معلومات المؤسسة والشعار العلوية
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (AppData.showCompanyName) ...[
                      Column(
                        children: [
                          Text(
                            AppData.companyName,
                            style: TextStyle(
                              fontSize: AppData.companyFontSize,
                              height: AppData.companyFontHeight,
                              fontFamily: AppData.companyFontFamily,
                              color: AppData.companyFontColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.currentUser != null ? "المستخدم: ${widget.currentUser!['username']} (${widget.currentUser!['role']})" : "لوحة التحكم والتشغيل السريع",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                    ],
                    if (AppData.showCompanyLogo) ...[
                      AppData.companyLogoPath != null && AppData.companyLogoPath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: AppData.companyLogoPath!.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(AppData.companyLogoPath!.split(',').last),
                                      width: AppData.companyLogoWidth,
                                      height: AppData.companyLogoHeight,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 28, color: Color(0xFF0F172A)),
                                    )
                                  : const Icon(Icons.business, size: 28, color: Color(0xFF0F172A)),
                            )
                          : const Icon(Icons.business, size: 28, color: Color(0xFF0F172A)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 15),
              
              // 📱 محتوى الأقسام: يتكيف تلقائياً (Row للشاشات الكبيرة و Column للموبايل)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: isMobile
                      ? Column(
                          children: [
                            _buildSectionCard(
                              title: "البيانات الجديدة",
                              headerColor: const Color(0xFF2563EB),
                              buttons: _getNewDataButtons(),
                            ),
                            const SizedBox(height: 15),
                            _buildSectionCard(
                              title: "القوائم والبحث",
                              headerColor: const Color(0xFFD97706),
                              buttons: _getListsAndSearchButtons(),
                            ),
                            const SizedBox(height: 15),
                            _buildSectionCard(
                              title: "عروض الأسعار",
                              headerColor: const Color(0xFF334155),
                              buttons: _getQuotationsButtons(),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 950),
                            child: SizedBox(
                              height: 520,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 310,
                                    child: _buildDashboardCard(
                                      title: "البيانات الجديدة",
                                      headerColor: const Color(0xFF2563EB),
                                      buttons: _getNewDataButtons(),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  SizedBox(
                                    width: 310,
                                    child: _buildDashboardCard(
                                      title: "القوائم والبحث",
                                      headerColor: const Color(0xFFD97706),
                                      buttons: _getListsAndSearchButtons(),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  SizedBox(
                                    width: 310,
                                    child: _buildDashboardCard(
                                      title: "عروض الأسعار",
                                      headerColor: const Color(0xFF334155),
                                      buttons: _getQuotationsButtons(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("2026-09-14", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

  // قوائم الأزرار منظمة لتسهيل الاستخدام
  List<Widget> _getNewDataButtons() {
    return [
      if (_hasPermission('ordersEntry'))
        _buildMenuButton("إدخال البيانات", Icons.edit_note, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersEntryScreen()));
        }),
      if (_hasPermission('clientsReport'))
        _buildMenuButton("تقرير العملاء", Icons.people_outline, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsReportScreen()));
        }),
      if (_hasPermission('database'))
        _buildMenuButton("قاعدة البيانات", Icons.table_chart, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DatabaseScreen()));
        }),
      if (_hasPermission('statement'))
        _buildMenuButton("كشف حساب", Icons.receipt_long, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const StatementScreen()));
        }),
      if (_hasPermission('profit'))
        _buildMenuButton("الأرباح", Icons.account_balance_wallet, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfitScreen()));
        }),
    ];
  }

  List<Widget> _getListsAndSearchButtons() {
    return [
      if (_hasPermission('lists'))
        _buildMenuButton("القوائم والأسعار", Icons.list_alt, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
        }),
      if (_hasPermission('settings'))
        _buildMenuButton("إعدادات النظام والشركة", Icons.settings, () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          setState(() {});
        }),
      if (_hasPermission('generalSummary'))
        _buildMenuButton("الملخص العام", Icons.fact_check, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const GeneralSummaryScreen()));
        }),
      if (_hasPermission('searchOptions'))
        _buildMenuButton("البحث المتعدد", Icons.search, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchOptionsScreen()));
        }),
      if (_hasPermission('archive'))
        _buildMenuButton("استعراض الأرشيف", Icons.archive, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchiveScreen()));
        }),
    ];
  }

  List<Widget> _getQuotationsButtons() {
    return [
      if (_hasPermission('quotationsEntry'))
        _buildMenuButton("إدخال بيانات (العرض)", Icons.local_offer, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QuotationsEntryScreen()));
        }),
      if (_hasPermission('quotationsClients'))
        _buildMenuButton("تقرير العملاء (العرض)", Icons.analytics_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsOfferReportScreen()));
        }),
      if (_hasPermission('quotationsDatabase'))
        _buildMenuButton("قاعدة بيانات (العروض)", Icons.storage, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DatabaseOfferScreen()));
        }),
      if (_hasPermission('quotationsStatement'))
        _buildMenuButton("كشف حساب (العرض)", Icons.receipt, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const StatementOfferScreen()));
        }),
      if (_hasPermission('quotationsProfit'))
        _buildMenuButton("الارباح (العرض)", Icons.trending_up, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfitOfferScreen()));
        }),
    ];
  }

  // بطاقة الشاشات الكبيرة
  Widget _buildDashboardCard({required String title, required Color headerColor, required List<Widget> buttons}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: headerColor, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)],
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

  // بطاقة مخصصة للشاشات الصغيرة (الموبايل) تتكيف طولياً
  Widget _buildSectionCard({required String title, required Color headerColor, required List<Widget> buttons}) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: headerColor, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: headerColor),
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: buttons.map((btn) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: btn,
              )).toList(),
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