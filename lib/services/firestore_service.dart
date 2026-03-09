import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class FirestoreService extends ChangeNotifier {
  // final FirebaseFirestore _db = FirebaseFirestore.instance;
  // final String _collection = 'listings';

  // Create
  Future<void> addListing(ListingModel listing) async {
    // TODO: implement add
  }

  // Read all
  Stream<List<ListingModel>> getListings() {
    // TODO: implement get all
    return const Stream.empty();
  }

  // Read user specific
  Stream<List<ListingModel>> getUserListings(String userId) {
    // TODO: implement get user specific
    return const Stream.empty();
  }

  // Update
  Future<void> updateListing(ListingModel listing) async {
    // TODO: implement update
  }

  // Delete
  Future<void> deleteListing(String id) async {
    // TODO: implement delete
  }
}
