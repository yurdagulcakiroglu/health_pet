import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:health_pet/widgets/bottom_navigation_bar.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  LocationData? _currentPosition;
  final Location _location = Location();
  String _selectedPlaceType = 'veterinary_care';
  final List<String> _placeTypes = ['veterinary_care', 'pet_store'];

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Set<Marker> markers = {};
  final String _apiKey = '***REMOVED***';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Location services are disabled.');
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Location permissions are denied');
          return;
        }
      }

      final locationData = await _location.getLocation();
      print(
        'Location obtained: ${locationData.latitude}, ${locationData.longitude}',
      );

      setState(() {
        _currentPosition = locationData;
      });

      if (_currentPosition != null) {
        final GoogleMapController controller = await _controller.future;
        final newPosition = LatLng(
          _currentPosition!.latitude!,
          _currentPosition!.longitude!,
        );

        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newPosition, zoom: 14.0),
          ),
        );

        // Kullanıcı konumu marker'ı
        final userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: newPosition,
          infoWindow: const InfoWindow(title: 'Konumunuz'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        setState(() {
          markers.clear();
          markers.add(userMarker);
        });

        // Yakındaki yerleri ara
        await _searchNearbyPlaces();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _searchNearbyPlaces() async {
    try {
      if (_currentPosition == null) {
        print('Current position is null');
        return;
      }

      final String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&radius=5000' // 5km yarıçap
          '&type=$_selectedPlaceType'
          '&key=$_apiKey';

      print('Fetching places with URL: $url');

      final response = await http.get(Uri.parse(url));

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          print('Found ${results.length} places');

          // Mevcut kullanıcı konumu marker'ını koru
          final Set<Marker> newMarkers = markers;

          for (var place in results) {
            final lat = place['geometry']['location']['lat'] as double;
            final lng = place['geometry']['location']['lng'] as double;
            final name = place['name'] as String;
            final placeId = place['place_id'] as String;

            print('Adding marker for: $name at $lat,$lng');

            final marker = Marker(
              markerId: MarkerId(placeId),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name,
                snippet: place['vicinity'] as String?,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _selectedPlaceType == 'veterinary_care'
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueGreen,
              ),
            );

            newMarkers.add(marker);
          }

          setState(() {
            markers = newMarkers;
          });

          print('Total markers after update: ${markers.length}');
        } else {
          print('API returned status: ${data['status']}');
          print('API error message: ${data['error_message']}');
        }
      } else {
        print('Failed to fetch places: ${response.statusCode}');
        print('Error response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error searching nearby places: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yakındaki Yerler"),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text("Kategori Seç: "),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPlaceType,
                    isExpanded: true,
                    items: _placeTypes.map((String place) {
                      return DropdownMenuItem<String>(
                        value: place,
                        child: Text(
                          place == 'veterinary_care'
                              ? 'Veteriner Klinik'
                              : 'Pet Shop',
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue != null && newValue != _selectedPlaceType) {
                        setState(() {
                          _selectedPlaceType = newValue;
                        });
                        // Kullanıcı konumu marker'ını koru, diğerlerini temizle
                        final userMarker = markers.firstWhere(
                          (m) => m.markerId == const MarkerId('user_location'),
                          orElse: () => markers.first,
                        );
                        markers.clear();
                        markers.add(userMarker);
                        // Yeni kategori için yerleri ara
                        await _searchNearbyPlaces();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kInitialPosition,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(
        userId: '',
        petId: '',
      ),
    );
  }
}
