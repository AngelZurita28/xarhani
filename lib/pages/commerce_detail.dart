import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommerceDetailContent extends StatefulWidget {
  final Map<String, dynamic> commerce;

  const CommerceDetailContent({Key? key, required this.commerce})
      : super(key: key);

  @override
  _CommerceDetailContentState createState() => _CommerceDetailContentState();
}

class _CommerceDetailContentState extends State<CommerceDetailContent> {
  int _selectedTab = 0;
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

            // Carrusel
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
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
              color: Color(0xf8fff8e1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Color(0xf6ffc333), width: 1.2), // ✅ Borde
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
                  child: Image.asset(
                    'assets/xarhani-logo.png',
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
