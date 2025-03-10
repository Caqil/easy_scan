import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format date as a readable string
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date,
      {String format = 'MMM dd, yyyy HH:mm'}) {
    return DateFormat(format).format(date);
  }

  /// Get a relative time string like "2 hours ago"
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get a friendly date string
  static String getFriendlyDate(DateTime date) {
    if (isToday(date)) {
      return 'Today at ${DateFormat('HH:mm').format(date)}';
    } else if (isYesterday(date)) {
      return 'Yesterday at ${DateFormat('HH:mm').format(date)}';
    } else {
      return formatDateTime(date);
    }
  }
}
