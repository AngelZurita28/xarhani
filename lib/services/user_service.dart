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

  // Crear o actualizar usuario después del login
  Future<UserModel> createOrUpdateUser() async {
    if (currentUser == null) {
      throw Exception('No hay usuario autenticado');
    }

    // Buscar si el usuario ya existe por su ID de Google
    final querySnapshot = await _usersCollection
        .where('googleId', isEqualTo: currentUser!.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // El usuario ya existe, actualizar sus datos
      final docId = querySnapshot.docs.first.id;
      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;

      final updatedUser = UserModel.fromMap(userData, docId).copyWith(
        name: currentUser!.displayName,
        email: currentUser!.email,
        photoUrl: currentUser!.photoURL,
      );

      await _usersCollection.doc(docId).update(updatedUser.toMap());
      return updatedUser;
    } else {
      // Crear nuevo usuario
      final newUser = UserModel(
        id: '', // Se asignará después
        googleId: currentUser!.uid,
        email: currentUser!.email ?? '',
        name: currentUser!.displayName ?? '',
        photoUrl: currentUser!.photoURL ?? '',
        favoriteCommerces: [],
      );

      final docRef = await _usersCollection.add(newUser.toMap());
      return newUser.copyWith(id: docRef.id);
    }
  }

  // Obtener usuario actual desde Firestore
  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;

    final querySnapshot = await _usersCollection
        .where('googleId', isEqualTo: currentUser!.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }

    return null;
  }

  // Agregar un comercio a favoritos
  Future<void> addToFavorites(String commerceId) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return;

    if (!userModel.favoriteCommerces.contains(commerceId)) {
      final updatedFavorites = [...userModel.favoriteCommerces, commerceId];
      await _usersCollection.doc(userModel.id).update({
        'favoriteCommerces': updatedFavorites,
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
      });
    }
  }

  // Verificar si un comercio está en favoritos
  Future<bool> isCommerceFavorite(String commerceId) async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return false;

    return userModel.favoriteCommerces.contains(commerceId);
  }
}
