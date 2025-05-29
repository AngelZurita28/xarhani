// widgets/search_results_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/commerce.dart';
import '../services/commerce_service.dart';
import '../services/user_service.dart';
import '../ui/app_colors.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;
  final ValueChanged<Commerce> onCommerceTap;

  const SearchResultsPage({
    Key? key,
    required this.query,
    required this.onCommerceTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ya no envolvemos en Scaffold ni AppBar:
    return SearchResultsContent(
      query: query,
      onCommerceTap: onCommerceTap,
    );
  }
}

class SearchResultsContent extends StatefulWidget {
  final String query;
  final ValueChanged<Commerce> onCommerceTap;

  const SearchResultsContent({
    Key? key,
    required this.query,
    required this.onCommerceTap,
  }) : super(key: key);

  @override
  _SearchResultsContentState createState() => _SearchResultsContentState();
}

class _SearchResultsContentState extends State<SearchResultsContent> {
  final CommerceService _commerceService = CommerceService();
  final UserService _userService = UserService();

  List<Commerce> _searchResults = [];
  List<Commerce> _recommended = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _searchResults = await _commerceService.searchCommerces(widget.query);
      final all = await _commerceService.fetchCommerces();
      all.shuffle(Random());
      _recommended = all.take(5).toList();
    } catch (e) {
      print('Error al cargar datos de búsqueda: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCommerceCard(Commerce c) {
    final imageUrl = c.images.isNotEmpty ? c.images.first.trim() : '';
    return GestureDetector(
      onTap: () => widget.onCommerceTap(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
                child: imageUrl.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.bgSecondary,
                        child: const Icon(Icons.store,
                            size: 50, color: Colors.grey),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${c.city}, ${c.state}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        c.description.length > 80
                            ? '${c.description.substring(0, 80)}...'
                            : c.description,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_searchResults.isEmpty) ...[
          const SizedBox(height: 40),
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No se encontraron resultados',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Intenta con otros términos de búsqueda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ] else ...[
          // Puedes mantener o quitar este título local
          Text('Resultados (${_searchResults.length})',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 16),
          ..._searchResults.map(_buildCommerceCard),
        ],
        if (_recommended.isNotEmpty) ...[
          const SizedBox(height: 24),
          Divider(thickness: 1, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text('Recomendados para ti',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._recommended.map(_buildCommerceCard),
        ],
      ],
    );
  }
}
