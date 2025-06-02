import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ui/app_colors.dart';

/// Widget que muestra un placeholder animado con una imagen de fondo desenfocada
/// y un indicador para abrir la ubicación en Google Maps al pulsar.
class LocationPreview extends StatefulWidget {
  /// Cadena: "lat,lng", URL de Google Maps o dirección textual.
  final String ubication;

  const LocationPreview({Key? key, required this.ubication}) : super(key: key);

  @override
  _LocationPreviewState createState() => _LocationPreviewState();
}

class _LocationPreviewState extends State<LocationPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Extrae coordenadas directas "lat,lng".
  LatLng? get _coords {
    try {
      final direct = RegExp(r'^-?\d+\.\d+,-?\d+\.\d+$');
      if (direct.hasMatch(widget.ubication.trim())) {
        final parts = widget.ubication.split(',');
        return LatLng(
          double.parse(parts[0].trim()),
          double.parse(parts[1].trim()),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Construye la URI para navegación nativa o búsqueda web.
  Uri _buildLaunchUri() {
    final coords = _coords;
    if (coords != null) {
      return Uri.parse(
          'google.navigation:q=${coords.latitude},${coords.longitude}');
    }
    if (widget.ubication.startsWith('http')) {
      return Uri.parse(widget.ubication);
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.ubication)}',
    );
  }

  /// Muestra diálogo y abre Google Maps.
  void _launchMaps() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Abrir en Google Maps',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('¿Deseas abrir la ubicación en Google Maps?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    ).then((open) {
      if (open == true) {
        final uri = _buildLaunchUri();
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchMaps,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                // Fondo desenfocado
                Positioned.fill(
                  child: Image.asset(
                    'assets/map-background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                        color: const Color.fromARGB(255, 249, 249, 249)
                            .withOpacity(0)),
                  ),
                ),
                // Contenido central
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseController,
                        child: SizedBox(
                          height: 100,
                          width: 100,
                          child: Lottie.asset(
                            'assets/animations/pin-drop.json',
                            repeat: true,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _coords != null
                              ? 'Toca para abrir la ubicación en Maps'
                              : 'Toca para buscar esta dirección en Maps',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modelo de coordenadas.
class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}
