import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'listings';

  // Create
  Future<void> addListing(ListingModel listing) async {
    try {
      await _db.collection(_collection).doc(listing.id).set(listing.toMap());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // Read all
  Stream<List<ListingModel>> getListings() {
    return _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Read user specific
  Stream<List<ListingModel>> getUserListings(String userId) {
    return _db
        .collection(_collection)
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Update
  Future<void> updateListing(ListingModel listing) async {
    try {
      await _db.collection(_collection).doc(listing.id).update(listing.toMap());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // Delete
  Future<void> deleteListing(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
