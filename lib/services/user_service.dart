// services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colección de usuarios
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Obtener usuario actual de Firebase Auth
  User? get currentUser => _auth.currentUser;

  /// Crea o actualiza el documento de usuario en Firestore tras login/registro
  Future<UserModel> createOrUpdateUser() async {
    if (currentUser == null) {
      throw Exception('No hay usuario autenticado');
    }

    final querySnapshot = await _usersCollection
        .where('firebaseUid', isEqualTo: currentUser!.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Actualizar usuario existente
      final doc = querySnapshot.docs.first;
      final userData = doc.data() as Map<String, dynamic>;
      final updatedUser = UserModel.fromMap(userData, doc.id).copyWith(
        name: currentUser!.displayName ?? userData['name'] ?? '',
        email: currentUser!.email ?? userData['email'] ?? '',
        photoUrl: currentUser!.photoURL ?? userData['photoUrl'] ?? '',
      );
      await _usersCollection.doc(doc.id).update(updatedUser.toMap());
      return updatedUser;
    } else {
      // Crear nuevo usuario
      final newUser = UserModel(
        id: '',
        firebaseUid: currentUser!.uid,
        email: currentUser!.email ?? '',
        name: currentUser!.displayName ??
            _extractNameFromEmail(currentUser!.email ?? ''),
        photoUrl: currentUser!.photoURL ?? '',
        favoriteCommerces: [],
        createdAt: DateTime.now(),
        isEmailVerified: currentUser!.emailVerified,
        authProvider: _getAuthProvider(),
      );
      final docRef = await _usersCollection.add(newUser.toMap());
      return newUser.copyWith(id: docRef.id);
    }
  }

  /// Obtiene el modelo de usuario actual desde Firestore
  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;

    final querySnapshot = await _usersCollection
        .where('firebaseUid', isEqualTo: currentUser!.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  /// Actualizar nombre y/o foto de perfil
  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    final updates = <String, dynamic>{};

    if (name != null && name != userModel.name) {
      updates['name'] = name;
      if (currentUser!.displayName != name) {
        await currentUser!.updateDisplayName(name);
      }
    }
    if (photoUrl != null && photoUrl != userModel.photoUrl) {
      updates['photoUrl'] = photoUrl;
      if (currentUser!.photoURL != photoUrl) {
        await currentUser!.updatePhotoURL(photoUrl);
      }
    }
    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(userModel.id).update(updates);
    }
  }

  /// Reload y actualizar verificación de email
  Future<void> updateEmailVerificationStatus() async {
    if (currentUser == null) return;
    await currentUser!.reload();
    final userModel = await getCurrentUserModel();
    if (userModel != null &&
        userModel.isEmailVerified != currentUser!.emailVerified) {
      await _usersCollection.doc(userModel.id).update({
        'isEmailVerified': currentUser!.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Agrega un comercio a favoritos
  Future<void> addToFavorites(String commerceId) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    if (!userModel.favoriteCommerces.contains(commerceId)) {
      final updated = [...userModel.favoriteCommerces, commerceId];
      await _usersCollection.doc(userModel.id).update({
        'favoriteCommerces': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Quita un comercio de favoritos
  Future<void> removeFromFavorites(String commerceId) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    if (userModel.favoriteCommerces.contains(commerceId)) {
      final updated =
          userModel.favoriteCommerces.where((id) => id != commerceId).toList();
      await _usersCollection.doc(userModel.id).update({
        'favoriteCommerces': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Verifica si un comercio está en favoritos
  Future<bool> isCommerceFavorite(String commerceId) async {
    final userModel = await getCurrentUserModel();
    return userModel?.favoriteCommerces.contains(commerceId) ?? false;
  }

  /// Obtiene lista de IDs de comercios favoritos
  Future<List<String>> fetchFavoriteIds() async {
    final userModel = await getCurrentUserModel();
    return userModel?.favoriteCommerces ?? [];
  }

  /// Elimina la cuenta de usuario (Firestore + Auth)
  Future<void> deleteAccount() async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;
    await _usersCollection.doc(userModel.id).delete();
    await currentUser!.delete();
  }

  /// Cierra sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- Métodos auxiliares ---

  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'Usuario';
    return email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
        .trim();
  }

  String _getAuthProvider() {
    if (currentUser == null) return 'unknown';
    for (final userInfo in currentUser!.providerData) {
      if (userInfo.providerId == 'google.com') return 'google';
      if (userInfo.providerId == 'password') return 'email';
    }
    return 'email';
  }

  /// Stream de cambios de usuario
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await getCurrentUserModel();
    });
  }

  /// Reenvía email de verificación
  Future<void> sendEmailVerification() async {
    if (currentUser != null && !currentUser!.emailVerified) {
      await currentUser!.sendEmailVerification();
    }
  }

  /// Enviar correo de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
