import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
  IconOption(id: 'gamepad', label: 'Gamepad', icon: MdiIcons.gamepadVariant),
  IconOption(id: 'plane', label: 'Plane', icon: MdiIcons.airplane),
  IconOption(id: 'bus', label: 'Bus', icon: MdiIcons.bus),
  IconOption(id: 'train_mdi', label: 'Train', icon: MdiIcons.train),
  IconOption(id: 'wallet_mdi', label: 'Wallet', icon: MdiIcons.wallet),
  IconOption(id: 'music_mdi', label: 'Music', icon: MdiIcons.music),
  IconOption(id: 'camera_mdi', label: 'Camera', icon: MdiIcons.camera),
  IconOption(id: 'food_mdi', label: 'Food', icon: MdiIcons.foodForkDrink),
  IconOption(id: 'coffee_mdi', label: 'Coffee', icon: MdiIcons.coffee),
  IconOption(id: 'bike_mdi', label: 'Bike', icon: MdiIcons.bike),
  IconOption(id: 'palette_mdi', label: 'Palette', icon: MdiIcons.palette),
  IconOption(id: 'hospital_mdi', label: 'Hospital', icon: MdiIcons.hospitalBox),
  IconOption(id: 'shopping_mdi', label: 'Shopping', icon: MdiIcons.shopping),
  IconOption(id: 'basket_mdi', label: 'Basket', icon: MdiIcons.basket),
  IconOption(id: 'game_mdi', label: 'Game', icon: MdiIcons.gamepadSquare),
  IconOption(id: 'laptop_mdi', label: 'Laptop', icon: MdiIcons.laptop),
  IconOption(id: 'chip_mdi', label: 'Chip', icon: MdiIcons.memory),
  IconOption(id: 'cloud_mdi', label: 'Cloud', icon: MdiIcons.cloud),
  IconOption(id: 'dog_mdi', label: 'Dog', icon: MdiIcons.dog),
  IconOption(id: 'cat_mdi', label: 'Cat', icon: MdiIcons.cat),
  IconOption(id: 'palette2_mdi', label: 'Art', icon: MdiIcons.brush),
  IconOption(id: 'drink_mdi', label: 'Drink', icon: MdiIcons.glassCocktail),
  IconOption(id: 'flower_mdi', label: 'Flower', icon: MdiIcons.flowerTulip),
  IconOption(id: 'gift_mdi', label: 'Gift', icon: MdiIcons.gift),
  IconOption(id: 'ticket_mdi', label: 'Ticket', icon: MdiIcons.ticket),
  IconOption(id: 'heart_mdi', label: 'Heart', icon: MdiIcons.heart),
  IconOption(id: 'star_mdi', label: 'Star', icon: MdiIcons.star),
  IconOption(id: 'shield_mdi', label: 'Shield', icon: MdiIcons.shield),
  IconOption(id: 'sun_mdi', label: 'Sun', icon: MdiIcons.weatherSunny),
  IconOption(id: 'moon_mdi', label: 'Moon', icon: MdiIcons.weatherNight),
  IconOption(id: 'rocket_mdi', label: 'Rocket', icon: MdiIcons.rocketLaunch),
  IconOption(id: 'tools_mdi', label: 'Tools', icon: MdiIcons.tools),
  IconOption(id: 'camera2_mdi', label: 'Camera', icon: MdiIcons.cameraIris),
  IconOption(id: 'book_mdi', label: 'Book', icon: MdiIcons.bookOpenPageVariant),
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
