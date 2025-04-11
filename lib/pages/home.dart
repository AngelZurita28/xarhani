import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String rawData =
      "1|Myrna Restaurante|Cocina, Tradicional|Lorem ipsum dolor sit amet...|myra.jpg|2|La Cocina de Martita|Cocina, Tradicional|Lorem ipsum dolor sit amet...|martita.jpg";

  List<Map<String, String>> parseData(String rawData) {
    List<Map<String, String>> negocios = [];
    List<String> parts = rawData.split("|");
    // Cada negocio tiene 5 campos, así que incrementamos de 5 en 5
    for (int i = 0; i < parts.length; i += 5) {
      if (i + 4 < parts.length) {
        negocios.add({
          "id": parts[i],
          "nombre": parts[i + 1],
          "categoria": parts[i + 2],
          "descripcion": parts[i + 3],
          "imagen": parts[i + 4],
        });
      }
    }
    return negocios;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> negocios = parseData(rawData);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cerca de ti",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildCarousel(negocios),
            SizedBox(height: 16),
            Text("Más Gustados",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildCarousel(negocios),
            SizedBox(height: 16),
            Text("Tus Me Gusta",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildCarousel(negocios),
            SizedBox(height: 180),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(List<Map<String, String>> negocios) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: negocios.length,
        itemBuilder: (context, index) {
          return _buildCard(
            negocios[index]["nombre"]!,
            negocios[index]["categoria"]!,
            negocios[index]["imagen"]!,
          );
        },
      ),
    );
  }

  Widget _buildCard(String nombre, String categoria, String imagen) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagen),
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
            colors: [Colors.black.withAlpha(50), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(categoria,
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
