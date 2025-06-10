import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_pet/providers/location_providers.dart';
import 'package:health_pet/widgets/bottom_navigation_bar.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends ConsumerState<LocationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  final List<String> _placeTypes = ['veterinary_care', 'pet_store'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMap();
    });
  }

  Future<void> _initMap() async {
    final location = await ref.read(locationProvider.future);
    if (location == null) return;

    final controller = await _controller.future;
    final newPosition = LatLng(location.latitude!, location.longitude!);

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: newPosition, zoom: 14.0),
      ),
    );

    ref.read(markersProvider.notifier).addUserMarker(newPosition);
    ref.read(nearbyPlacesProvider(ref.read(placeTypeProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlaceType = ref.watch(placeTypeProvider);
    final markers = ref.watch(markersProvider);
    final locationAsync = ref.watch(locationProvider);

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
                    value: selectedPlaceType,
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
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        ref.read(placeTypeProvider.notifier).state = newValue;
                        ref.refresh(nearbyPlacesProvider(newValue));
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
              onMapCreated: (controller) {
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
