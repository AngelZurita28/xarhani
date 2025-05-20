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
      // Obtener el usuario actual
      final userModel = await _userService.getCurrentUserModel();

      if (userModel != null && userModel.favoriteCommerces.isNotEmpty) {
        // Obtener los detalles de los comercios favoritos
        final List<Map<String, dynamic>> commercesList = [];

        for (final commerceId in userModel.favoriteCommerces) {
          final commerceDoc = await FirebaseFirestore.instance
              .collection('commerces')
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
    // Recargar favoritos después de eliminar
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Favoritos'),
        backgroundColor: Colors.white,
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
                        // Navegar a la página de detalles
                        Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: commerce,
                        ).then((_) => _loadFavorites());
                      },
                      child: Card(
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen del comercio
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: commerce['image'] != null
                                  ? Image.network(
                                      commerce['image'],
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 160,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.store,
                                        color: Colors.grey[600],
                                        size: 50,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre del comercio
                                  Text(
                                    commerce['name'] ?? 'Sin nombre',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Ciudad o ubicación
                                  if (commerce['city'] != null)
                                    Text(
                                      commerce['city'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),

                                  SizedBox(height: 8),

                                  // Descripción breve
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

                                  SizedBox(height: 12),

                                  // Botón de "Te Gusta" (con opción para eliminar)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _removeFromFavorites(commerce['id']);
                                      },
                                      icon: Icon(Icons.favorite),
                                      label: Text('Te Gusta'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFFFC333),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
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
