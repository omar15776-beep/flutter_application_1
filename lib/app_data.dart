import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppData {
  // إعدادات المؤسسة والهوية المتقدمة
  static String companyName = "المؤسسة التجارية";
  static double companyFontSize = 14.0;
  static double companyFontHeight = 1.2;
  static String companyFontFamily = "Cairo";
  static Color companyFontColor = const Color(0xFF0F172A);
  
  static double companyLogoWidth = 35.0;
  static double companyLogoHeight = 35.0;
  static String? companyLogoPath;
  static bool showCompanyName = true;
  static bool showCompanyLogo = true;
  static List<Map<String, String>> clients = [];
  static List<Map<String, String>> materials = [];
  static List<Map<String, String>> methods = [];
  static List<Map<String, String>> searchOptions = [];
  static List<Map<String, dynamic>> savedOrders = [];
  static List<Map<String, dynamic>> savedQuotations = [];
  static List<Map<String, dynamic>> users = [];

  static Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      companyName = prefs.getString('company_name') ?? "المؤسسة التجارية";
      companyFontSize = prefs.getDouble('company_font_size') ?? 14.0;
      companyFontHeight = prefs.getDouble('company_font_height') ?? 1.2;
      companyFontFamily = prefs.getString('company_font_family') ?? "Cairo";
      
      int? colorVal = prefs.getInt('company_font_color');
      if (colorVal != null) {
        companyFontColor = Color(colorVal);
      }

      companyLogoWidth = prefs.getDouble('company_logo_width') ?? 35.0;
      companyLogoHeight = prefs.getDouble('company_logo_height') ?? 35.0;
      companyLogoPath = prefs.getString('company_logo_path');

      final clientsStr = prefs.getString('saved_clients');
      if (clientsStr != null) {
        clients = List<Map<String, String>>.from(json.decode(clientsStr).map((x) => Map<String, String>.from(x)));
      }

      final materialsStr = prefs.getString('saved_materials');
      if (materialsStr != null) {
        materials = List<Map<String, String>>.from(json.decode(materialsStr).map((x) => Map<String, String>.from(x)));
      }

      final methodsStr = prefs.getString('saved_methods');
      if (methodsStr != null) {
        methods = List<Map<String, String>>.from(json.decode(methodsStr).map((x) => Map<String, String>.from(x)));
      }

      final searchStr = prefs.getString('saved_search');
      if (searchStr != null) {
        searchOptions = List<Map<String, String>>.from(json.decode(searchStr).map((x) => Map<String, String>.from(x)));
      }

      final ordersStr = prefs.getString('saved_orders');
      if (ordersStr != null) {
        savedOrders = List<Map<String, dynamic>>.from(json.decode(ordersStr).map((x) => Map<String, dynamic>.from(x)));
      }

      final quotesStr = prefs.getString('saved_quotations');
      if (quotesStr != null) {
        savedQuotations = List<Map<String, dynamic>>.from(json.decode(quotesStr).map((x) => Map<String, dynamic>.from(x)));
      }

      final usersStr = prefs.getString('saved_users');
      if (usersStr != null) {
        users = List<Map<String, dynamic>>.from(json.decode(usersStr).map((x) => Map<String, dynamic>.from(x)));
      }

      debugPrint("تم تحميل البيانات بنجاح من الذاكرة الدائمة.");
    } catch (e) {
      debugPrint("خطأ أثناء تحميل البيانات: $e");
    }
  }

  static Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('company_name', companyName);
      await prefs.setDouble('company_font_size', companyFontSize);
      await prefs.setDouble('company_font_height', companyFontHeight);
      await prefs.setString('company_font_family', companyFontFamily);
      await prefs.setInt('company_font_color', fontColorToInt(companyFontColor));
      
      await prefs.setDouble('company_logo_width', companyLogoWidth);
      await prefs.setDouble('company_logo_height', companyLogoHeight);
      if (companyLogoPath != null) {
        await prefs.setString('company_logo_path', companyLogoPath!);
      }

      await prefs.setString('saved_clients', json.encode(clients));
      await prefs.setString('saved_materials', json.encode(materials));
      await prefs.setString('saved_methods', json.encode(methods));
      await prefs.setString('saved_search', json.encode(searchOptions));
      await prefs.setString('saved_orders', json.encode(savedOrders));
      await prefs.setString('saved_quotations', json.encode(savedQuotations));
      await prefs.setString('saved_users', json.encode(users));
      
      debugPrint("تم حفظ البيانات بنجاح في الذاكرة الدائمة.");
    } catch (e) {
      debugPrint("خطأ أثناء حفظ البيانات: $e");
    }
  }

  static int fontColorToInt(Color color) {
    return color.toARGB32();
  }
}