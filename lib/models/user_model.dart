class UserModel {
  final String uid;
  final String email;
  final String displayName;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'displayName': displayName};
  }
}
