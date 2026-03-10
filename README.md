# Kigali360

A Flutter mobile application for discovering, adding, and navigating to places of interest across Kigali, Rwanda. Users can browse a real-time directory of places, filter by category, view all listings on an interactive map, and manage their own submissions.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Authentication | Firebase Auth (Email/Password) |
| Database | Cloud Firestore |
| State Management | Provider (`ChangeNotifier`) |
| Overview Map | `flutter_map` + OpenStreetMap tiles |
| Detail Map | `webview_flutter` (Google Maps embed) |
| External Navigation | `url_launcher` |
| Unique IDs | `uuid` |

**Key dependencies** (`pubspec.yaml`):

```yaml
provider: ^6.1.5+1
firebase_auth: ^6.2.0
firebase_core: ^4.5.0
cloud_firestore: ^6.1.3
flutter_map: ^8.2.2
latlong2: ^0.9.1
webview_flutter: ^4.13.1
url_launcher: ^6.3.2
uuid: ^4.5.3
```

## Firebase Setup

The app uses **Firebase Auth** and **Cloud Firestore**. The project is configured via the FlutterFire CLI, which generates `lib/firebase_options.dart` automatically.

### Firebase project details

- **Project ID:** `kigali360-af35d`
- **Android package:** `com.elgibbor.kigali360`
- **Configured platforms:** Android only (iOS, web, Windows not currently configured)

### Initialization

Firebase is initialized before `runApp` in `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

`DefaultFirebaseOptions.currentPlatform` selects the correct per-platform config from `firebase_options.dart` at runtime.

### Authentication

Firebase Auth is enabled with the **Email/Password** sign-in provider. The app enforces **email verification** — users who register but have not clicked the verification link in their inbox are blocked from reaching the main app.

The enforcement lives in `AuthWrapper` in `main.dart`, which is a `StreamBuilder` on `authStateChanges()`. Both conditions must pass:

```dart
if (user != null && user.emailVerified) {
  return const MainWrapper();  // access granted
} else {
  return const LoginScreen();  // blocked — login or verify first
}
```

Sign-up (`auth_service.dart`) runs three sequential steps: create the Firebase Auth account, write a profile document to the `users` Firestore collection (using the UID as the document ID), then dispatch the verification email. Each step is independently error-handled so a Firestore failure does not prevent the auth account from being created.

### Firestore Security Rules (recommended)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }

    // Any authenticated user can read and create listings
    // Only the creator can update or delete their own listing
    match /listings/{listingId} {
      allow read:   if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
                            && request.auth.uid == resource.data.createdBy;
    }
  }
}
```

---

## Firestore Collections

### `users`

Written during sign-up. Document ID equals the Firebase Auth UID.

| Field | Type | Description |
|---|---|---|
| `uid` | `String` | Firebase Auth UID |
| `email` | `String` | User's email address |
| `displayName` | `String` | Full name provided at sign-up |

### `listings`

The primary data collection. Each document represents one place in Kigali. Document IDs are UUID v4 values generated client-side by the `uuid` package.

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Place name |
| `category` | `String` | One of: `Hospital`, `Police Station`, `Library`, `Restaurant`, `Café`, `Park`, `Tourist Attraction` |
| `address` | `String` | Street or area address |
| `contact` | `String` | Phone number (optional) |
| `description` | `String` | Free-text description |
| `latitude` | `Number` | Geographic latitude — used directly by map widgets |
| `longitude` | `Number` | Geographic longitude — used directly by map widgets |
| `createdBy` | `String` | Firebase Auth UID of the listing creator |
| `createdAt` | `Timestamp` | Firestore `Timestamp` of creation time |

> `latitude` and `longitude` are stored as plain numbers. `MapScreen` reads them to position `flutter_map` markers. `ListingDetailScreen` interpolates them into an embedded Google Maps iframe URL and an external navigation deep-link.

### Serialization

`ListingModel` (`lib/models/listing_model.dart`) handles conversion in both directions:

```dart
// Writing to Firestore — toMap()
Map<String, dynamic> toMap() => {
  'name': name,
  'category': category,
  'address': address,
  'contact': contact,
  'description': description,
  'latitude': latitude,             // stored as double
  'longitude': longitude,           // stored as double
  'createdBy': createdBy,
  'createdAt': Timestamp.fromDate(createdAt),
};

// Reading from Firestore — fromMap()
factory ListingModel.fromMap(Map<String, dynamic> data, String documentId) =>
  ListingModel(
    id: documentId,                 // document ID passed in separately
    latitude: (data['latitude'] ?? 0.0).toDouble(),
    longitude: (data['longitude'] ?? 0.0).toDouble(),
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    // ... other fields
  );
```

---

## State Management

