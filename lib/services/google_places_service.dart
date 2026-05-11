import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GooglePlacesService {
  static const String _apiKey = 'AIzaSyCTZlFTsXe-3_sVAT0hKt7Uq_DEu7Zzczg';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Singleton pattern
  static final GooglePlacesService _instance = GooglePlacesService._internal();
  factory GooglePlacesService() => _instance;
  GooglePlacesService._internal();

  // Check and request location permission using Geolocator only
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  // Search places with autocomplete
  Future<List<PlacePrediction>> searchPlaces(
    String query, {
    String? sessionToken,
    Position? currentLocation,
  }) async {
    if (query.isEmpty) return [];

    try {
      String locationBias = '';
      if (currentLocation != null) {
        locationBias =
            '&location=${currentLocation.latitude},${currentLocation.longitude}&radius=50000';
      }

      final url = Uri.parse(
        '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(query)}'
        '&key=$_apiKey'
        '&components=country:bd' // Bangladesh
        '&types=geocode|establishment'
        '$locationBias'
        '${sessionToken != null ? '&sessiontoken=$sessionToken' : ''}',
      );

      final response = await http.get(url);
      print('Places autocomplete response: ${response.body}'); // DEBUG PRINT

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else if (data['status'] == 'REQUEST_DENIED') {
          print(
            'REQUEST_DENIED: ${data['error_message']} - Check billing/API key',
          );
          return [];
        } else {
          print(
            'Places API Error: ${data['status']} - ${data['error_message'] ?? ''}',
          );
          return [];
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    }
    return [];
  }

  // Get place details by place ID
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId'
        '&key=$_apiKey'
        '&fields=formatted_address,geometry,name,place_id,address_components'
        '${sessionToken != null ? '&sessiontoken=$sessionToken' : ''}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
    return null;
  }

  // Get current location with improved error handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Try to get current position with better settings
      try {
        // First try: High accuracy with longer timeout
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
        );
      } catch (e) {
        print('Error getting high accuracy location: $e');
        // Fallback to best accuracy
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 30),
          );
        } catch (e2) {
          print('Error getting best accuracy location: $e2');
          // Fallback to medium accuracy
          try {
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 20),
            );
          } catch (e3) {
            print('Error getting medium accuracy location: $e3');
            // Final fallback to low accuracy
            try {
              return await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: const Duration(seconds: 15),
              );
            } catch (e4) {
              print('Error getting low accuracy location: $e4');
              // Last resort: get last known position
              final lastPosition = await Geolocator.getLastKnownPosition();
              if (lastPosition != null) {
                print('Using last known location');
                return lastPosition;
              }
              return null;
            }
          }
        }
      }
    } catch (e) {
      print('Error in getCurrentLocation: $e');
      return null;
    }
  }

  // Get last known location (faster)
  Future<Position?> getLastKnownLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  // Get position using location stream for best accuracy
  Future<Position?> getPositionWithStream({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        return null;
      }

      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('No location permission');
        return null;
      }

      // Get the position stream and take the first accurate position
      final positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // Emit all position updates
          timeLimit: Duration(seconds: 30),
        ),
      );

      Position? bestPosition;
      double bestAccuracy = double.infinity;

      await for (final position in positionStream.take(1)) {
        if (position.accuracy < bestAccuracy) {
          bestAccuracy = position.accuracy;
          bestPosition = position;
          print('Got position with accuracy: ${position.accuracy}m');
          break; // Take first position and break
        }
      }

      return bestPosition;
    } catch (e) {
      print('Error in getPositionWithStream: $e');
      return null;
    }
  }

  // Reverse geocoding - get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=$lat,$lng'
        '&key=$_apiKey'
        '&language=en',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }

  // Get distance between two points
  Future<DistanceInfo?> getDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      print(
        'Distance API Called: origin($originLat, $originLng) -> dest($destLat, $destLng)',
      );

      // Try API first
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=$originLat,$originLng'
        '&destinations=$destLat,$destLng'
        '&key=$_apiKey'
        '&units=metric',
      );

      final response = await http.get(url);
      print('Distance API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Distance API Response: ${data['status']}');

        if (data['status'] == 'OK') {
          final elements = data['rows'][0]['elements'][0];
          if (elements['status'] == 'OK') {
            return DistanceInfo(
              distanceText: elements['distance']['text'],
              distanceValue: elements['distance']['value'],
              durationText: elements['duration']['text'],
              durationValue: elements['duration']['value'],
            );
          } else {
            print('API returned element status: ${elements['status']}');
          }
        }
      }

      // Fallback: Use Haversine formula to calculate distance
      print('Falling back to Haversine distance calculation');
      return _calculateDistanceHaversine(
        originLat,
        originLng,
        destLat,
        destLng,
      );
    } catch (e) {
      print('Error getting distance: $e');
      // Fallback to Haversine calculation on error
      return _calculateDistanceHaversine(
        originLat,
        originLng,
        destLat,
        destLng,
      );
    }
  }

  // Haversine formula to calculate distance between two coordinates
  DistanceInfo? _calculateDistanceHaversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    try {
      const double earthRadiusKm = 6371.0;

      double dLat = _toRadian(lat2 - lat1);
      double dLon = _toRadian(lon2 - lon1);

      double a =
          (math.sin(dLat / 2) * math.sin(dLat / 2)) +
          math.cos(_toRadian(lat1)) *
              math.cos(_toRadian(lat2)) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);

      double c = 2 * math.asin(math.sqrt(a));
      double distanceKm = earthRadiusKm * c;
      int distanceMeters = (distanceKm * 1000).toInt();

      // Estimate duration (assuming average speed of 20 km/h for Rajshahi traffic)
      double estimatedMinutes = (distanceKm / 20) * 60;
      int durationSeconds = (estimatedMinutes * 60).toInt();

      String distanceText = distanceKm < 1
          ? '${(distanceKm * 1000).toStringAsFixed(0)}m'
          : '${distanceKm.toStringAsFixed(1)} km';

      String durationText = estimatedMinutes < 1
          ? '1 min'
          : estimatedMinutes.toInt() > 60
          ? '${(estimatedMinutes / 60).toStringAsFixed(0)} h ${(estimatedMinutes % 60).toInt()} min'
          : '${estimatedMinutes.toStringAsFixed(0)} min';

      print('Haversine Distance: $distanceText, Duration: $durationText');

      return DistanceInfo(
        distanceText: distanceText,
        distanceValue: distanceMeters,
        durationText: durationText,
        durationValue: durationSeconds,
      );
    } catch (e) {
      print('Error in Haversine calculation: $e');
      return null;
    }
  }

  double _toRadian(double degree) {
    return degree * (3.14159265359 / 180);
  }

  // Calculate delivery price based on distance
  double calculateDeliveryPrice(int distanceInMeters, String packageSize) {
    double basePrice = 50.0; // Base price in BDT
    double perKmRate = 20.0; // Per kilometer rate (updated)

    // Package size multiplier
    double sizeMultiplier = 1.0;
    switch (packageSize.toLowerCase()) {
      case 'small':
        sizeMultiplier = 1.0;
        break;
      case 'medium':
        sizeMultiplier = 1.5;
        break;
      case 'large':
        sizeMultiplier = 2.0;
        break;
    }

    // Prevent division by zero and negative values
    double distanceKm = (distanceInMeters > 0)
        ? (distanceInMeters / 1000)
        : 0.0;
    double price = basePrice + (distanceKm * perKmRate * sizeMultiplier);

    // If distance is zero, set minimum price
    if (distanceKm == 0) {
      price = basePrice;
    }

    return double.parse(price.toStringAsFixed(2));
  }
}

