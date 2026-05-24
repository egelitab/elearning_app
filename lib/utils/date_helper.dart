import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DateHelper {
  static final ValueNotifier<String> calendarFormat = ValueNotifier<String>('Global');
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    calendarFormat.value = _prefs?.getString('pref_calendar_format') ?? 'Global';
  }

  static Future<void> refresh() async {
    await _prefs?.reload();
    calendarFormat.value = _prefs?.getString('pref_calendar_format') ?? 'Global';
  }

  static String formatDue(String dueDateStr) {
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final difference = dueDate.difference(now);

      if (difference.isNegative) return "Overdue";

      if (calendarFormat.value == 'Ethiopian') {
        return "Due ${_toEthiopianTime(dueDate)} (Eth)";
      }

      if (difference.inHours < 24) {
        if (difference.inHours == 0) return "Due in ${difference.inMinutes} mins";
        return "Due in ${difference.inHours} hrs";
      }

      if (difference.inDays < 7) {
        return "Due ${DateFormat('EEEE').format(dueDate)}";
      }

      return "Due ${DateFormat('MMM d').format(dueDate)}";
    } catch (e) {
      return "Due $dueDateStr";
    }
  }

  static String formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      if (calendarFormat.value == 'Ethiopian') {
        return "${_toEthiopianTime(date)} (Eth)";
      }
      return "${date.day}/${date.month}";
    } catch (_) {
      return dateStr;
    }
  }

  static String formatTimeSlot(String slot, {bool startOnly = false}) {
    if (calendarFormat.value == 'Ethiopian') {
      if (startOnly) return "${slot.split(' - ')[0]} (Eth)";
      return "$slot (Eth)";
    }
    
    // Input is assumed to be Ethiopian format (e.g., "02:00 - 03:45")
    try {
      final parts = slot.split(' - ');
      if (parts.length != 2) return slot;
      
      if (startOnly) return _ethToGregorian(parts[0]);
      return "${_ethToGregorian(parts[0])} - ${_ethToGregorian(parts[1])}";
    } catch (_) {
      return slot;
    }
  }

  static String _ethToGregorian(String ethTime) {
    final timeParts = ethTime.trim().split(':');
    if (timeParts.length != 2) return ethTime;
    
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    
    // Ethiopian daytime starts at 6:00 AM Gregorian (12:00 Eth)
    // 1:00 Eth = 7:00 AM Greg
    // Offset is +6
    int gregHour = (hour + 6);
    
    String period = "AM";
    if (gregHour >= 12) {
      if (gregHour >= 24) {
        gregHour -= 24;
        period = "AM";
      } else {
        period = "PM";
        if (gregHour > 12) gregHour -= 12;
      }
    } else {
      period = "AM";
    }
    
    if (gregHour == 0) gregHour = 12;
    
    return "${gregHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
  }

  static String _toEthiopianTime(DateTime dt) {
    int ethHour = (dt.hour - 6) % 12;
    if (ethHour == 0) ethHour = 12;
    if (ethHour < 0) ethHour += 12;

    String period;
    if (dt.hour >= 6 && dt.hour < 12) {
      period = "Morning";
    } else if (dt.hour >= 12 && dt.hour < 18) {
      period = "Day";
    } else if (dt.hour >= 18 && dt.hour < 24) {
      period = "Evening";
    } else {
      period = "Night";
    }

    return "$ethHour:${dt.minute.toString().padLeft(2, '0')} $period";
  }
}



