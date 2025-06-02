// models/commerce.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Commerce {
  final String id;
  final String name;
  final String city;
  final String state;
  final String description;
  final String history;
  final List<String> images;
  final String ubication; // Link a Google Maps
  final double latitude;
  final double longitude;

  Commerce({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.description,
    required this.history,
    required this.images,
    required this.ubication,
    required this.latitude,
    required this.longitude,
  });

  factory Commerce.fromMap(Map<String, dynamic> m) {
    // 1) Extrae el GeoPoint del campo 'location', si existe
    double lat = 0.0, lng = 0.0;
    final rawLocation = m['location'];
    if (rawLocation is GeoPoint) {
      lat = rawLocation.latitude;
      lng = rawLocation.longitude;
    }

    // 2) Procesa el campo 'images' sea lista o cadena única
    final rawImages = m['images'];
    late List<String> images;
    if (rawImages is Iterable) {
      images = rawImages
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawImages is String && rawImages.trim().isNotEmpty) {
      images = [rawImages.trim()];
    } else {
      images = [];
    }

    return Commerce(
      id: m['id'] as String,
      name: (m['name'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      state: (m['state'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      history: (m['history'] ?? '').toString(),
      images: images,
      ubication: (m['ubication_link'] ?? '').toString().trim(),
      latitude: lat,
      longitude: lng,
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
      'location': GeoPoint(latitude, longitude),
    };
  }
}
