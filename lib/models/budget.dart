enum BudgetPeriod { monthly, annual }

class Budget {
  const Budget({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.isEnabled,
    required this.period,
    required this.categoryIds,
    this.isDefault = false,
  });

  final String id;
  final String title;
  final String description;
  final double amount;
  final bool isEnabled;
  final BudgetPeriod period;
  final List<String> categoryIds;
  final bool isDefault;

  Budget copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    bool? isEnabled,
    BudgetPeriod? period,
    List<String>? categoryIds,
    bool? isDefault,
  }) {
    return Budget(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      isEnabled: isEnabled ?? this.isEnabled,
      period: period ?? this.period,
      categoryIds: categoryIds ?? this.categoryIds,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'isEnabled': isEnabled,
      'period': period.name,
      'categoryIds': categoryIds,
      'isDefault': isDefault,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      isEnabled: json['isEnabled'] as bool,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      categoryIds: (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
