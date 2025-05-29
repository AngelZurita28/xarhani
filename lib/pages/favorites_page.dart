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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Comercio eliminado de favoritos'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eliminamos Scaffold y AppBar: asumimos que el padre maneja la estructura.
    return Container(
      color: AppColors.bgPrimary,
      child: FutureBuilder<List<String>>(
        future: _favoriteIdsFuture,
        builder: (context, idsSnap) {
          if (idsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (idsSnap.hasError || idsSnap.data == null) {
            return Center(
              child: Text(
                'Error al cargar favoritos',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final ids = idsSnap.data!;
          if (ids.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: AppColors.disabled,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No tienes comercios favoritos',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Explora y guarda tus comercios favoritos para encontrarlos fácilmente.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                return Center(
                  child: Text(
                    'Error al cargar comercios favoritos',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              final favorites = comSnap.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final commerce = favorites[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => widget.onCommerceTap(commerce),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: commerce.images.isNotEmpty
                                    ? Image.network(
                                        commerce.images.first.trim(),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.bgSecondary,
                                        child: Icon(
                                          Icons.store,
                                          color: AppColors.disabled,
                                          size: 48,
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    commerce.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AppColors.complement,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${commerce.city}, ${commerce.state}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    commerce.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                                'Confirmar eliminación'),
                                            content: Text(
                                              '¿Quitar "${commerce.name}" de favoritos?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(_, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(_, true),
                                                child: const Text('Quitar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          _removeFavorite(commerce.id);
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      label: const Text('Quitar'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
