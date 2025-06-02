import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commerce.dart';
import '../models/product.dart';

class CommerceService {
  final _db = FirebaseFirestore.instance;

  /// Obtiene todos los comercios
  Future<List<Commerce>> fetchCommerces() async {
    try {
      print('🛠️ [CommerceService] fetchCommerces() → consultando /commerce');
      final snap = await _db.collection('commerce').get();
      print('🛠️ [CommerceService] snap.docs.length = ${snap.docs.length}');
      return snap.docs
          .map((d) => Commerce.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (e, st) {
      print('❌ [CommerceService] Error en fetchCommerces: $e');
      print(st);
      return [];
    }
  }

  /// Obtiene comercios por una lista de IDs
  Future<List<Commerce>> fetchCommercesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _db
        .collection('commerce')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snap.docs
        .map((d) => Commerce.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Búsqueda simple de comercios por nombre, ciudad o estado
  Future<List<Commerce>> searchCommerces(String query) async {
    final all = await fetchCommerces();
    final lower = query.toLowerCase();
    return all.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          c.city.toLowerCase().contains(lower) ||
          c.state.toLowerCase().contains(lower);
    }).toList();
  }

  /// Obtiene productos de un comercio
  Future<List<Product>> fetchProducts(String commerceId) async {
    final snap = await _db
        .collection('commerce')
        .doc(commerceId)
        .collection('product')
        .get();
    return snap.docs
        .map((d) => Product.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Obtiene el link de Google Maps (ubicación) de un comercio
  Future<String?> fetchUbication(String commerceId) async {
    final doc = await _db.collection('commerce').doc(commerceId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data != null && data.containsKey('ubication_link')
        ? data['ubication_link'] as String
        : null;
  }
}
