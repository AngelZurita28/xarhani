import 'dart:math';
import 'package:flutter/material.dart';
import '../models/commerce.dart';
import '../services/commerce_service.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<Commerce> onCommerceTap;

  const HomePage({
    Key? key,
    required this.onCommerceTap,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<List<Commerce>> fetchCommerces() async {
    print('🔔 [HomePage] fetchCommerces() called');
    try {
      final list = await CommerceService().fetchCommerces();
      print('🔔 [HomePage] fetchCommerces() returned ${list.length} items');
      return list;
    } catch (e, st) {
      print('❌ [HomePage] Error in fetchCommerces: $e');
      print(st);
      return [];
    }
  }

  List<Commerce> _randomSubset(List<Commerce> all, int max) {
    final copy = List<Commerce>.from(all)..shuffle(Random());
    return copy.take(min(max, copy.length)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Commerce>>(
        future: fetchCommerces(),
        builder: (context, snapshot) {
          print('🔍 [HomePage] FutureBuilder snapshot: '
              'state=${snapshot.connectionState}, '
              'hasData=${snapshot.hasData}, '
              'error=${snapshot.error}, '
              'dataLength=${snapshot.data?.length ?? 0}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading(context);
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar comercios:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final all = snapshot.data!;
          print('✅ [HomePage] Rendering UI with ${all.length} items');
          final cercaDeTi = _randomSubset(all, 5);
          final masGustados = _randomSubset(all, 5);
          final tusMeGusta = _randomSubset(all, 5);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: "Cerca de ti",
                      list: cercaDeTi,
                      icon: Icons.location_on_outlined,
                      accentColor: Colors.blue,
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      title: "Más Gustados",
                      list: masGustados,
                      icon: Icons.favorite_outline,
                      accentColor: Colors.red,
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      title: "Tus Me Gusta",
                      list: tusMeGusta,
                      icon: Icons.thumb_up_outlined,
                      accentColor: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando comercios...',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay comercios disponibles',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta de nuevo más tarde',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );

  Widget _buildSection({
    required String title,
    required List<Commerce> list,
    required IconData icon,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 16),
        _buildCarousel(list, accentColor),
      ],
    );
  }

  Widget _buildCarousel(List<Commerce> list, Color accentColor) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 4),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final commerce = list[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => widget.onCommerceTap(commerce),
              child: Hero(
                tag: 'commerce-${commerce.id}',
                child: _buildCard(
                  commerce.name,
                  '${commerce.city} / ${commerce.state}',
                  commerce.images.isNotEmpty ? commerce.images.first : '',
                  accentColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    String name,
    String cityState,
    String imageUrl,
    Color accentColor,
  ) {
    final imageProvider = imageUrl.startsWith('http')
        ? NetworkImage(imageUrl)
        : const AssetImage('assets/placeholder.png');
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.white.withOpacity(0.9)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cityState,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
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
}
