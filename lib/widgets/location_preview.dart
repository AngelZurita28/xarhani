import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ui/app_colors.dart';

/// Muestra una previsualización de ubicación y abre Google Maps al pulsar.
class LocationPreview extends StatelessWidget {
  /// Cadena: "lat,lng", URL de Google Maps(DynamicLink) o texto libre.
  final String ubication;

  const LocationPreview({Key? key, required this.ubication}) : super(key: key);

  /// Intenta extraer lat,lng de formatos directos o URLs de Maps.
  LatLng? get _coords {
    try {
      final direct = RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*\$');
      if (direct.hasMatch(ubication.trim())) {
        final parts = ubication.split(',');
        return LatLng(double.parse(parts[0]), double.parse(parts[1]));
      }
      final reg = RegExp(r'[@&](-?\d+\.?\d*),(-?\d+\.?\d*)');
      final match = reg.firstMatch(ubication);
      if (match != null) {
        return LatLng(
            double.parse(match.group(1)!), double.parse(match.group(2)!));
      }
    } catch (_) {}
    return null;
  }

  /// URL estática de Google Static Maps (requiere API key)
  String get _staticMapUrl {
    final coords = _coords;
    if (coords == null) return '';
    const key = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (key.isEmpty) return '';
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=${coords.latitude},${coords.longitude}'
        '&zoom=15&size=600x300&markers=color:0xFFFFB400|${coords.latitude},${coords.longitude}'
        '&key=$key';
  }

  /// Construye la URI para lanzar navegación nativa o web.
  Uri _buildLaunchUri() {
    final coords = _coords;
    // Si es DynamicLink de Maps, usar directamente
    if (ubication.startsWith('http') && ubication.contains('maps.app.goo.gl')) {
      return Uri.parse(ubication);
    }
    if (coords != null) {
      // Intentar esquema google.navigation
      return Uri.parse(
          'google.navigation:q=${coords.latitude},${coords.longitude}');
    }
    // Fallback: búsqueda web
    return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(ubication)}');
  }

  Future<void> _launchMaps() async {
    try {
      final uri = _buildLaunchUri();
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching Maps: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapUrl = _staticMapUrl;
    return GestureDetector(
      onTap: () async {
        final open = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Abrir en Google Maps'),
            content: const Text('¿Deseas abrir la ubicación en Google Maps?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Abrir')),
            ],
          ),
        );
        if (open == true) await _launchMaps();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: mapUrl.isNotEmpty
            ? Image.network(
                mapUrl,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 200,
        color: AppColors.bgSecondary,
        child: const Center(
          child: Icon(Icons.map_outlined, size: 48, color: AppColors.disabled),
        ),
      );
}

/// Helper para coordenadas.
class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}
