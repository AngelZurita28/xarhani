import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class CommerceDetailContent extends StatefulWidget {
  final Map<String, dynamic> commerce;

  const CommerceDetailContent({super.key, required this.commerce});

  @override
  _CommerceDetailContentState createState() => _CommerceDetailContentState();
}

class _CommerceDetailContentState extends State<CommerceDetailContent> {
  int _selectedTab = 0;
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  List<Map<String, dynamic>> _products = [];
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final String commerceId = widget.commerce['id'];
      final isFavorite = await _userService.isCommerceFavorite(commerceId);

      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Error al verificar favorito: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userService.currentUser == null) {
      // Usuario no autenticado, mostrar diálogo
      _showLoginDialog();
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final String commerceId = widget.commerce['id'];

      if (_isFavorite) {
        await _userService.removeFromFavorites(commerceId);
      } else {
        await _userService.addToFavorites(commerceId);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Error al cambiar favorito: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se pudo actualizar favoritos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Iniciar sesión requerido'),
        content: Text('Debes iniciar sesión para guardar comercios favoritos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/login');
            },
            child: Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  // Nueva función para abrir imagen en pantalla completa
  void _openFullScreenImage(List<dynamic> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _loadProducts() async {
    try {
      final String id = widget.commerce['id'];
      final snapshot = await FirebaseFirestore.instance
          .collection('commerce')
          .doc(id)
          .collection('product')
          .get();

      final products = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Error al cargar productos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.commerce['images'] ?? [];
    final String name = widget.commerce['name'] ?? '';
    final String city = widget.commerce['city'] ?? '';
    final String state = widget.commerce['state'] ?? '';
    final String description = widget.commerce['description'] ?? '';
    final String history = widget.commerce['history'] ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            // Carrusel con botón de favorito
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      return Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _openFullScreenImage(images, index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 12 : 8,
                          height: isActive ? 12 : 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.purple : Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),

                  // Botón de favoritos
                  Positioned(
                    top: 12,
                    right: 24,
                    child: Material(
                      elevation: 4,
                      shape: CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      color: Colors.white,
                      child: InkWell(
                        onTap: _isLoadingFavorite ? null : _toggleFavorite,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: _isLoadingFavorite
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.purple,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isFavorite ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Padding(
              padding: EdgeInsets.fromLTRB(25, 20, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("$city / $state",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  SizedBox(height: 24),

                  // Tabs
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 195, 51, 0.40),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Información', 0),
                        _buildTabButton('Productos', 1),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Secciones
                  _selectedTab == 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(description,
                                style: TextStyle(fontSize: 16, height: 1.5)),
                            SizedBox(height: 16),
                            Text("Historia",
                                style: TextStyle(fontSize: 25, height: 1.5)),
                            SizedBox(height: 12),
                            Text(history,
                                style: TextStyle(fontSize: 16, height: 1.5)),
                          ],
                        )
                      : _buildProductList(),
                ],
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return Text(
        "Este comercio aún no tiene productos.",
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      );
    }

    return Column(
      children: _products.map((product) {
        final String name = product['name'] ?? 'Producto sin nombre';
        final double price = (product['price'] ?? 0).toDouble();

        return Padding(
          padding: EdgeInsets.only(bottom: 16), // Separación entre tarjetas
          child: Container(
            padding: EdgeInsets.all(12), // Espacio interno
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFFFC333), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🡐 Texto (nombre + precio)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "\$${price.toStringAsFixed(2)}",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // 🡒 Imagen a la derecha
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.containsKey('image') &&
                          product['image'] != null &&
                          product['image'].toString().isNotEmpty
                      ? Image.network(
                          product['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/icon.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/icon.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final isSelected = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabIndex;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : const Color.fromARGB(0, 255, 255, 255),
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(Icons.check,
                    size: 16, color: const Color.fromARGB(255, 29, 29, 29)),
              if (isSelected) SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color.fromARGB(255, 28, 28, 28)
                      : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nueva clase para el visor de imágenes en pantalla completa
class FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111111).withOpacity(0.95),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Imagen principal con PageView
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  panEnabled: false,
                  boundaryMargin: EdgeInsets.all(40),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 32,
                            spreadRadius: 0,
                            offset: Offset(0, 16),
                          ),
                          BoxShadow(
                            color: Color(0xFFffb400).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: -4,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xFFf6f6f6).withOpacity(0.1),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Image.network(
                            widget.images[index],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Color(0xFF111111),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          color: Color(0xFFffb400),
                                          strokeWidth: 3,
                                          backgroundColor: Color(0xFFf6f6f6)
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Cargando imagen...',
                                        style: TextStyle(
                                          color: Color(0xFFf6f6f6)
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Color(0xFF111111),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFf6f6f6)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(32),
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Color(0xFFf6f6f6)
                                              .withOpacity(0.6),
                                          size: 32,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Error al cargar imagen',
                                        style: TextStyle(
                                          color: Color(0xFFf6f6f6)
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Controles superiores
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF111111).withOpacity(0.8),
                        Color(0xFF111111).withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.7, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botón de cerrar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(0xFFf6f6f6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Color(0xFFf6f6f6).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => Navigator.of(context).pop(),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFf6f6f6),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Contador de imágenes
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF111111).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFFffb400).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${_currentIndex + 1} de ${widget.images.length}',
                              style: TextStyle(
                                color: Color(0xFFf6f6f6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Indicadores de página (puntos)
            if (_showControls && widget.images.length > 1)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      width: isActive ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Color(0xFFffb400)
                            : Color(0xFFf6f6f6).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Color(0xFFffb400).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
