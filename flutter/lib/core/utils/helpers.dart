import 'dart:math';

class Helpers {
  static final _random = Random();

  static String generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(20, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  static T randomElement<T>(List<T> list) {
    return list[_random.nextInt(list.length)];
  }

  static List<T> shuffle<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    shuffled.shuffle(_random);
    return shuffled;
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  static int calculateScore(int correct, int total) {
    if (total == 0) return 0;
    return ((correct / total) * 100).round();
  }

  static double calculateAccuracy(int correct, int total) {
    if (total == 0) return 0;
    return correct / total;
  }
}
