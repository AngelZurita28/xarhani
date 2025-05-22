// Pantalla que muestra resultados de búsqueda desde Firestore y una sección de recomendados integrada al MainLayout
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

// Versión como Widget para usar dentro del MainLayout
class SearchResultsContent extends StatefulWidget {
  final String query;

  const SearchResultsContent({required this.query});

  @override
  State<SearchResultsContent> createState() => _SearchResultsContentState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Resultados de búsqueda'),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SearchResultsContent(query: widget.query),
    );
  }
}

class _SearchResultsContentState extends State<SearchResultsContent> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recommended = [];
  List<String> _userFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
    _loadUserFavorites();
  }

  Future<void> _loadUserFavorites() async {
    try {
      final userModel = await _userService.getCurrentUserModel();
      if (userModel != null) {
        setState(() {
          _userFavorites = userModel.favoriteCommerces;
        });
      }
    } catch (e) {
      print('Error al cargar favoritos del usuario: $e');
    }
  }

  Future<void> _performSearch() async {
    try {
      final resultSnap = await FirebaseFirestore.instance
          .collection('commerce')
          .where('name', isGreaterThanOrEqualTo: widget.query)
          .where('name', isLessThanOrEqualTo: widget.query + '\uf8ff')
          .get();

      final recommendedSnap = await FirebaseFirestore.instance
          .collection('commerce')
          .orderBy(FieldPath.documentId)
          .limit(3)
          .get();

      setState(() {
        _searchResults = resultSnap.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _recommended = recommendedSnap.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error al buscar: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmToggleFavorite(BuildContext context, String commerceId,
      String commerceName, bool isCurrentlyFavorite) {
    if (isCurrentlyFavorite) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Eliminar de tus Me Gusta?'),
          content: Text(
              '¿Estás seguro de eliminar de tus Me Gusta al comercio "$commerceName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleFavorite(commerceId);
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
    } else {
      _toggleFavorite(commerceId);
    }
  }

  Future<void> _toggleFavorite(String commerceId) async {
    try {
      final isCurrentlyFavorite = _userFavorites.contains(commerceId);

      if (isCurrentlyFavorite) {
        await _userService.removeFromFavorites(commerceId);
        setState(() {
          _userFavorites.remove(commerceId);
        });
      } else {
        await _userService.addToFavorites(commerceId);
        setState(() {
          _userFavorites.add(commerceId);
        });
      }
    } catch (e) {
      print('Error al actualizar favoritos: $e');
    }
  }

  Widget _buildCommerceCard(Map<String, dynamic> commerce) {
    final commerceId = commerce['id'];
    final isFavorite = _userFavorites.contains(commerceId);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detail',
          arguments: commerce,
        ).then((_) => _loadUserFavorites());
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _confirmToggleFavorite(
                              context,
                              commerceId,
                              commerce['name'] ?? 'este comercio',
                              isFavorite,
                            );
                          },
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          label: Text(isFavorite ? 'Te Gusta' : 'Me Gusta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFFC333),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
                      commerce['description'].toString().length > 100
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
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Resultados de búsqueda
              if (_searchResults.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No se encontraron resultados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Intenta con otros términos de búsqueda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Resultados (${_searchResults.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                ..._searchResults.map((c) => _buildCommerceCard(c)).toList(),
              ],

              // Sección de recomendados
              if (_recommended.isNotEmpty) ...[
                SizedBox(height: 24),
                Divider(thickness: 1, color: Colors.grey[300]),
                SizedBox(height: 24),
                Text(
                  'Recomendados para ti',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ..._recommended.map((c) => _buildCommerceCard(c)).toList(),
              ],

              SizedBox(height: 16),
            ],
          );
  }
}
