import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'add_listing_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final lat = widget.listing.latitude;
    final lng = widget.listing.longitude;
    final htmlString =
        '''
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
          <style>
            body { padding: 0; margin: 0; }
            iframe { width: 100%; height: 100%; border: 0; }
          </style>
        </head>
        <body>
          <iframe src="https://www.google.com/maps?q=$lat,$lng&z=15&output=embed" allowfullscreen></iframe>
        </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlString);
  }

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
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwner = authService.currentUser?.uid == widget.listing.createdBy;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing.name),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddListingScreen(listingToEdit: widget.listing),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Listing'),
                    content: const Text(
                      'Are you sure you want to delete this listing?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final firestoreService = Provider.of<FirestoreService>(
                    context,
                    listen: false,
                  );
                  try {
                    await firestoreService.deleteListing(widget.listing.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Listing deleted')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete listing'),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map View
          SizedBox(height: 250, child: WebViewWidget(controller: _controller)),
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
