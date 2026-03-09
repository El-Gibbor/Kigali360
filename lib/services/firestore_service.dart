import '../models/listing.dart';

abstract class FirestoreService {
  Stream<List<Listing>> getListingsStream();

  Stream<List<Listing>> getUserListingsStream(String ownerId);

  /// Adds a new [listing] document and returns its generated ID.
  Future<String> addListing(Listing listing);

  /// Replaces the document for [listing.id] with the updated data.
  Future<void> updateListing(Listing listing);

  /// Permanently deletes the listing document with [id].
  Future<void> deleteListing(String id);

  /// Fetches a single listing by [id], returning `null` if not found.
  Future<Listing?> getListingById(String id);
}

/// Phase-1 stub: all streams yield empty lists and write methods are no-ops.
class StubFirestoreService implements FirestoreService {
  @override
  Stream<List<Listing>> getListingsStream() => const Stream.empty();

  @override
  Stream<List<Listing>> getUserListingsStream(String ownerId) =>
      const Stream.empty();

  @override
  Future<String> addListing(Listing listing) async => '';

  @override
  Future<void> updateListing(Listing listing) async {}

  @override
  Future<void> deleteListing(String id) async {}

  @override
  Future<Listing?> getListingById(String id) async => null;
}
