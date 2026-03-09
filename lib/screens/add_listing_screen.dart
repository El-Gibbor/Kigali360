import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AddListingScreen extends StatefulWidget {
  final ListingModel? listingToEdit;

  const AddListingScreen({super.key, this.listingToEdit});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  late String _selectedCategory;
  final List<String> _categories = [
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listingToEdit;
    _nameController = TextEditingController(text: listing?.name ?? '');
    _addressController = TextEditingController(text: listing?.address ?? '');
    _contactController = TextEditingController(text: listing?.contact ?? '');
    _descriptionController = TextEditingController(
      text: listing?.description ?? '',
    );
    _latController = TextEditingController(
      text: listing?.latitude.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: listing?.longitude.toString() ?? '',
    );

    _selectedCategory = 'Hospital';
    if (listing != null && _categories.contains(listing.category)) {
      _selectedCategory = listing.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final user = authService.currentUser;

      if (user != null) {
        final isEditing = widget.listingToEdit != null;
        final listingId = isEditing
            ? widget.listingToEdit!.id
            : const Uuid().v4();
        final createdAt = isEditing
            ? widget.listingToEdit!.createdAt
            : DateTime.now();

        final updatedListing = ListingModel(
          id: listingId,
          name: _nameController.text.trim(),
          category: _selectedCategory,
          address: _addressController.text.trim(),
          contact: _contactController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: double.tryParse(_latController.text.trim()) ?? 0.0,
          longitude: double.tryParse(_lngController.text.trim()) ?? 0.0,
          createdBy: user.uid,
          createdAt: createdAt,
        );

        try {
          if (isEditing) {
            await firestoreService.updateListing(updatedListing);
          } else {
            await firestoreService.addListing(updatedListing);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? 'Listing updated successfully!'
                      : 'Listing added successfully!',
                ),
              ),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? 'Failed to update listing.'
                      : 'Failed to add listing.',
                ),
              ),
            );
          }
        }
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.listingToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Listing' : 'Add Listing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Place Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(
                        isEditing ? 'Update Listing' : 'Save Listing',
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
