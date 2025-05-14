// Modelo para manejar usuarios
class UserModel {
  final String id; // ID interno de Firestore
  final String googleId; // ID de Google
  final String email;
  final String name;
  final String photoUrl;
  final List<String> favoriteCommerces; // Lista de IDs de comercios favoritos

  UserModel({
    required this.id,
    required this.googleId,
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.favoriteCommerces,
  });

  // Crear desde un mapa (documento de Firestore)
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      googleId: data['googleId'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      favoriteCommerces: List<String>.from(data['favoriteCommerces'] ?? []),
    );
  }

  // Convertir a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'googleId': googleId,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'favoriteCommerces': favoriteCommerces,
    };
  }

  // Crear una copia con modificaciones
  UserModel copyWith({
    String? id,
    String? googleId,
    String? email,
    String? name,
    String? photoUrl,
    List<String>? favoriteCommerces,
  }) {
    return UserModel(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteCommerces: favoriteCommerces ?? this.favoriteCommerces,
    );
  }
}
