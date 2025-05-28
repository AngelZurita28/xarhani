// models/commerce.dart
class Commerce {
  final String id;
  final String name;
  final String city;
  final String state;
  final String description;
  final String history;
  final List<String> images;
  final String ubication; // Link a Google Maps

  Commerce({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.description,
    required this.history,
    required this.images,
    required this.ubication,
  });

  factory Commerce.fromMap(Map<String, dynamic> m) {
    return Commerce(
      id: m['id'] as String,
      name: m['name'] ?? '',
      city: m['city'] ?? '',
      state: m['state'] ?? '',
      description: m['description'] ?? '',
      history: m['history'] ?? '',
      images: List<String>.from(m['images'] ?? []),
      ubication: m['ubication_link'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'description': description,
      'history': history,
      'images': images,
      'ubication_link': ubication,
    };
  }
}