// Models
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? distanceMeters;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.distanceMeters,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
      distanceMeters: json['distance_meters']?.toDouble(),
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;
  final List<AddressComponent> addressComponents;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    required this.addressComponents,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    final components = json['address_components'] as List? ?? [];

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      lat: (location['lat'] ?? 0).toDouble(),
      lng: (location['lng'] ?? 0).toDouble(),
      addressComponents: components
          .map((c) => AddressComponent.fromJson(c))
          .toList(),
    );
  }
}

class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] ?? '',
      shortName: json['short_name'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

class DistanceInfo {
  final String distanceText;
  final int distanceValue; // in meters
  final String durationText;
  final int durationValue; // in seconds

  DistanceInfo({
    required this.distanceText,
    required this.distanceValue,
    required this.durationText,
    required this.durationValue,
  });
}

// Location model for storing selected locations
class SelectedLocation {
  final String address;
  final String name;
  final double lat;
  final double lng;
  final String? placeId;

  SelectedLocation({
    required this.address,
    required this.name,
    required this.lat,
    required this.lng,
    this.placeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'name': name,
      'lat': lat,
      'lng': lng,
      'placeId': placeId,
    };
  }

  factory SelectedLocation.fromMap(Map<String, dynamic> map) {
    return SelectedLocation(
      address: map['address'] ?? '',
      name: map['name'] ?? '',
      lat: map['lat'] ?? 0.0,
      lng: map['lng'] ?? 0.0,
      placeId: map['placeId'],
    );
  }
}
