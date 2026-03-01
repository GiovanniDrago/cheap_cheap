enum StatKey { strength, belly, spirit, adulthood, easygoing }

extension StatKeyLabel on StatKey {
  String get label {
    switch (this) {
      case StatKey.strength:
        return 'Strength';
      case StatKey.belly:
        return 'Belly';
      case StatKey.spirit:
        return 'Spirit';
      case StatKey.adulthood:
        return 'Adulthood';
      case StatKey.easygoing:
        return 'Easygoing';
    }
  }
}
