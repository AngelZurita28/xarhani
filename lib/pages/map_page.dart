import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../services/commerce_service.dart';
import '../models/commerce.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _loading = true;
  bool _permissionGranted = false;
  LatLng? _userLatLng;
  GoogleMapController? _mapController;
  final CommerceService _commerceService = CommerceService();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      setState(() {
        _permissionGranted = false;
        _loading = false;
      });
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _userLatLng = LatLng(pos.latitude, pos.longitude);
    _permissionGranted = true;

    // Cargar comercios
    await _loadCommerces();

    setState(() => _loading = false);
  }

  Future<void> _loadCommerces() async {
    final commerces = await _commerceService.fetchCommerces();

    // Solo para prueba: usa coordenadas inventadas si no vienen en el modelo
    final dummyCoordinates = [
      LatLng(25.4389, -100.9736), // Monclova
      LatLng(25.5700, -100.9500), // Frontera
      LatLng(25.5000, -100.9700), // Castaños
      LatLng(25.4100, -101.0000), // Monclova otra
      LatLng(25.5800, -101.0100), // Frontera otra
    ];

    for (int i = 0; i < commerces.length && i < 5; i++) {
      final commerce = commerces[i];
      _markers.add(Marker(
        markerId: MarkerId(commerce.id),
        position: dummyCoordinates[i], // Asignación manual por ahora
        infoWindow: InfoWindow(title: commerce.name),
        onTap: () {
          Navigator.of(context).pushNamed('/detail', arguments: commerce);
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_permissionGranted || _userLatLng == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permiso de ubicación')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() => _loading = true);
              _initLocation();
            },
            child: const Text('Conceder permiso de ubicación'),
          ),
        ),
      );
    }

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _userLatLng!,
          zoom: 13,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        onMapCreated: (ctrl) => _mapController = ctrl,
      ),
    );
  }
}

