// providers/health_tips_providers.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

final locationProvider = FutureProvider<LocationData?>((ref) async {
  final location = Location();
  try {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    return await location.getLocation();
  } catch (e) {
    print('Error getting location: $e');
    return null;
  }
});

final placeTypeProvider = StateProvider<String>((ref) => 'veterinary_care');

final markersProvider = StateNotifierProvider<MarkersNotifier, Set<Marker>>(
  (ref) => MarkersNotifier(ref),
);

class MarkersNotifier extends StateNotifier<Set<Marker>> {
  final Ref ref;
  MarkersNotifier(this.ref) : super({});

  void addUserMarker(LatLng position) {
    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: position,
      infoWindow: const InfoWindow(title: 'Konumunuz'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    state = {userMarker};
  }

  void clearMarkers() {
    state = {};
  }

  void addPlaceMarkers(Set<Marker> newMarkers) {
    state = {...state, ...newMarkers};
  }
}

final nearbyPlacesProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  placeType,
) async {
  final location = await ref.watch(locationProvider.future);
  if (location == null) return;

  final markersNotifier = ref.read(markersProvider.notifier);
  final currentMarkers = ref.read(markersProvider);

  // Keep user marker if exists
  final userMarker = currentMarkers.firstWhere(
    (m) => m.markerId == const MarkerId('user_location'),
    orElse: () =>
        Marker(markerId: const MarkerId('empty'), position: const LatLng(0, 0)),
  );

  markersNotifier.clearMarkers();
  if (userMarker.markerId != const MarkerId('empty')) {
    markersNotifier.addUserMarker(userMarker.position);
  }

  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  final url =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=5000'
      '&type=$placeType'
      '&key=$apiKey';

  final response = await ref.watch(httpClientProvider).get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      final results = data['results'] as List;
      final newMarkers = <Marker>{};

      for (var place in results) {
        final lat = place['geometry']['location']['lat'] as double;
        final lng = place['geometry']['location']['lng'] as double;
        final name = place['name'] as String;
        final placeId = place['place_id'] as String;

        newMarkers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: name,
              snippet: place['vicinity'] as String?,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              placeType == 'veterinary_care'
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      markersNotifier.addPlaceMarkers(newMarkers);
    }
  }
});

// A provider for http client to make it mockable in tests
final httpClientProvider = Provider<http.Client>((ref) => http.Client());
