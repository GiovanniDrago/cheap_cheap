import 'package:cheapcheap/models/stat_key.dart';

class Category {
  Category({
    required this.id,
    required this.name,
    required this.iconId,
    required this.isIncomeDefault,
    required this.statKey,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String iconId;
  final bool isIncomeDefault;
  final StatKey statKey;
  final bool isDefault;

  Category copyWith({
    String? id,
    String? name,
    String? iconId,
    bool? isIncomeDefault,
    StatKey? statKey,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconId: iconId ?? this.iconId,
      isIncomeDefault: isIncomeDefault ?? this.isIncomeDefault,
      statKey: statKey ?? this.statKey,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconId': iconId,
      'isIncomeDefault': isIncomeDefault,
      'statKey': statKey.name,
      'isDefault': isDefault,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconId: json['iconId'] as String,
      isIncomeDefault: json['isIncomeDefault'] as bool? ?? false,
      statKey: StatKey.values.firstWhere(
        (key) => key.name == json['statKey'],
        orElse: () => StatKey.spirit,
      ),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
