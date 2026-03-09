import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/listing_model.dart';
import '../services/firestore_service.dart';
import 'listing_detail_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    // Kigali Coordinates
    final kigaliCenter = const LatLng(-1.9441, 30.0619);

    return Scaffold(
      appBar: AppBar(title: const Text('Kigali 360 Map')),
      body: StreamBuilder<List<ListingModel>>(
        stream: firestoreService.getListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listings = snapshot.data ?? [];

          final markers = listings.map((listing) {
            return Marker(
              point: LatLng(listing.latitude, listing.longitude),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ListingDetailScreen(listing: listing),
                    ),
                  );
                },
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(initialCenter: kigaliCenter, initialZoom: 13.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.elgibbor.kigali360',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
