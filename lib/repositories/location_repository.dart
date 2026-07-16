import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import 'package:geocoding/geocoding.dart';

class LocationRepository {
  Future<LocationData> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Enable GPS in device settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Enable it in device Settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    final position = await Geolocator.getCurrentPosition();

    String? city;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      city = placemarks.firstOrNull?.locality;
    } catch (_) {
      // Reverse geocoding is best-effort — city stays null if offline or unavailable
    }

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
    );
  }
}
