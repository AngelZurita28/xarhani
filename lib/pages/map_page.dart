import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/commerce_service.dart';
import '../models/commerce.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  // Colores del esquema definido
  static const Color primary = Color(0xFFFFB400);
  static const Color primaryHover = Color(0xFFE6A800);
  static const Color secondary = Color(0xFFFFC333);
  static const Color complement = Color(0xFF0057D9);
  static const Color success = Color(0xFF30BFBF);
  static const Color bgPrimary = Color(0xFFF6F6F6);
  static const Color bgSecondary = Color(0xFFECECEC);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF2C2C2C);
  static const Color disabled = Color(0xFFCCCCCC);

  bool _loading = true;
  bool _permissionGranted = false;
  LatLng? _userLatLng;
  GoogleMapController? _mapController;

  final CommerceService _commerceService = CommerceService();
  late List<Commerce> _allCommerces;
  final Set<Marker> _markers = {};

  // Cache para los íconos personalizados
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  // Para la vista previa flotante
  Commerce? _selectedCommerce;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndData() async {
    // 1) Pedir permiso y posición
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

    // 2) Cargar todos los comercios
    _allCommerces = await _commerceService.fetchCommerces();

    setState(() => _loading = false);
  }

  void _updateMarkers() async {
    if (_mapController == null) return;
    // 1) Obtener región visible
    final bounds = await _mapController!.getVisibleRegion();
    // 2) Calcular padding del 20%
    final latDelta =
        (bounds.northeast.latitude - bounds.southwest.latitude) * 0.2;
    final lngDelta =
        (bounds.northeast.longitude - bounds.southwest.longitude) * 0.2;
    final paddedSW = LatLng(
      bounds.southwest.latitude - latDelta,
      bounds.southwest.longitude - lngDelta,
    );
    final paddedNE = LatLng(
      bounds.northeast.latitude + latDelta,
      bounds.northeast.longitude + lngDelta,
    );

    // 3) Filtrar comercios dentro del paddedBounds
    final visible = _allCommerces.where((c) {
      final lat = c.latitude;
      final lng = c.longitude;
      return lat >= paddedSW.latitude &&
          lat <= paddedNE.latitude &&
          lng >= paddedSW.longitude &&
          lng <= paddedNE.longitude;
    });

    // 4) Crear marcadores con íconos personalizados
    final newMarkers = <Marker>{};
    for (final commerce in visible) {
      final icon = await _getCustomMarkerIcon(commerce);
      newMarkers.add(
        Marker(
          markerId: MarkerId(commerce.id),
          position: LatLng(commerce.latitude, commerce.longitude),
          icon: icon,
          onTap: () => _showCommercePreview(commerce),
        ),
      );
    }

    // 5) Actualizar estado
    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  Future<BitmapDescriptor> _getCustomMarkerIcon(Commerce commerce) async {
    // Verificar cache primero
    if (_markerIconCache.containsKey(commerce.id)) {
      return _markerIconCache[commerce.id]!;
    }

    try {
      BitmapDescriptor icon;
      if (commerce.images.isNotEmpty) {
        // Crear ícono con imagen del comercio
        icon = await _createCustomMarkerFromImage(commerce.images.first);
      } else {
        // Crear ícono por defecto
        icon = await _createDefaultMarkerIcon();
      }

      // Guardar en cache
      _markerIconCache[commerce.id] = icon;
      return icon;
    } catch (e) {
      print('❌ Error creando ícono personalizado: $e');
      // Fallback al ícono por defecto
      return await _createDefaultMarkerIcon();
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerFromImage(String imageUrl) async {
    try {
      // Descargar la imagen
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return await _createDefaultMarkerIcon();
      }

      // Decodificar imagen
      final codec = await ui.instantiateImageCodec(
        response.bodyBytes,
        targetWidth: 120,
        targetHeight: 120,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Crear canvas para el marcador personalizado
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 100.0;

      // Dibujar fondo usando color primary
      final bgPaint = Paint()
        ..color = primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        bgPaint,
      );

      // Dibujar borde blanco
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 1.5,
        borderPaint,
      );

      // Clip circular para la imagen
      final clipPath = Path()
        ..addOval(Rect.fromCircle(
          center: const Offset(size / 2, size / 2),
          radius: size / 2 - 6,
        ));
      canvas.clipPath(clipPath);

      // Dibujar imagen
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(6, 6, size - 12, size - 12),
        Paint(),
      );

      // Convertir a bytes
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('❌ Error procesando imagen: $e');
      return await _createDefaultMarkerIcon();
    }
  }

  Future<BitmapDescriptor> _createDefaultMarkerIcon() async {
    // Crear ícono por defecto con color complement
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 100.0;

    // Fondo circular usando color complement
    final bgPaint = Paint()
      ..color = complement
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      bgPaint,
    );

    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 1.5,
      borderPaint,
    );

    // Ícono de tienda (dibujo simple)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Dibujar ícono de tienda simple
    final storePath = Path();
    const center = size / 2;
    const iconSize = 20.0;

    // Base de la tienda
    storePath.addRect(Rect.fromCenter(
      center: const Offset(center, center + 2),
      width: iconSize,
      height: iconSize * 0.7,
    ));

    // Techo triangular
    storePath.moveTo(center - iconSize / 2, center - iconSize / 4);
    storePath.lineTo(center, center - iconSize / 2);
    storePath.lineTo(center + iconSize / 2, center - iconSize / 4);
    storePath.close();

    canvas.drawPath(storePath, iconPaint);

    // Convertir a bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  void _showCommercePreview(Commerce commerce) {
    setState(() {
      _selectedCommerce = commerce;
    });
    _animationController.forward();
  }

  void _hideCommercePreview() {
    _animationController.reverse().then((_) {
      setState(() {
        _selectedCommerce = null;
      });
    });
  }

  void _goToCommerceDetail() {
    if (_selectedCommerce != null) {
      Navigator.of(context).pushNamed('/detail', arguments: _selectedCommerce);
    }
  }

  Widget _buildCommercePreviewCard() {
    if (_selectedCommerce == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 300),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del comercio
            if (_selectedCommerce!.images.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  _selectedCommerce!.images.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: bgSecondary,
                      child: Icon(
                        Icons.store,
                        size: 64,
                        color: disabled,
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón de cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCommerce!.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _hideCommercePreview,
                        icon: Icon(
                          Icons.close,
                          color: textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Ubicación
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: complement,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_selectedCommerce!.city}, ${_selectedCommerce!.state}',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Descripción (truncada)
                  if (_selectedCommerce!.description.isNotEmpty)
                    Text(
                      _selectedCommerce!.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _hideCommercePreview,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primary),
                            foregroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _goToCommerceDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Ver detalles'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: bgPrimary,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
      );
    }

    if (!_permissionGranted || _userLatLng == null) {
      return Scaffold(
        backgroundColor: bgPrimary,
        appBar: AppBar(
          title: Text(
            'Permiso de ubicación',
            style: TextStyle(color: textPrimary),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: disabled,
                ),
                const SizedBox(height: 24),
                Text(
                  'Necesitamos acceso a tu ubicación para mostrar comercios cerca de ti',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _initLocationAndData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Conceder permiso de ubicación'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLatLng!,
              zoom: 13,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              // Llenar marcadores iniciales
              _updateMarkers();
            },
            onCameraIdle: _updateMarkers,
            onTap: (_) {
              // Ocultar vista previa al tocar el mapa
              if (_selectedCommerce != null) {
                _hideCommercePreview();
              }
            },
          ),

          // Vista previa flotante
          if (_selectedCommerce != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCommercePreviewCard(),
            ),
        ],
      ),
    );
  }
}
