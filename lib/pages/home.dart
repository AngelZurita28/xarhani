import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  // Modificado: ahora también incluye el 'id' del documento
  Future<List<Map<String, dynamic>>> fetchCommerce() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('commerce').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // ✅ Agrega el ID del documento
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCommerce(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay datos disponibles'));
          }

          final commerceList = snapshot.data!;
          return Stack(
            children: [
              // Contenido principal desplazable detrás de la barra
              SingleChildScrollView(
                padding: EdgeInsets.only(top: 80, left: 15, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 18),
                    Text("Cerca de ti",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _buildCarousel(context, commerceList),
                    SizedBox(height: 16),
                    Text("Más Gustados",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _buildCarousel(context, commerceList),
                    SizedBox(height: 16),
                    Text("Tus Me Gusta",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _buildCarousel(context, commerceList),
                    SizedBox(height: 35),
                  ],
                ),
              ),

              // Barra flotante de búsqueda
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(236, 255, 255, 255),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12),
                        Icon(Icons.menu, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              hintText: 'Buscar Productos...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCarousel(
      BuildContext context, List<Map<String, dynamic>> commerceList) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: commerceList.length,
        itemBuilder: (context, index) {
          final item = commerceList[index];
          final name = item['name'] ?? '';
          final city = item['city'] ?? '';
          final state = item['state'] ?? '';
          final imageUrl = item['image'] ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/detail', arguments: item);
            },
            child: _buildCard(name, "$city / $state", imageUrl),
          );
        },
      ),
    );
  }

  Widget _buildCard(String name, String cityState, String imageUrl) {
    final String heroTag = 'commerce-$name'; // Puedes usar item['id'] si deseas

    return Hero(
      tag: heroTag,
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: imageUrl.startsWith('http')
                ? NetworkImage(imageUrl)
                : AssetImage(imageUrl) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: EdgeInsets.only(left: 15, bottom: 15),
          alignment: Alignment.bottomLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withAlpha(100), Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(cityState,
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
