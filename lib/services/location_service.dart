import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Default Fallback: Naval, Biliran, Philippines
  static const LatLng defaultLocation = LatLng(11.5606, 124.3986);

  // Fetch real device GPS coordinates
  Future<LatLng> getCurrentDeviceLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled. Using default location.');
        }
        return defaultLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied. Using default location.');
          }
          return defaultLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions permanently denied. Using default location.');
        }
        return defaultLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device location: $e. Falling back to default.');
      }
      return defaultLocation;
    }
  }
}
