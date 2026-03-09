import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/listing_model.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  Future<void> _launchMaps() async {
    final lat = widget.listing.latitude;
    final lng = widget.listing.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps navigation')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(widget.listing.latitude, widget.listing.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(widget.listing.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map View
          SizedBox(
            height: 250,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(target: latLng, zoom: 15),
              markers: {
                Marker(
                  markerId: MarkerId(widget.listing.id),
                  position: latLng,
                  infoWindow: InfoWindow(title: widget.listing.name),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(widget.listing.category),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Address',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.listing.address),
                  const SizedBox(height: 16),
                  if (widget.listing.contact.isNotEmpty) ...[
                    const Text(
                      'Contact',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(widget.listing.contact),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.listing.description),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchMaps,
        icon: const Icon(Icons.navigation),
        label: const Text('Navigate'),
      ),
    );
  }
}
