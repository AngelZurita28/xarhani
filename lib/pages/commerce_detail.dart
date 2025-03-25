import 'package:flutter/material.dart';

class CommerceDetailPage extends StatelessWidget {
  final String nombre;
  final String categoria;
  final String descripcion;
  final String imagen;

  const CommerceDetailPage({
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.imagen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  imagen,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(categoria,
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 16),
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    fillColor: Colors.purple,
                    children: [Text("Información"), Text("Productos")],
                    isSelected: [true, false],
                    onPressed: (index) {},
                  ),
                  SizedBox(height: 16),
                  Text(descripcion, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