The app uses the **Provider** package with `ChangeNotifier` services. Two services are registered as global singletons at the root of the widget tree in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => FirestoreService()),
  ],
  child: MaterialApp(...),
)
```

Because they are registered at the root, any screen can access them with `Provider.of<T>(context)` or `context.read<T>()` without prop drilling.

### AuthService (`lib/services/auth_service.dart`)

| Member | Type | Description |
|---|---|---|
| `userChanges` | `Stream<User?>` | Auth state stream; consumed by `AuthWrapper` |
| `currentUser` | `User?` | Synchronous getter for the active user |
| `signUpWithEmailAndPassword` | `Future<UserModel?>` | Auth + Firestore write + verification email |
| `signInWithEmailAndPassword` | `Future<UserModel?>` | Auth + Firestore profile fetch |
| `signOut` | `Future<void>` | Signs out; stream emits null, routing to login |

### FirestoreService (`lib/services/firestore_service.dart`)

All read methods return **Streams** so screens rebuild automatically on any Firestore change without extra `setState` calls:

| Method | Return type | Description |
|---|---|---|
| `getListings()` | `Stream<List<ListingModel>>` | All listings ordered by `createdAt` descending |
| `getUserListings(userId)` | `Stream<List<ListingModel>>` | Listings filtered by `createdBy == userId` (server-side query) |
| `addListing(listing)` | `Future<void>` | `.set()` — creates document with client-generated UUID |
| `updateListing(listing)` | `Future<void>` | `.update()` — patches existing document fields |
| `deleteListing(id)` | `Future<void>` | `.delete()` — removes document by ID |

### Data flow

```
Firestore (remote)
      │
      │  .snapshots()  ←  real-time push on any write
      ▼
FirestoreService  (singleton Provider)
      │
      │  Stream<List<ListingModel>>
      ▼
StreamBuilder  (in DirectoryScreen / MyListingsScreen / MapScreen)
      │
      │  snapshot.data  →  client-side filter (search query + category)
      ▼
ListView / MarkerLayer  (UI rebuilds automatically)
```

All three data screens share the same `FirestoreService` singleton. A write from any screen triggers Firestore to push a new snapshot, which rebuilds every subscribed `StreamBuilder` simultaneously — no manual refresh is needed.

---

## Navigation Structure

Navigation has two levels.

### Level 1 — Auth routing (automatic, stream-driven)

`AuthWrapper` in `main.dart` listens to `authService.userChanges`. The widget tree is determined entirely by the stream state — no imperative `Navigator` calls are involved at this level:

```
Firebase Auth stream emits
      │
      ├── null (signed out)                →  LoginScreen
      ├── User, emailVerified == false     →  LoginScreen
      └── User, emailVerified == true      →  MainWrapper
```

Calling `authService.signOut()` causes the stream to emit `null`, which instantly swaps the tree back to `LoginScreen`.

### Level 2 — Main app (bottom navigation)

`MainWrapper` (`lib/screens/main_wrapper.dart`) holds four screens in a fixed list and displays the active one by index. Switching tabs calls `setState` to update `_currentIndex`:

| Index | Label | Screen | Purpose |
|---|---|---|---|
| 0 | Directory | `DirectoryScreen` | Browse, search, and filter all listings |
| 1 | My Listings | `MyListingsScreen` | View and manage your own listings |
| 2 | Map View | `MapScreen` | All listings as tappable map markers |
| 3 | Settings | `SettingsScreen` | User profile header and sign-out |

All four screens are instantiated at startup and kept in memory while switching tabs.

### Level 3 — Detail navigation (imperative `Navigator.push`)

From listing cards or map markers, `Navigator.push` opens deeper screens:

| Source | Destination | Trigger |
|---|---|---|
| Directory card / map marker | `ListingDetailScreen` | Tap |
| Detail screen (owner only) | `AddListingScreen(listingToEdit: listing)` | Edit icon |
| Directory FAB / My Listings FAB | `AddListingScreen()` | `+` button |
| My Listings edit icon | `AddListingScreen(listingToEdit: listing)` | Edit icon |

`AddListingScreen` handles both create and edit based on whether `listingToEdit` is non-null:

```dart
// Create — no argument
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const AddListingScreen(),
));

// Edit — listing passed in
Navigator.push(context, MaterialPageRoute(
  builder: (context) => AddListingScreen(listingToEdit: listing),
));
```

---

## Running the App

### Prerequisites

- Flutter SDK `^3.10.7`
- Android Studio or VS Code with the Flutter/Dart plugins
- An Android device or emulator (API 21+)
- A Firebase project with **Authentication (Email/Password)** and **Cloud Firestore** enabled

### Steps

```bash
# 1. Clone the repository
git clone <repo-url>
cd kigali360

# 2. Install dependencies
flutter pub get

# 3. Add google-services.json
#    Download from Firebase Console → Project Settings → Android app
#    Place it at: android/app/google-services.json

# 4. Run the app
flutter run
```

> **New Firebase project?** Re-run the FlutterFire CLI to regenerate `lib/firebase_options.dart`:
> ```bash
> dart pub global activate flutterfire_cli
> flutterfire configure
> ```
