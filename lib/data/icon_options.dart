import 'package:flutter/material.dart';

class IconOption {
  IconOption({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color? color;
}

final List<IconOption> iconOptions = [
  IconOption(id: 'wallet', label: 'Wallet', icon: Icons.account_balance_wallet),
  IconOption(
    id: 'home_bill',
    label: 'House Bill',
    icon: Icons.home_work_outlined,
  ),
  IconOption(id: 'trips', label: 'Trips', icon: Icons.flight_takeoff),
  IconOption(id: 'car', label: 'Car', icon: Icons.directions_car),
  IconOption(id: 'transport', label: 'Transport', icon: Icons.directions_bus),
  IconOption(id: 'games', label: 'Games', icon: Icons.sports_esports),
  IconOption(id: 'aperitivo', label: 'Aperitivo', icon: Icons.local_bar),
  IconOption(id: 'health', label: 'Health', icon: Icons.health_and_safety),
  IconOption(id: 'cloths', label: 'Cloths', icon: Icons.checkroom),
  IconOption(
    id: 'groceries',
    label: 'Groceries',
    icon: Icons.local_grocery_store,
  ),
  IconOption(id: 'electronics', label: 'Electronics', icon: Icons.devices),
  IconOption(id: 'software', label: 'Software', icon: Icons.code),
  IconOption(id: 'hobby', label: 'Hobby', icon: Icons.palette),
  IconOption(id: 'income', label: 'Income', icon: Icons.savings),
  IconOption(id: 'gift', label: 'Gift', icon: Icons.card_giftcard),
  IconOption(id: 'coffee', label: 'Coffee', icon: Icons.coffee),
  IconOption(id: 'food', label: 'Food', icon: Icons.restaurant),
  IconOption(id: 'shopping', label: 'Shopping', icon: Icons.shopping_bag),
  IconOption(id: 'movie', label: 'Movie', icon: Icons.movie),
  IconOption(id: 'music', label: 'Music', icon: Icons.music_note),
  IconOption(id: 'pet', label: 'Pet', icon: Icons.pets),
  IconOption(id: 'fitness', label: 'Fitness', icon: Icons.fitness_center),
  IconOption(id: 'bike', label: 'Bike', icon: Icons.pedal_bike),
  IconOption(id: 'train', label: 'Train', icon: Icons.train),
  IconOption(id: 'hotel', label: 'Hotel', icon: Icons.hotel),
  IconOption(id: 'phone', label: 'Phone', icon: Icons.phone_iphone),
  IconOption(id: 'water', label: 'Water', icon: Icons.water_drop),
  IconOption(id: 'electricity', label: 'Electricity', icon: Icons.bolt),
  IconOption(id: 'education', label: 'Education', icon: Icons.school),
  IconOption(id: 'tax', label: 'Tax', icon: Icons.account_balance),
  IconOption(id: 'travel', label: 'Travel', icon: Icons.luggage),
  IconOption(id: 'camera', label: 'Camera', icon: Icons.photo_camera),
  IconOption(id: 'garden', label: 'Garden', icon: Icons.yard),
  IconOption(id: 'baby', label: 'Baby', icon: Icons.child_friendly),
  IconOption(id: 'party', label: 'Party', icon: Icons.celebration),
  IconOption(id: 'book', label: 'Book', icon: Icons.menu_book),
  IconOption(id: 'tools', label: 'Tools', icon: Icons.handyman),
  IconOption(id: 'beauty', label: 'Beauty', icon: Icons.brush),
  IconOption(id: 'invest', label: 'Invest', icon: Icons.trending_up),
  IconOption(id: 'gift_card', label: 'Gift Card', icon: Icons.redeem),
  IconOption(id: 'art', label: 'Art', icon: Icons.color_lens),
  IconOption(id: 'gamepad', label: 'Gamepad', icon: Icons.videogame_asset),
  IconOption(id: 'plane', label: 'Plane', icon: Icons.flight),
  IconOption(id: 'bus', label: 'Bus', icon: Icons.directions_bus),
  IconOption(id: 'train_mdi', label: 'Train', icon: Icons.train),
  IconOption(id: 'wallet_mdi', label: 'Wallet', icon: Icons.account_balance_wallet),
  IconOption(id: 'music_mdi', label: 'Music', icon: Icons.music_note),
  IconOption(id: 'camera_mdi', label: 'Camera', icon: Icons.camera_alt),
  IconOption(id: 'food_mdi', label: 'Food', icon: Icons.restaurant),
  IconOption(id: 'coffee_mdi', label: 'Coffee', icon: Icons.coffee),
  IconOption(id: 'bike_mdi', label: 'Bike', icon: Icons.pedal_bike),
  IconOption(id: 'palette_mdi', label: 'Palette', icon: Icons.palette),
  IconOption(id: 'hospital_mdi', label: 'Hospital', icon: Icons.local_hospital),
  IconOption(id: 'shopping_mdi', label: 'Shopping', icon: Icons.shopping_bag),
  IconOption(id: 'basket_mdi', label: 'Basket', icon: Icons.shopping_basket),
  IconOption(id: 'game_mdi', label: 'Game', icon: Icons.videogame_asset),
  IconOption(id: 'laptop_mdi', label: 'Laptop', icon: Icons.laptop),
  IconOption(id: 'chip_mdi', label: 'Chip', icon: Icons.memory),
  IconOption(id: 'cloud_mdi', label: 'Cloud', icon: Icons.cloud),
  IconOption(id: 'dog_mdi', label: 'Dog', icon: Icons.pets),
  IconOption(id: 'cat_mdi', label: 'Cat', icon: Icons.pets),
  IconOption(id: 'palette2_mdi', label: 'Art', icon: Icons.brush),
  IconOption(id: 'drink_mdi', label: 'Drink', icon: Icons.local_bar),
  IconOption(id: 'flower_mdi', label: 'Flower', icon: Icons.local_florist),
  IconOption(id: 'gift_mdi', label: 'Gift', icon: Icons.card_giftcard),
  IconOption(id: 'ticket_mdi', label: 'Ticket', icon: Icons.confirmation_number),
  IconOption(id: 'heart_mdi', label: 'Heart', icon: Icons.favorite),
  IconOption(id: 'star_mdi', label: 'Star', icon: Icons.star),
  IconOption(id: 'shield_mdi', label: 'Shield', icon: Icons.shield),
  IconOption(id: 'sun_mdi', label: 'Sun', icon: Icons.wb_sunny),
  IconOption(id: 'moon_mdi', label: 'Moon', icon: Icons.nights_stay),
  IconOption(id: 'rocket_mdi', label: 'Rocket', icon: Icons.rocket),
  IconOption(id: 'tools_mdi', label: 'Tools', icon: Icons.build),
  IconOption(id: 'camera2_mdi', label: 'Camera', icon: Icons.camera),
  IconOption(id: 'book_mdi', label: 'Book', icon: Icons.menu_book),
  IconOption(
    id: 'yellow_dot',
    label: 'Yellow Dot',
    icon: Icons.circle,
    color: Colors.amber,
  ),
];

IconOption iconOptionById(String id) {
  return iconOptions.firstWhere(
    (option) => option.id == id,
    orElse: () => iconOptions.first,
  );
}
