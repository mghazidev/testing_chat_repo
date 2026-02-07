import 'package:intl/intl.dart';

class TimeUtils {
  static DateTime toLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  static String formatChatTime(DateTime? utcDateTime) {
    if (utcDateTime == null) return '';
    final local = utcDateTime.toLocal();
    return DateFormat('hh:mm a').format(local);
  }

  static String formatFull(DateTime? utcDateTime) {
    if (utcDateTime == null) return '';
    final local = utcDateTime.toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(local);
  }
}
