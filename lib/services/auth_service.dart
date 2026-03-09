import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          displayName: name,
        );

        try {
          // If Firestore fails (e.g., due to rules), we still created the auth user.
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
        } catch (firestoreError) {
          debugPrint('Firestore Error during signup: $firestoreError');
        }

        try {
          await user.sendEmailVerification();
        } catch (emailError) {
          debugPrint('Email Verification Error: $emailError');
        }

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signup: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unknown Error during signup: $e');
      return null;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        try {
          DocumentSnapshot doc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists) {
            return UserModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }
        } catch (firestoreError) {
          debugPrint('Firestore Error during login: $firestoreError');
        }

        // If Firestore doc failed or doesn't exist, fallback to just Auth data
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
        );
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
