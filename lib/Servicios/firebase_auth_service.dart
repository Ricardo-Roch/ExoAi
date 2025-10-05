// lib/Servicios/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );

        // Crear/actualizar perfil de usuario
        if (userCredential.user != null) {
          await _createUserProfile(userCredential.user!);
        }

        return userCredential.user;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // Crear/actualizar perfil de usuario
        if (userCredential.user != null) {
          await _createUserProfile(userCredential.user!);
        }

        return userCredential.user;
      }
    } catch (e) {
      print('Error en inicio de sesion con Google: $e');
      return null;
    }
  }

  Future<void> _createUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'displayName': user.displayName ?? 'Usuario',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'bio': '',
        'followers': [],
        'following': [],
        'postsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesion: $e');
    }
  }

  Map<String, dynamic>? getUserInfo() {
    final user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
      };
    }
    return null;
  }
}
