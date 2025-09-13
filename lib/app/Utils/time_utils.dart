import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeUtils {
  /// Formats a DateTime, Firestore Timestamp, or String to 'h:mm a'
  static String formatToTime(dynamic date) {
    if (date == null) return '';

    DateTime dateTime;

    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return '';
      }
    } else {
      return '';
    }

    return DateFormat('h:mm a').format(dateTime);
  }
}
