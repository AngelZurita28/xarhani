import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colección de usuarios
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Crear o actualizar usuario después del login/registro
  Future<UserModel> createOrUpdateUser() async {
    if (currentUser == null) {
      throw Exception('No hay usuario autenticado');
    }

    // Buscar si el usuario ya existe por su UID de Firebase (funciona para Google y Email)
    final querySnapshot = await _usersCollection
        .where('firebaseUid', isEqualTo: currentUser!.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // El usuario ya existe, actualizar sus datos
      final docId = querySnapshot.docs.first.id;
      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;

      final updatedUser = UserModel.fromMap(userData, docId).copyWith(
        name: currentUser!.displayName ?? userData['name'] ?? '',
        email: currentUser!.email ?? userData['email'] ?? '',
        photoUrl: currentUser!.photoURL ?? userData['photoUrl'] ?? '',
      );

      await _usersCollection.doc(docId).update(updatedUser.toMap());
      return updatedUser;
    } else {
      // Crear nuevo usuario
      final newUser = UserModel(
        id: '', // Se asignará después
        firebaseUid: currentUser!.uid, // Cambio de googleId a firebaseUid
        email: currentUser!.email ?? '',
        name: currentUser!.displayName ??
            _extractNameFromEmail(currentUser!.email ?? ''),
        photoUrl: currentUser!.photoURL ?? '',
        favoriteCommerces: [],
        // Agregar campos adicionales que podrías necesitar
        createdAt: DateTime.now(),
        isEmailVerified: currentUser!.emailVerified,
        authProvider: _getAuthProvider(),
      );

      final docRef = await _usersCollection.add(newUser.toMap());
      return newUser.copyWith(id: docRef.id);
    }
  }

  // Obtener usuario actual desde Firestore
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

  // Actualizar perfil de usuario
  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
  }) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    final updates = <String, dynamic>{};

    if (name != null && name != userModel.name) {
      updates['name'] = name;
      // También actualizar en Firebase Auth si es diferente
      if (currentUser!.displayName != name) {
        await currentUser!.updateDisplayName(name);
      }
    }

    if (photoUrl != null && photoUrl != userModel.photoUrl) {
      updates['photoUrl'] = photoUrl;
      // También actualizar en Firebase Auth si es diferente
      if (currentUser!.photoURL != photoUrl) {
        await currentUser!.updatePhotoURL(photoUrl);
      }
    }

    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(userModel.id).update(updates);
    }
  }

  // Verificar y actualizar estado de verificación de email
  Future<void> updateEmailVerificationStatus() async {
    if (currentUser == null) return;

    await currentUser!.reload(); // Recargar datos del usuario
    final userModel = await getCurrentUserModel();

    if (userModel != null &&
        userModel.isEmailVerified != currentUser!.emailVerified) {
      await _usersCollection.doc(userModel.id).update({
        'isEmailVerified': currentUser!.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Agregar un comercio a favoritos
  Future<void> addToFavorites(String commerceId) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    if (!userModel.favoriteCommerces.contains(commerceId)) {
      final updatedFavorites = [...userModel.favoriteCommerces, commerceId];
      await _usersCollection.doc(userModel.id).update({
        'favoriteCommerces': updatedFavorites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Quitar un comercio de favoritos
  Future<void> removeFromFavorites(String commerceId) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    if (userModel.favoriteCommerces.contains(commerceId)) {
      final updatedFavorites =
          userModel.favoriteCommerces.where((id) => id != commerceId).toList();
      await _usersCollection.doc(userModel.id).update({
        'favoriteCommerces': updatedFavorites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Verificar si un comercio está en favoritos
  Future<bool> isCommerceFavorite(String commerceId) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return false;
    return userModel.favoriteCommerces.contains(commerceId);
  }

  // Obtener lista de favoritos
  Future<List<String>> getFavoriteCommerces() async {
    final userModel = await getCurrentUserModel();
    return userModel?.favoriteCommerces ?? [];
  }

  // Eliminar cuenta de usuario
  Future<void> deleteAccount() async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    // Eliminar documento de Firestore
    await _usersCollection.doc(userModel.id).delete();

    // Eliminar cuenta de Firebase Auth
    await currentUser!.delete();
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Métodos auxiliares privados
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

    for (UserInfo userInfo in currentUser!.providerData) {
      if (userInfo.providerId == 'google.com') {
        return 'google';
      } else if (userInfo.providerId == 'password') {
        return 'email';
      }
    }
    return 'email'; // Por defecto
  }

  // Stream para escuchar cambios en el usuario actual
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await getCurrentUserModel();
    });
  }

  // Reenviar email de verificación
  Future<void> sendEmailVerification() async {
    if (currentUser != null && !currentUser!.emailVerified) {
      await currentUser!.sendEmailVerification();
    }
  }

  // Enviar reset de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
