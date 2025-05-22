import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _favoriteCommerces = [];
  bool _isLoading = true;
  void _confirmRemoveFavorite(
      BuildContext context, String commerceId, String commerceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar de tus Me Gusta?'),
        content: Text(
            '¿Estás seguro de eliminar de tus Me Gusta al comercio "$commerceName"?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(), // Cerrar sin hacer nada
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
              _removeFromFavorites(commerceId); // Ejecuta eliminación
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = await _userService.getCurrentUserModel();

      if (userModel != null && userModel.favoriteCommerces.isNotEmpty) {
        final List<Map<String, dynamic>> commercesList = [];

        for (final commerceId in userModel.favoriteCommerces) {
          final commerceDoc = await FirebaseFirestore.instance
              .collection('commerce') // ✅ Corrección aquí
              .doc(commerceId)
              .get();

          if (commerceDoc.exists) {
            final commerceData = commerceDoc.data() as Map<String, dynamic>;
            commercesList.add({
              'id': commerceDoc.id,
              ...commerceData,
            });
          }
        }

        setState(() {
          _favoriteCommerces = commercesList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _favoriteCommerces = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar favoritos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(String commerceId) async {
    await _userService.removeFromFavorites(commerceId);
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Mis Favoritos'),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoriteCommerces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tienes comercios favoritos',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Explora y guarda tus comercios favoritos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _favoriteCommerces.length,
                  itemBuilder: (context, index) {
                    final commerce = _favoriteCommerces[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: commerce,
                        ).then((_) => _loadFavorites());
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: commerce['image'] != null
                                    ? Image.network(
                                        commerce['image'],
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.store,
                                          color: Colors.grey[600],
                                          size: 50,
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          commerce['name'] ?? 'Sin nombre',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            _confirmRemoveFavorite(
                                                context,
                                                commerce['id'],
                                                commerce['name'] ??
                                                    'este comercio');
                                          },
                                          icon: Icon(Icons.favorite,
                                              size: 16, color: Colors.red),
                                          label: Text('Te Gusta'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFFFC333),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  if (commerce['city'] != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          commerce['city'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: 12),
                                  if (commerce['description'] != null)
                                    Text(
                                      commerce['description']
                                                  .toString()
                                                  .length >
                                              100
                                          ? commerce['description']
                                                  .toString()
                                                  .substring(0, 100) +
                                              '...'
                                          : commerce['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
