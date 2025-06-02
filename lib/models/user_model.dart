import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para manejar usuarios
class UserModel {
  final String id; // ID interno de Firestore
  final String firebaseUid; // UID de Firebase (funciona para Google y Email)
  final String email;
  final String name;
  final String photoUrl;
  final List<String> favoriteCommerces; // Lista de IDs de comercios favoritos
  final DateTime createdAt; // Fecha de creación
  final DateTime? updatedAt; // Fecha de última actualización
  final bool isEmailVerified; // Estado de verificación del email
  final String authProvider; // Proveedor de autenticación ('google' o 'email')

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.favoriteCommerces,
    required this.createdAt,
    this.updatedAt,
    required this.isEmailVerified,
    required this.authProvider,
  });

  // Crear desde un mapa (documento de Firestore)
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      firebaseUid: data['firebaseUid'] ??
          data['googleId'] ??
          '', // Compatibilidad hacia atrás
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      favoriteCommerces: List<String>.from(data['favoriteCommerces'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isEmailVerified: data['isEmailVerified'] ?? false,
      authProvider: data['authProvider'] ??
          'google', // Por defecto google para compatibilidad
    );
  }

  // Convertir a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'firebaseUid': firebaseUid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'favoriteCommerces': favoriteCommerces,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isEmailVerified': isEmailVerified,
      'authProvider': authProvider,
      // Mantener googleId para compatibilidad hacia atrás
      'googleId': firebaseUid,
    };
  }

  // Crear una copia con modificaciones
  UserModel copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? name,
    String? photoUrl,
    List<String>? favoriteCommerces,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    String? authProvider,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteCommerces: favoriteCommerces ?? this.favoriteCommerces,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  // Getters útiles
  bool get isGoogleUser => authProvider == 'google';
  bool get isEmailUser => authProvider == 'email';
  bool get hasPhoto => photoUrl.isNotEmpty;
  String get displayName => name.isNotEmpty ? name : email.split('@').first;
  String get initials {
    if (name.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : 'U';
    final names = name.split(' ');
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[1][0]}'.toUpperCase();
  }

  // Verificar si el usuario está completo (tiene todos los datos necesarios)
  bool get isProfileComplete {
    return name.isNotEmpty && email.isNotEmpty;
  }

  // Verificar si el usuario necesita verificar su email
  bool get needsEmailVerification {
    return authProvider == 'email' && !isEmailVerified;
  }

  // Método para convertir a JSON string (útil para debugging)
  @override
  String toString() {
    return 'UserModel(id: $id, firebaseUid: $firebaseUid, email: $email, name: $name, authProvider: $authProvider, isEmailVerified: $isEmailVerified)';
  }

  // Verificar igualdad
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.firebaseUid == firebaseUid &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ firebaseUid.hashCode ^ email.hashCode;
  }

  // Factory constructor para crear usuario desde Firebase Auth User
  factory UserModel.fromFirebaseUser({
    required String firestoreId,
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoURL,
    required String authProvider,
    bool isEmailVerified = false,
  }) {
    return UserModel(
      id: firestoreId,
      firebaseUid: firebaseUid,
      email: email,
      name: displayName ?? '',
      photoUrl: photoURL ?? '',
      favoriteCommerces: [],
      createdAt: DateTime.now(),
      updatedAt: null,
      isEmailVerified: isEmailVerified,
      authProvider: authProvider,
    );
  }

  // Factory constructor para crear un usuario vacío/template
  factory UserModel.empty() {
    return UserModel(
      id: '',
      firebaseUid: '',
      email: '',
      name: '',
      photoUrl: '',
      favoriteCommerces: [],
      createdAt: DateTime.now(),
      updatedAt: null,
      isEmailVerified: false,
      authProvider: 'email',
    );
  }
}
