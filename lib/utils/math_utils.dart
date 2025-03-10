import 'dart:math' as math;

class MathUtils {
  /// Calculate distance between two points
  static double distance(double x1, double y1, double x2, double y2) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }

  /// Calculate angle between three points
  static double angleInDegrees(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    final a = distance(x2, y2, x3, y3);
    final b = distance(x1, y1, x3, y3);
    final c = distance(x1, y1, x2, y2);

    // Law of cosines
    final angle = math.acos((a * a + c * c - b * b) / (2 * a * c));
    return angle * 180 / math.pi;
  }

  /// Convert radians to degrees
  static double radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  /// Convert degrees to radians
  static double degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Get a random integer between min and max (inclusive)
  static int randomInt(int min, int max) {
    final random = math.Random();
    return min + random.nextInt(max - min + 1);
  }

  /// Linear interpolation between two values
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
