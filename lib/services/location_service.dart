import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Structure encapsulant une position GPS avec adresse lisible
class UserLocation {
  final double latitude;
  final double longitude;
  final String address;
  final bool isFallback; // true si le GPS n'a pas pu être résolu

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isFallback = false,
  });
}

/// Service de Géolocalisation Automatique avec Fallbacks sécurisés.
/// L'application est volontairement limitée à Antananarivo (Madagascar).
class LocationService {
  // Position centrale d'Antananarivo, Madagascar
  static const double defaultLat = -18.8792;
  static const double defaultLng = 47.5079;
  static const String defaultAddress = "Antananarivo, Madagascar";

  // Limites officieuses de la Commune Urbaine d'Antananarivo
  static const double minLat = -19.10;
  static const double maxLat = -18.72;
  static const double minLng = 47.36;
  static const double maxLng = 47.66;

  /// Vérifie qu'un point GPS se trouve dans la zone d'Antananarivo.
  static bool isWithinAntananarivo(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Obtient la position GPS actuelle de l'utilisateur avec demande d'autorisation.
  /// Si le GPS est indisponible, retourne la position par défaut (Antananarivo).
  static Future<UserLocation> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallback();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallback();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallback();
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      // Règle d'Antananarivo : si la position dépasse la zone, on se recentre
      // sur la ville afin de garantir des données locales cohérentes.
      if (!isWithinAntananarivo(position.latitude, position.longitude)) {
        return UserLocation(
          latitude: defaultLat,
          longitude: defaultLng,
          address: defaultAddress,
          isFallback: true,
        );
      }

      String resolvedAddress = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: resolvedAddress,
      );
    } catch (e) {
      return _fallback();
    }
  }

  static UserLocation _fallback() {
    return UserLocation(
      latitude: defaultLat,
      longitude: defaultLng,
      address: defaultAddress,
      isFallback: true,
    );
  }

  /// Géocodage inverse : convertit (lat, lng) en adresse lisible
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> parts = [
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
        ];
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (e) {
      // Géocodage indisponible : on conserve les coordonnées brutes.
    }
    return "Antananarivo - Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}";
  }
}