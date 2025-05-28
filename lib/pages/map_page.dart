import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // 1) Pedir permiso “when in use”
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      setState(() {
        _permissionGranted = false;
        _loading = false;
      });
      return;
    }

    // 2) Obtener última posición conocida (o current)
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _permissionGranted = true;
      _userLatLng = LatLng(pos.latitude, pos.longitude);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Spinner mientras pedimos permiso y geolocalizamos
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_permissionGranted || _userLatLng == null) {
      // Si no dio permiso
      return Scaffold(
        appBar: AppBar(title: const Text('Permiso de ubicación')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _loading = true;
              });
              _initLocation();
            },
            child: const Text('Conceder permiso de ubicación'),
          ),
        ),
      );
    }

    // Permiso concedido y tenemos ubicación: mostrar mapa centrado
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _userLatLng!,
          zoom: 16,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (ctrl) {
          _mapController = ctrl;
        },
      ),
    );
  }
}
