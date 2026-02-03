import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyDepartment = 'user_department';
  static const String _keyName = 'user_name';
  static const String _keyIsFirstLogin = 'is_first_login';
  static const String _keySelectedSheetId = 'selected_sheet_id';

  Future<void> saveUserInfo(String department, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDepartment, department);
    await prefs.setString(_keyName, name);
    await prefs.setBool(_keyIsFirstLogin, false);
  }

  Future<String?> getDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDepartment);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstLogin) ?? true;
  }

  Future<void> clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDepartment);
    await prefs.remove(_keyName);
    await prefs.setBool(_keyIsFirstLogin, true);
  }

  Future<void> saveSelectedSheetId(String sheetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedSheetId, sheetId);
  }

  Future<String?> getSelectedSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedSheetId);
  }
}
