import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) {
      return await sharedPreferences.setString(key, value);
    } else if (value is int) {
      return await sharedPreferences.setInt(key, value);
    } else if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    } else if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    }
    return false;
  }

  static Future<dynamic> getData({required String key}) async {
    return sharedPreferences.get(key);
  }

  static Future<bool> removeData({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  // ✅ ADD THIS METHOD TO FIX THE ERROR
  static Map<String, dynamic> getAllData() {
    Map<String, dynamic> allData = {};
    for (String key in sharedPreferences.getKeys()) {
      var value = sharedPreferences.get(key);
      if (value is String) {
        try {
          allData[key] = jsonDecode(value);
        } catch (_) {
          allData[key] = value;
        }
      } else {
        allData[key] = value;
      }
    }
    return allData;
  }
}
