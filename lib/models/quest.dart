enum QuestFrequency { once, daily, weekly }

class Quest {
  Quest({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.expPoints,
  });

  final String id;
  final String name;
  final String description;
  final QuestFrequency frequency;
  final int expPoints;
}
