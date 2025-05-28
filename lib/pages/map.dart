import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _permissionGranted = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.location.request();

    setState(() {
      _checkingPermission = false;
      _permissionGranted = status == PermissionStatus.granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _permissionGranted
          ? const GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(25.4389, -100.9736),
                zoom: 12,
              ),
            )
          : const Center(
              child: Text(
                'Se necesita el permiso de ubicación para mostrar el mapa.',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
