import 'package:cheapcheap/models/stat_key.dart';

class Profile {
  Profile({
    this.name = '',
    this.imagePath,
    this.level = 1,
    this.xp = 0,
    Map<StatKey, double>? stats,
  }) : stats = stats ?? _defaultStats();

  final String name;
  final String? imagePath;
  final int level;
  final int xp;
  final Map<StatKey, double> stats;

  Profile copyWith({
    String? name,
    String? imagePath,
    int? level,
    int? xp,
    Map<StatKey, double>? stats,
  }) {
    return Profile(
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imagePath': imagePath,
      'level': level,
      'xp': xp,
      'stats': stats.map((key, value) => MapEntry(key.name, value)),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawStats = Map<String, dynamic>.from(json['stats'] as Map? ?? {});
    final Map<StatKey, double> stats = _defaultStats();
    for (final entry in rawStats.entries) {
      final key = StatKey.values.firstWhere(
        (stat) => stat.name == entry.key,
        orElse: () => StatKey.spirit,
      );
      stats[key] = (entry.value as num?)?.toDouble() ?? 0;
    }
    return Profile(
      name: json['name'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      stats: stats,
    );
  }

  static Map<StatKey, double> _defaultStats() {
    return {
      StatKey.strength: 0,
      StatKey.belly: 0,
      StatKey.spirit: 0,
      StatKey.adulthood: 0,
      StatKey.easygoing: 0,
    };
  }
}
