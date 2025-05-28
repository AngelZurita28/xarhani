import 'package:flutter/material.dart';
import '../models/commerce.dart';
import '../services/commerce_service.dart';
import '../services/user_service.dart';
import '../ui/app_colors.dart';

class FavoritesPage extends StatefulWidget {
  final ValueChanged<Commerce> onCommerceTap;

  const FavoritesPage({
    Key? key,
    required this.onCommerceTap,
  }) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final UserService _userService = UserService();
  final CommerceService _commerceService = CommerceService();
  late Future<List<String>> _favoriteIdsFuture;

  @override
  void initState() {
    super.initState();
    _favoriteIdsFuture = _userService.fetchFavoriteIds();
  }

  void _refreshFavorites() {
    setState(() {
      _favoriteIdsFuture = _userService.fetchFavoriteIds();
    });
  }

  Future<void> _removeFavorite(String commerceId) async {
    await _userService.removeFromFavorites(commerceId);
    _refreshFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _favoriteIdsFuture,
        builder: (context, idsSnap) {
          if (idsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (idsSnap.hasError || idsSnap.data == null) {
            return const Center(child: Text('Error al cargar favoritos'));
          }
          final ids = idsSnap.data!;
          if (ids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes comercios favoritos',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Explora y guarda tus comercios favoritos',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }
          return FutureBuilder<List<Commerce>>(
            future: _commerceService.fetchCommercesByIds(ids),
            builder: (context, comSnap) {
              if (comSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (comSnap.hasError || comSnap.data == null) {
                return const Center(
                    child: Text('Error al cargar comercios favoritos'));
              }
              final favorites = comSnap.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final commerce = favorites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onCommerceTap(commerce),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: commerce.images.isNotEmpty
                                  ? Image.network(commerce.images.first,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.store,
                                          color: Colors.grey, size: 50),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        commerce.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      if (commerce.city.isNotEmpty)
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              commerce.city,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 8),
                                      if (commerce.description.isNotEmpty)
                                        Text(
                                          commerce.description.length > 100
                                              ? commerce.description
                                                      .substring(0, 100) +
                                                  '...'
                                              : commerce.description,
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _removeFavorite(commerce.id),
                                  icon: const Icon(Icons.favorite,
                                      size: 16, color: Colors.white),
                                  label: const Text('Quitar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.complement,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
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
              );
            },
          );
        },
      ),
    );
  }
}
